///|
pub struct RelationMap { entities : Array[@ifc_entities.Entity] } derive(Debug)

///|
pub fn build(entities : Array[@ifc_entities.Entity]) -> RelationMap { { entities } }

///|
pub fn RelationMap::entities(self : RelationMap) -> Array[@ifc_entities.Entity] { self.entities.copy() }
