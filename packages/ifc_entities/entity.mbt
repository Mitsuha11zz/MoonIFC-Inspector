///|
pub struct Entity {
  id : Int
  kind : String
  args : Array[@step_text.Value]
  references : Array[Int]
  global_id : String?
  location : @step_text.SourceLoc
} derive(Eq, Debug)

///|
pub extend Entity with Eq::{not_equal, equal}

///|
pub extend Entity with Debug::{to_repr}

///|
pub fn Entity::id(self : Entity) -> Int {
  self.id
}

///|
pub fn Entity::kind(self : Entity) -> String {
  self.kind
}

///|
pub fn Entity::args(self : Entity) -> Array[@step_text.Value] {
  self.args.copy()
}

///|
pub fn Entity::references(self : Entity) -> Array[Int] {
  self.references.copy()
}

///|
pub fn Entity::global_id(self : Entity) -> String? {
  self.global_id
}

///|
pub fn Entity::location(self : Entity) -> @step_text.SourceLoc {
  self.location
}

///|
pub fn Entity::category(self : Entity) -> EntityClass {
  classify(self.kind)
}
