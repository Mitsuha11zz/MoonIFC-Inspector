///|
/// Index every distinct direct parent declared by IFCRELAGGREGATES. The
/// general relation map intentionally keeps only the first parent, while this
/// audit needs all parents to detect ambiguous spatial ownership.
fn spatial_parents(
  entities : Array[@ifc_entities.Entity],
) -> Map[Int, Array[Int]] {
  let parents : Map[Int, Array[Int]] = Map([])
  for entity in entities {
    if entity.kind().to_upper() != "IFCRELAGGREGATES" {
      continue
    }
    let args = entity.args()
    if args.length() < 6 {
      continue
    }
    match (args[4], args[5]) {
      (@step_text.Reference(parent_id), @step_text.Aggregate(children)) =>
        for child in children {
          match child {
            @step_text.Reference(child_id) => {
              let child_parents = match parents.get(child_id) {
                Some(existing) => existing
                None => []
              }
              if !child_parents.contains(parent_id) {
                child_parents.push(parent_id)
                parents[child_id] = child_parents
              }
            }
            _ => ()
          }
        }
      _ => ()
    }
  }
  parents
}

///|
fn expected_spatial_parent(kind : String) -> String? {
  match kind.to_upper() {
    "IFCSITE" => Some("IFCPROJECT")
    "IFCBUILDING" => Some("IFCSITE")
    "IFCBUILDINGSTOREY" => Some("IFCBUILDING")
    "IFCSPACE" => Some("IFCBUILDINGSTOREY")
    _ => None
  }
}

///|
/// Audit the expected project-to-space aggregation chain and ambiguous direct
/// parents. Findings are emitted in rule order, then entity source order.
fn check_spatial_hierarchy(
  map : @relation_map.RelationMap,
  entities : Array[@ifc_entities.Entity],
  findings : Array[Finding],
) -> Unit {
  let parents = spatial_parents(entities)
  check_expected_spatial_parent(map, entities, parents, findings)
  check_multiple_spatial_parents(map, entities, parents, findings)
}

///|
fn check_expected_spatial_parent(
  map : @relation_map.RelationMap,
  entities : Array[@ifc_entities.Entity],
  parents : Map[Int, Array[Int]],
  findings : Array[Finding],
) -> Unit {
  for entity in entities {
    match expected_spatial_parent(entity.kind()) {
      Some(expected_kind) => {
        let parent_ids = match parents.get(entity.id()) {
          Some(ids) => ids
          None => []
        }
        let mut has_expected_parent = false
        let mut has_existing_parent = false
        let mut has_dangling_parent = false
        let mut first_existing_parent : Int? = None
        for parent_id in parent_ids {
          match map.entity_by_id(parent_id) {
            Some(parent) => {
              has_existing_parent = true
              if first_existing_parent is None {
                first_existing_parent = Some(parent_id)
              }
              if parent.kind().to_upper() == expected_kind {
                has_expected_parent = true
              }
            }
            None => has_dangling_parent = true
          }
        }
        // REF001 already explains a purely dangling parent. If a valid entity
        // exists but has the wrong type, report the hierarchy mismatch too.
        if !has_expected_parent && (has_existing_parent || !has_dangling_parent) {
          findings.push({
            code: "SPAT002",
            severity: Warning,
            entity_id: Some(entity.id()),
            entity_type: Some(entity.kind()),
            location: Some(entity.location()),
            target_id: first_existing_parent,
            message: entity.kind().to_upper() +
            " requires a direct aggregation parent of type " +
            expected_kind,
            suggestion: Some(
              "add an IFCRELAGGREGATES relationship to the required spatial parent",
            ),
          })
        }
      }
      None => ()
    }
  }
}

///|
fn check_multiple_spatial_parents(
  map : @relation_map.RelationMap,
  entities : Array[@ifc_entities.Entity],
  parents : Map[Int, Array[Int]],
  findings : Array[Finding],
) -> Unit {
  for entity in entities {
    match expected_spatial_parent(entity.kind()) {
      Some(_) => {
        let parent_ids = match parents.get(entity.id()) {
          Some(ids) => ids
          None => []
        }
        let existing_parent_ids = parent_ids.filter(parent_id => {
          map.entity_by_id(parent_id) is Some(_)
        })
        if existing_parent_ids.length() > 1 {
          let parent_list = existing_parent_ids
            .map(id => "#" + id.to_string())
            .join(", ")
          findings.push({
            code: "SPAT003",
            severity: Error,
            entity_id: Some(entity.id()),
            entity_type: Some(entity.kind()),
            location: Some(entity.location()),
            target_id: existing_parent_ids.get(0),
            message: "spatial entity has multiple aggregation parents (" +
            parent_list +
            ")",
            suggestion: Some(
              "keep only the intended IFCRELAGGREGATES parent for this spatial entity",
            ),
          })
        }
      }
      None => ()
    }
  }
}
