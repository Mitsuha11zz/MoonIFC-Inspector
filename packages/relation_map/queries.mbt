///|
pub fn RelationMap::children_of(self : RelationMap, id : Int) -> Array[Int] {
  let result : Array[Int] = []
  for entity in self.entities {
    if entity.kind() == "IFCRELAGGREGATES" && entity.references().contains(id) { result.push(entity.id()) }
  }
  result
}

///|
pub fn RelationMap::parent_of(self : RelationMap, id : Int) -> Int? {
  let incoming = self.incoming_references(id)
  incoming.get(0)
}
