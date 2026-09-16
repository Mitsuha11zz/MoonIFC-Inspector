///|
pub fn text(report : @model_rules.AuditReport) -> String {
  let lines : Array[String] = []
  lines.push("IFC entities: " + report.entity_count().to_string())
  lines.push("Types: " + report.type_count().to_string())
  lines.push("References: " + report.reference_count().to_string())
  for finding in report.findings() {
    let id = match finding.entity_id() { Some(value) => "#" + value.to_string(); None => "model" }
    lines.push("[" + finding.severity().to_string() + "] " + finding.code() + " " + id + " " + finding.message())
  }
  lines.join("\n")
}
