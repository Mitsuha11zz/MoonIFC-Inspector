///|
/// Follow the indexed parent chain until a spatial entity is found.
/// None means the chain contains a dangling reference already covered by REF001.
fn has_spatial_ancestor(
  map : @relation_map.RelationMap,
  entity_id : Int,
) -> Bool? {
  let seen : Array[Int] = [entity_id]
  let mut parent_id = map.parent_of(entity_id)
  while parent_id is Some(next_id) {
    if seen.contains(next_id) {
      return Some(false)
    }
    seen.push(next_id)
    match map.entity_by_id(next_id) {
      Some(parent) =>
        if parent.category() == @ifc_entities.Spatial {
          return Some(true)
        } else {
          parent_id = map.parent_of(next_id)
        }
      None => return None
    }
  }
  Some(false)
}

///|
/// Report recognized building elements without a spatial ancestor.
fn check_spatial_placement(
  map : @relation_map.RelationMap,
  entities : Array[@ifc_entities.Entity],
  findings : Array[Finding],
) -> Unit {
  for entity in entities {
    let kind = entity.kind().to_upper()
    if kind != "IFCWALL" && kind != "IFCDOOR" && kind != "IFCWINDOW" {
      continue
    }
    match has_spatial_ancestor(map, entity.id()) {
      Some(true) | None => ()
      Some(false) =>
        findings.push({
          code: "SPAT001",
          severity: Warning,
          entity_id: Some(entity.id()),
          entity_type: Some(entity.kind()),
          location: Some(entity.location()),
          target_id: None,
          message: "element has no spatial ancestor in the indexed hierarchy",
          suggestion: Some(
            "add a valid spatial containment or aggregation relationship",
          ),
        })
    }
  }
}
