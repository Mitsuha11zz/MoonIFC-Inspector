///|
/// Per-model structural audit inside a federation review.
pub struct ModelAudit {
  name : String
  discipline : String
  report : @model_rules.AuditReport
} derive(Debug)

///|
pub extend ModelAudit with Debug::{to_repr}

///|
pub fn ModelAudit::name(self : ModelAudit) -> String {
  self.name
}

///|
pub fn ModelAudit::discipline(self : ModelAudit) -> String {
  self.discipline
}

///|
pub fn ModelAudit::report(self : ModelAudit) -> @model_rules.AuditReport {
  self.report
}

///|
/// A single result combining per-model checks with cross-model coordination checks.
pub struct FederationReviewReport {
  model_audits : Array[ModelAudit]
  federation : FederationReport
} derive(Debug)

///|
pub extend FederationReviewReport with Debug::{to_repr}

///|
pub fn FederationReviewReport::model_audits(
  self : FederationReviewReport,
) -> Array[ModelAudit] {
  self.model_audits.copy()
}

///|
pub fn FederationReviewReport::federation(
  self : FederationReviewReport,
) -> FederationReport {
  self.federation
}

///|
pub fn FederationReviewReport::local_finding_count(
  self : FederationReviewReport,
) -> Int {
  let mut count = 0
  for model_audit in self.model_audits {
    count += model_audit.report.findings().length()
  }
  count
}

///|
pub fn FederationReviewReport::has_findings(
  self : FederationReviewReport,
) -> Bool {
  self.local_finding_count() > 0 ||
  self.federation.unexpected_collision_count() > 0
}

///|
/// Review every model in a federation and check cross-model GlobalId policy.
///
/// Each model receives the built-in structural audit; cross-model identifier
/// collisions are then reported with model and discipline provenance.
pub fn review(models : Array[ModelSource]) -> FederationReviewReport {
  review_with_allowlist(models, [])
}

///|
/// Review every model in a federation while honoring explicitly shared IDs.
pub fn review_with_allowlist(
  models : Array[ModelSource],
  allowed_global_ids : Array[String],
) -> FederationReviewReport {
  let model_audits : Array[ModelAudit] = []
  for model in models {
    let relation_map = @relation_map.build(model.entities)
    model_audits.push({
      name: model.name,
      discipline: model.discipline,
      report: @model_rules.audit(relation_map),
    })
  }
  {
    model_audits,
    federation: audit_with_allowlist(models, allowed_global_ids),
  }
}
