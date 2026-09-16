///|
pub fn RelationMap::entity_by_id(self : RelationMap, id : Int) -> @ifc_entities.Entity? {
  for entity in self.entities { if entity.id() == id { return Some(entity) } }
  None
}

///|
pub fn RelationMap::entities_by_type(self : RelationMap, kind : String) -> Array[@ifc_entities.Entity] {
  self.entities.filter(entity => entity.kind() == kind)
}

///|
pub fn RelationMap::outgoing_references(self : RelationMap, id : Int) -> Array[Int] {
  match self.entity_by_id(id) { Some(entity) => entity.references(); None => [] }
}

///|
pub fn RelationMap::incoming_references(self : RelationMap, id : Int) -> Array[Int] {
  let result : Array[Int] = []
  for entity in self.entities { if entity.references().contains(id) { result.push(entity.id()) } }
  result
}
