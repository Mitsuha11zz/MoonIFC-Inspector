///|
/// One IFC file participating in a federated model check.
pub struct ModelSource {
  name : String
  discipline : String
  entities : Array[@ifc_entities.Entity]
} derive(Debug)

///|
pub extend ModelSource with Debug::{to_repr}

///|
pub fn ModelSource::new(
  name~ : String,
  entities~ : Array[@ifc_entities.Entity],
  discipline? : String = "",
) -> ModelSource {
  { name, discipline, entities: entities.copy(), }
}

///|
pub fn ModelSource::name(self : ModelSource) -> String {
  self.name
}

///|
pub fn ModelSource::discipline(self : ModelSource) -> String {
  self.discipline
}

///|
/// A duplicate IFC `GlobalId` found in two different input models.
pub struct GlobalIdCollision {
  global_id : String
  first_model : String
  first_discipline : String
  first_entity_id : Int
  first_entity_type : String
  first_location : @step_text.SourceLoc
  duplicate_model : String
  duplicate_discipline : String
  duplicate_entity_id : Int
  duplicate_entity_type : String
  duplicate_location : @step_text.SourceLoc
  allowed : Bool
} derive(Eq, Debug)

///|
pub extend GlobalIdCollision with Eq::{not_equal, equal}

///|
pub extend GlobalIdCollision with Debug::{to_repr}

///|
pub fn GlobalIdCollision::code(_self : GlobalIdCollision) -> String {
  if _self.allowed {
    "FED002"
  } else {
    "FED001"
  }
}

///|
/// Whether the repeated identifier was explicitly allowed by the federation policy.
pub fn GlobalIdCollision::is_allowed(self : GlobalIdCollision) -> Bool {
  self.allowed
}

///|
pub fn GlobalIdCollision::global_id(self : GlobalIdCollision) -> String {
  self.global_id
}

///|
pub fn GlobalIdCollision::first_model(self : GlobalIdCollision) -> String {
  self.first_model
}

///|
pub fn GlobalIdCollision::first_discipline(self : GlobalIdCollision) -> String {
  self.first_discipline
}

///|
pub fn GlobalIdCollision::first_entity_id(self : GlobalIdCollision) -> Int {
  self.first_entity_id
}

///|
pub fn GlobalIdCollision::first_entity_type(self : GlobalIdCollision) -> String {
  self.first_entity_type
}

///|
pub fn GlobalIdCollision::first_location(
  self : GlobalIdCollision,
) -> @step_text.SourceLoc {
  self.first_location
}

///|
pub fn GlobalIdCollision::duplicate_model(self : GlobalIdCollision) -> String {
  self.duplicate_model
}

///|
pub fn GlobalIdCollision::duplicate_discipline(
  self : GlobalIdCollision,
) -> String {
  self.duplicate_discipline
}

///|
pub fn GlobalIdCollision::duplicate_entity_id(self : GlobalIdCollision) -> Int {
  self.duplicate_entity_id
}

///|
pub fn GlobalIdCollision::duplicate_entity_type(
  self : GlobalIdCollision,
) -> String {
  self.duplicate_entity_type
}

///|
pub fn GlobalIdCollision::duplicate_location(
  self : GlobalIdCollision,
) -> @step_text.SourceLoc {
  self.duplicate_location
}

///|
/// Results from checking multiple discipline or delivery IFC files together.
pub struct FederationReport {
  models : Array[String]
  disciplines : Array[String]
  entity_count : Int
  collisions : Array[GlobalIdCollision]
} derive(Eq, Debug)

///|
pub extend FederationReport with Eq::{not_equal, equal}

///|
pub extend FederationReport with Debug::{to_repr}

///|
pub fn FederationReport::models(self : FederationReport) -> Array[String] {
  self.models.copy()
}

///|
pub fn FederationReport::model_count(self : FederationReport) -> Int {
  self.models.length()
}

///|
pub fn FederationReport::disciplines(self : FederationReport) -> Array[String] {
  self.disciplines.copy()
}

///|
pub fn FederationReport::entity_count(self : FederationReport) -> Int {
  self.entity_count
}

///|
pub fn FederationReport::collisions(
  self : FederationReport,
) -> Array[GlobalIdCollision] {
  self.collisions.copy()
}

///|
pub fn FederationReport::unexpected_collision_count(
  self : FederationReport,
) -> Int {
  let mut count = 0
  for collision in self.collisions {
    if !collision.is_allowed() {
      count += 1
    }
  }
  count
}

///|
pub fn FederationReport::allowed_collision_count(
  self : FederationReport,
) -> Int {
  self.collisions.length() - self.unexpected_collision_count()
}
