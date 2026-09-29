///|
/// Render a cross-file GlobalId collision report as readable text.
pub fn federation_text(report : @model_federation.FederationReport) -> String {
  let lines : Array[String] = []
  let models = report.models()
  let collisions = report.collisions()
  lines.push("IFC models: " + report.model_count().to_string())
  lines.push("Entities: " + report.entity_count().to_string())
  lines.push(
    "Cross-file GlobalId collisions: " + collisions.length().to_string(),
  )
  lines.push("Models:")
  for model in models {
    lines.push("  " + model)
  }
  for collision in collisions {
    lines.push(
      "[warning] " +
      collision.code() +
      " GlobalId '" +
      collision.global_id() +
      "' is reused across files; verify whether these records represent the same component: " +
      collision.first_model() +
      " #" +
      collision.first_entity_id().to_string() +
      " " +
      collision.first_entity_type() +
      " at " +
      collision.first_location().to_string() +
      " and " +
      collision.duplicate_model() +
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
/// Serialize a cross-file GlobalId collision report in stable JSON form.
pub fn federation_json(report : @model_federation.FederationReport) -> String {
  let model_items : Array[String] = []
  for model in report.models() {
    model_items.push(quote(model))
  }
  let collision_items : Array[String] = []
  for collision in report.collisions() {
    collision_items.push(
      "{\"code\":" +
      quote(collision.code()) +
      ",\"severity\":\"warning\"" +
      ",\"global_id\":" +
      quote(collision.global_id()) +
      ",\"first_model\":" +
      quote(collision.first_model()) +
      ",\"first_entity_id\":" +
      collision.first_entity_id().to_string() +
      ",\"first_entity_type\":" +
      quote(collision.first_entity_type()) +
      ",\"first_location\":" +
      location_opt(Some(collision.first_location())) +
      ",\"duplicate_model\":" +
      quote(collision.duplicate_model()) +
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
  ",\"models\":[" +
  model_items.join(",") +
  "],\"collision_count\":" +
  collision_items.length().to_string() +
  ",\"collisions\":[" +
  collision_items.join(",") +
  "]}"
}
