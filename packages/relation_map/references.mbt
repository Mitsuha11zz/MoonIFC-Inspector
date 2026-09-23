///|
pub fn RelationMap::entity_by_id(
  self : RelationMap,
  id : Int,
) -> @ifc_entities.Entity? {
  self.by_id.get(id)
}

///|
pub fn RelationMap::entities_by_type(
  self : RelationMap,
  kind : String,
) -> Array[@ifc_entities.Entity] {
  match self.by_type.get(kind.to_upper()) {
    Some(items) => items.copy()
    None => []
  }
}

///|
pub fn RelationMap::outgoing_references(
  self : RelationMap,
  id : Int,
) -> Array[Int] {
  match self.by_id.get(id) {
    Some(entity) => entity.references()
    None => []
  }
}

///|
pub fn RelationMap::incoming_references(
  self : RelationMap,
  id : Int,
) -> Array[Int] {
  match self.incoming.get(id) {
    Some(items) => items.copy()
    None => []
  }
}
