///|
pub enum Severity { Error; Warning; Info } derive(Eq, Debug)

///|
pub struct Finding {
  code : String
  severity : Severity
  entity_id : Int?
  entity_type : String?
  location : @ifc_entities.Entity?
  message : String
  suggestion : String?
} derive(Debug)

///|
pub struct AuditReport {
  findings : Array[Finding]
  entity_count : Int
  type_count : Int
  reference_count : Int
} derive(Debug)

///|
pub fn Finding::code(self : Finding) -> String { self.code }
///|
pub fn Finding::severity(self : Finding) -> Severity { self.severity }
///|
pub fn Finding::message(self : Finding) -> String { self.message }
///|
pub fn Finding::entity_id(self : Finding) -> Int? { self.entity_id }
///|
pub fn Finding::entity_type(self : Finding) -> String? { self.entity_type }
///|
pub fn Finding::suggestion(self : Finding) -> String? { self.suggestion }
///|
pub fn AuditReport::findings(self : AuditReport) -> Array[Finding] { self.findings.copy() }
///|
pub fn AuditReport::entity_count(self : AuditReport) -> Int { self.entity_count }
///|
pub fn AuditReport::type_count(self : AuditReport) -> Int { self.type_count }
///|
pub fn AuditReport::reference_count(self : AuditReport) -> Int { self.reference_count }
