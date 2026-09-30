///|
/// Render a cross-file GlobalId collision report as readable text.
pub fn federation_text(report : @model_federation.FederationReport) -> String {
  let lines : Array[String] = []
  let models = report.models()
  let disciplines = report.disciplines()
  let collisions = report.collisions()
  lines.push("IFC models: " + report.model_count().to_string())
  lines.push("Entities: " + report.entity_count().to_string())
  lines.push(
    "Cross-file GlobalId collisions: " +
    collisions.length().to_string() +
    " (unexpected: " +
    report.unexpected_collision_count().to_string() +
    ", declared shared: " +
    report.allowed_collision_count().to_string() +
    ")",
  )
  lines.push("Models:")
  for index, model in models {
    lines.push("  " + model_label(model, disciplines[index]))
  }
  for collision in collisions {
    let severity = if collision.is_allowed() { "info" } else { "warning" }
    let explanation = if collision.is_allowed() {
      "is declared as a shared component by the federation manifest"
    } else {
      "is reused across files; verify whether these records represent the same component"
    }
    lines.push(
      "[" +
      severity +
      "] " +
      collision.code() +
      " GlobalId '" +
      collision.global_id() +
      "' " +
      explanation +
      ": " +
      model_label(collision.first_model(), collision.first_discipline()) +
      " #" +
      collision.first_entity_id().to_string() +
      " " +
      collision.first_entity_type() +
      " at " +
      collision.first_location().to_string() +
      " and " +
      model_label(collision.duplicate_model(), collision.duplicate_discipline()) +
      " #" +
      collision.duplicate_entity_id().to_string() +
      " " +
      collision.duplicate_entity_type() +
      " at " +
      collision.duplicate_location().to_string(),
    )
  }
  lines.join("\n")
}

///|
fn model_label(name : String, discipline : String) -> String {
  if discipline == "" {
    name
  } else {
    name + " [" + discipline + "]"
  }
}

///|
/// Serialize a cross-file GlobalId collision report in stable JSON form.
pub fn federation_json(report : @model_federation.FederationReport) -> String {
  let model_items : Array[String] = []
  for model in report.models() {
    model_items.push(quote(model))
  }
  let discipline_items : Array[String] = []
  for discipline in report.disciplines() {
    discipline_items.push(quote(discipline))
  }
  let collision_items : Array[String] = []
  for collision in report.collisions() {
    let severity = if collision.is_allowed() { "info" } else { "warning" }
    collision_items.push(
      "{\"code\":" +
      quote(collision.code()) +
      ",\"severity\":" +
      quote(severity) +
      ",\"declared_shared\":" +
      collision.is_allowed().to_string() +
      ",\"global_id\":" +
      quote(collision.global_id()) +
      ",\"first_model\":" +
      quote(collision.first_model()) +
      ",\"first_discipline\":" +
      quote(collision.first_discipline()) +
      ",\"first_entity_id\":" +
      collision.first_entity_id().to_string() +
      ",\"first_entity_type\":" +
      quote(collision.first_entity_type()) +
      ",\"first_location\":" +
      location_opt(Some(collision.first_location())) +
      ",\"duplicate_model\":" +
      quote(collision.duplicate_model()) +
      ",\"duplicate_discipline\":" +
      quote(collision.duplicate_discipline()) +
      ",\"duplicate_entity_id\":" +
      collision.duplicate_entity_id().to_string() +
      ",\"duplicate_entity_type\":" +
      quote(collision.duplicate_entity_type()) +
      ",\"duplicate_location\":" +
      location_opt(Some(collision.duplicate_location())) +
      "}",
    )
  }
  "{\"model_count\":" +
  report.model_count().to_string() +
  ",\"entity_count\":" +
  report.entity_count().to_string() +
  ",\"unexpected_collision_count\":" +
  report.unexpected_collision_count().to_string() +
  ",\"declared_shared_count\":" +
  report.allowed_collision_count().to_string() +
  ",\"models\":[" +
  model_items.join(",") +
  "],\"disciplines\":[" +
  discipline_items.join(",") +
  "],\"collision_count\":" +
  collision_items.length().to_string() +
  ",\"collisions\":[" +
  collision_items.join(",") +
  "]}"
}

///|
/// Render a complete federation review, including each model's audit findings.
pub fn federation_review_text(
  report : @model_federation.FederationReviewReport,
) -> String {
  let lines : Array[String] = []
  let audits = report.model_audits()
  lines.push("Federation coordination review")
  lines.push("Models: " + audits.length().to_string())
  lines.push(
    "Model-level findings: " + report.local_finding_count().to_string(),
  )
  for audit in audits {
    lines.push("")
    lines.push("Model: " + model_label(audit.name(), audit.discipline()))
    lines.push(text(audit.report()))
  }
  lines.push("")
  lines.push("Cross-model review:")
  lines.push(federation_text(report.federation()))
  lines.join("\n")
}

///|
/// Serialize a complete federation review as one stable JSON document.
pub fn federation_review_json(
  report : @model_federation.FederationReviewReport,
) -> String {
  let audits : Array[String] = []
  for model_audit in report.model_audits() {
    audits.push(
      "{\"name\":" +
      quote(model_audit.name()) +
      ",\"discipline\":" +
      quote(model_audit.discipline()) +
      ",\"audit\":" +
      json(model_audit.report()) +
      "}",
    )
  }
  "{\"model_count\":" +
  audits.length().to_string() +
  ",\"local_finding_count\":" +
  report.local_finding_count().to_string() +
  ",\"has_findings\":" +
  report.has_findings().to_string() +
  ",\"model_audits\":[" +
  audits.join(",") +
  "],\"federation\":" +
  federation_json(report.federation()) +
  "}"
}
