///|
priv enum TreeVisit {
  Enter(Int, Int, String)
  Leave(Int)
}

///|
fn hierarchy_entity(
  map : @relation_map.RelationMap,
  entity : @ifc_entities.Entity,
) -> Bool {
  match entity.category() {
    @ifc_entities.Project | @ifc_entities.Spatial | @ifc_entities.Element =>
      true
    @ifc_entities.Relationship => false
    @ifc_entities.Unsupported =>
      map.parent_of(entity.id()) is Some(_) ||
      map.children_of(entity.id()).length() > 0
  }
}

///|
/// Use an explicit stack so deeply nested input does not exhaust the call stack.
fn append_spatial_branch(
  map : @relation_map.RelationMap,
  root : Int,
  annotation : String,
  shown : Map[Int, Bool],
  lines : Array[String],
) -> Unit {
  let active : Map[Int, Bool] = Map([])
  let stack : Array[TreeVisit] = [Enter(root, 0, annotation)]
  while stack.pop() is Some(visit) {
    match visit {
      Leave(id) => active.remove(id)
      Enter(id, depth, suffix) => {
        let prefix = "  ".repeat(depth) + "#" + id.to_string()
        match map.entity_by_id(id) {
          None => lines.push(prefix + " [missing]")
          Some(entity) => {
            let label = prefix + " " + entity.kind()
            if active.contains(id) {
              lines.push(label + " [cycle]")
              continue
            }
            if shown.contains(id) {
              lines.push(label + " [already shown]")
              continue
            }
            lines.push(label + suffix)
            shown[id] = true
            active[id] = true
            stack.push(Leave(id))
            let children = map.children_of(id)
            // Push in reverse so visits retain relationship source order.
            for index in 0..<children.length() {
              stack.push(
                Enter(children[children.length() - index - 1], depth + 1, ""),
              )
            }
          }
        }
      }
    }
  }
}

///|
/// Render indexed IFC aggregation/containment edges as an indented hierarchy.
/// Roots follow entity source order; children follow relationship source order.
/// Relationship records and unrelated unsupported entities are omitted as roots.
/// Missing nodes, shared children and cycles are marked without mutating the map.
pub fn spatial_tree(map : @relation_map.RelationMap) -> String {
  let entities = map.entities()
  let shown : Map[Int, Bool] = Map([])
  let lines : Array[String] = []
  for entity in entities {
    if !hierarchy_entity(map, entity) {
      continue
    }
    let annotation = match map.parent_of(entity.id()) {
      None => Some("")
      Some(parent_id) =>
        match map.entity_by_id(parent_id) {
          None => Some(" [missing parent #" + parent_id.to_string() + "]")
          Some(parent) =>
            if hierarchy_entity(map, parent) {
              None
            } else {
              Some(" [parent outside tree #" + parent_id.to_string() + "]")
            }
        }
    }
    if annotation is Some(suffix) && !shown.contains(entity.id()) {
      append_spatial_branch(map, entity.id(), suffix, shown, lines)
    }
  }
  // A cycle may have no root. Show each remaining component once, in source order.
  for entity in entities {
    if hierarchy_entity(map, entity) && !shown.contains(entity.id()) {
      append_spatial_branch(map, entity.id(), " [unrooted]", shown, lines)
    }
  }
  lines.join("\n")
}
