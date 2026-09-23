///|
pub struct RelationMap {
  entities : Array[@ifc_entities.Entity]
  by_id : Map[Int, @ifc_entities.Entity]
  by_type : Map[String, Array[@ifc_entities.Entity]]
  incoming : Map[Int, Array[Int]]
  children : Map[Int, Array[Int]]
  parents : Map[Int, Int]
}

///|
fn append_unique(index : Map[Int, Array[Int]], key : Int, value : Int) -> Unit {
  match index.get(key) {
    Some(items) => if !items.contains(value) { items.push(value) }
    None => index[key] = [value]
  }
}

///|
pub fn build(entities : Array[@ifc_entities.Entity]) -> RelationMap {
  let ordered : Array[@ifc_entities.Entity] = []
  let by_id : Map[Int, @ifc_entities.Entity] = Map([])
  let by_type : Map[String, Array[@ifc_entities.Entity]] = Map([])
  let incoming : Map[Int, Array[Int]] = Map([])
  let children : Map[Int, Array[Int]] = Map([])
  let parents : Map[Int, Int] = Map([])
  for entity in entities {
    let id = entity.id()
    if !by_id.contains(id) {
      ordered.push(entity)
      by_id[id] = entity
      match by_type.get(entity.kind().to_upper()) {
        Some(items) => items.push(entity)
        None => by_type[entity.kind().to_upper()] = [entity]
      }
      for target in entity.references() {
        append_unique(incoming, target, id)
      }
    }
  }
  for entity in ordered {
    index_relationship(entity, children, parents)
  }
  { entities: ordered, by_id, by_type, incoming, children, parents, }
}

///|
pub fn RelationMap::entities(self : RelationMap) -> Array[@ifc_entities.Entity] {
  self.entities.copy()
}
