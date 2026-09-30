///|
pub(all) enum Severity {
  Error
  Warning
  Info
} derive(Eq, Debug)

///|
pub extend Severity with Eq::{equal, not_equal}

///|
pub extend Severity with Debug::{to_repr}

///|
pub struct Finding {
  code : String
  severity : Severity
  entity_id : Int?
  entity_type : String?
  location : @step_text.SourceLoc?
  target_id : Int?
  message : String
  suggestion : String?
} derive(Eq, Debug)

///|
pub extend Finding with Eq::{equal, not_equal}

///|
pub extend Finding with Debug::{to_repr}

///|
pub struct AuditReport {
  findings : Array[Finding]
  entity_count : Int
  type_count : Int
  reference_count : Int
} derive(Eq, Debug)

///|
pub extend AuditReport with Eq::{equal, not_equal}

///|
pub extend AuditReport with Debug::{to_repr}

///|
pub fn Finding::location(self : Finding) -> @step_text.SourceLoc? {
  self.location
}

///|
/// Return the rule-specific related entity ID. REF001 uses the missing
/// reference target; GID001 uses the first owner of the duplicated GlobalId.
/// SPAT002 may point to a wrong-type parent and SPAT003 points to the first
/// aggregation parent. SPAT001 has no single related target.
pub fn Finding::target_id(self : Finding) -> Int? {
  self.target_id
}

///|
pub fn Finding::code(self : Finding) -> String {
  self.code
}

///|
pub fn Finding::severity(self : Finding) -> Severity {
  self.severity
}

///|
pub fn Finding::message(self : Finding) -> String {
  self.message
}

///|
pub fn Finding::entity_id(self : Finding) -> Int? {
  self.entity_id
}

///|
pub fn Finding::entity_type(self : Finding) -> String? {
  self.entity_type
}

///|
pub fn Finding::suggestion(self : Finding) -> String? {
  self.suggestion
}

///|
pub fn AuditReport::findings(self : AuditReport) -> Array[Finding] {
  self.findings.copy()
}

///|
pub fn AuditReport::entity_count(self : AuditReport) -> Int {
  self.entity_count
}

///|
pub fn AuditReport::type_count(self : AuditReport) -> Int {
  self.type_count
}

///|
pub fn AuditReport::reference_count(self : AuditReport) -> Int {
  self.reference_count
}
