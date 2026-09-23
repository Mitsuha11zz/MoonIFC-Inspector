///|
fn index_relationship(
  entity : @ifc_entities.Entity,
  children : Map[Int, Array[Int]],
  parents : Map[Int, Int],
) -> Unit {
  let kind = entity.kind().to_upper()
  if kind != "IFCRELAGGREGATES" && kind != "IFCRELCONTAINEDINSPATIALSTRUCTURE" {
    return
  }
  let args = entity.args()
  if args.length() < 6 {
    return
  }
  let parent : Int? = match (kind, args[4], args[5]) {
    ("IFCRELAGGREGATES", @step_text.Reference(id), _) => Some(id)
    ("IFCRELCONTAINEDINSPATIALSTRUCTURE", _, @step_text.Reference(id)) =>
      Some(id)
    _ => None
  }
  let related : @step_text.Value = if kind == "IFCRELAGGREGATES" {
    args[5]
  } else {
    args[4]
  }
  match (parent, related) {
    (Some(parent_id), @step_text.Aggregate(items)) =>
      for item in items {
        match item {
          @step_text.Reference(child_id) => {
            append_unique(children, parent_id, child_id)
            if !parents.contains(child_id) {
              parents[child_id] = parent_id
            }
          }
          _ => ()
        }
      }
    _ => ()
  }
}

///|
pub fn RelationMap::children_of(self : RelationMap, id : Int) -> Array[Int] {
  match self.children.get(id) {
    Some(items) => items.copy()
    None => []
  }
}

///|
pub fn RelationMap::parent_of(self : RelationMap, id : Int) -> Int? {
  self.parents.get(id)
}
