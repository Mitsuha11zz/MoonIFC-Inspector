///|
/// Render a federation revision diff as concise, deterministic text.
pub fn federation_diff_text(
  report : @model_federation.FederationDiffReport,
) -> String {
  let lines : Array[String] = []
  lines.push("IFC federation revision diff")
  lines.push("Before models: " + report.before_models().length().to_string())
  lines.push("After models: " + report.after_models().length().to_string())
  lines.push(
    "Changes: " +
    report.change_count().to_string() +
    " (added: " +
    report.added_count().to_string() +
    ", removed: " +
    report.removed_count().to_string() +
    ", modified: " +
    report.modified_count().to_string() +
    ", ambiguous: " +
    report.ambiguous_count().to_string() +
    ")",
  )
  lines.push("Before:")
  for model in report.before_models() {
    lines.push("  " + model)
  }
  lines.push("After:")
  for model in report.after_models() {
    lines.push("  " + model)
  }
  for change in report.changes() {
    lines.push(
      "[" +
      change.kind().label() +
      "] " +
      change.model_name() +
      discipline_change_label(
        change.before_discipline(),
        change.after_discipline(),
      ) +
      " GlobalId '" +
      change.global_id() +
      "': " +
      entity_revision_label(
        change.before_entity_type(),
        change.before_entity_id(),
      ) +
      " -> " +
      entity_revision_label(
        change.after_entity_type(),
        change.after_entity_id(),
      ),
    )
    let changed_arguments = change.changed_arguments()
    if changed_arguments.length() > 0 {
      lines.push(
        "  Changed STEP argument positions (1-based): " +
        changed_arguments.map(index => index.to_string()).join(", "),
      )
    }
    let before_path = change.before_spatial_path()
    let after_path = change.after_spatial_path()
    if before_path.length() > 0 {
      lines.push("  Before spatial path: " + before_path.join(" -> "))
    }
    if after_path.length() > 0 {
      lines.push("  After spatial path: " + after_path.join(" -> "))
    }
    let before_relationships = change.before_relationships()
    let after_relationships = change.after_relationships()
    if before_relationships.length() > 0 {
      lines.push(
        "  Before referring relationships: " + before_relationships.join(", "),
      )
    }
    if after_relationships.length() > 0 {
      lines.push(
        "  After referring relationships: " + after_relationships.join(", "),
      )
    }
    let related_models = change.related_models()
    if related_models.length() > 0 {
      lines.push(
        "  Same GlobalId also appears in: " + related_models.join(", "),
      )
    }
  }
  lines.join("\n")
}

///|
fn discipline_change_label(before : String?, after : String?) -> String {
  match (before, after) {
    (Some(old), Some(current)) if old != current =>
      " [" + old + " -> " + current + "]"
    (Some(value), _) | (_, Some(value)) if value != "" => " [" + value + "]"
    _ => ""
  }
}

///|
fn entity_revision_label(entity_type : String?, entity_id : Int?) -> String {
  match (entity_type, entity_id) {
    (Some(kind), Some(id)) => kind + " #" + id.to_string()
    _ => "(none)"
  }
}

///|
fn json_string_array(values : Array[String]) -> String {
  let items : Array[String] = []
  for value in values {
    items.push(quote(value))
  }
  "[" + items.join(",") + "]"
}

///|
fn json_int_array(values : Array[Int]) -> String {
  let items : Array[String] = []
  for value in values {
    items.push(value.to_string())
  }
  "[" + items.join(",") + "]"
}

///|
fn json_entity_revision(entity_type : String?, entity_id : Int?) -> String {
  match (entity_type, entity_id) {
    (Some(kind), Some(id)) =>
      "{\"entity_type\":" +
      quote(kind) +
      ",\"entity_id\":" +
      id.to_string() +
      "}"
    _ => "null"
  }
}

///|
/// Serialize a federation revision diff with stable field and item ordering.
pub fn federation_diff_json(
  report : @model_federation.FederationDiffReport,
) -> String {
  let changes : Array[String] = []
  for change in report.changes() {
    changes.push(
      "{\"status\":" +
      quote(change.kind().label()) +
      ",\"model\":" +
      quote(change.model_name()) +
      ",\"before_discipline\":" +
      quote_opt(change.before_discipline()) +
      ",\"after_discipline\":" +
      quote_opt(change.after_discipline()) +
      ",\"global_id\":" +
      quote(change.global_id()) +
      ",\"before\":" +
      json_entity_revision(
        change.before_entity_type(),
        change.before_entity_id(),
      ) +
      ",\"after\":" +
      json_entity_revision(change.after_entity_type(), change.after_entity_id()) +
      ",\"changed_arguments\":" +
      json_int_array(change.changed_arguments()) +
      ",\"before_spatial_path\":" +
      json_string_array(change.before_spatial_path()) +
      ",\"after_spatial_path\":" +
      json_string_array(change.after_spatial_path()) +
      ",\"before_relationships\":" +
      json_string_array(change.before_relationships()) +
      ",\"after_relationships\":" +
      json_string_array(change.after_relationships()) +
      ",\"related_models\":" +
      json_string_array(change.related_models()) +
      "}",
    )
  }
  "{\"before_models\":" +
  json_string_array(report.before_models()) +
  ",\"after_models\":" +
  json_string_array(report.after_models()) +
  ",\"change_count\":" +
  report.change_count().to_string() +
  ",\"added_count\":" +
  report.added_count().to_string() +
  ",\"removed_count\":" +
  report.removed_count().to_string() +
  ",\"modified_count\":" +
  report.modified_count().to_string() +
  ",\"ambiguous_count\":" +
  report.ambiguous_count().to_string() +
  ",\"changes\":[" +
  changes.join(",") +
  "]}"
}
