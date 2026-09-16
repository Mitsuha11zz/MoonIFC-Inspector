///|
fn quote(value : String) -> String { "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\"" }

///|
pub fn json(report : @model_rules.AuditReport) -> String {
  let items : Array[String] = []
  for finding in report.findings() {
    let id = match finding.entity_id() { Some(value) => value.to_string(); None => "null" }
    items.push("{\"code\":" + quote(finding.code()) + ",\"severity\":" + quote(finding.severity().to_string()) + ",\"entity_id\":" + id + ",\"message\":" + quote(finding.message()) + "}")
  }
  "{\"entity_count\":" + report.entity_count().to_string() + ",\"type_count\":" + report.type_count().to_string() + ",\"reference_count\":" + report.reference_count().to_string() + ",\"findings\":[" + items.join(",") + "]}"
}
