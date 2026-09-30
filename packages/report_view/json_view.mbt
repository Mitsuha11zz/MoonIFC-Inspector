///|
fn quote(value : String) -> String {
  let builder = StringBuilder()
  builder.write_char('"')
  for character in value.to_array() {
    match character {
      '"' => builder.write_string("\\\"")
      '\\' => builder.write_string("\\\\")
      '\b' => builder.write_string("\\b")
      '\f' => builder.write_string("\\f")
      '\n' => builder.write_string("\\n")
      '\r' => builder.write_string("\\r")
      '\t' => builder.write_string("\\t")
      _ => {
        let codepoint = character.to_int()
        if codepoint < 0x20 {
          let digits = "0123456789abcdef".to_array()
          builder.write_string("\\u00")
          builder.write_char(digits[codepoint / 16])
          builder.write_char(digits[codepoint % 16])
        } else {
          builder.write_char(character)
        }
      }
    }
  }
  builder.write_char('"')
  builder.to_string()
}

///|
/// 可空字符串字段：缺失时输出 JSON null，否则输出带引号的字符串。
fn quote_opt(value : String?) -> String {
  match value {
    Some(text) => quote(text)
    None => "null"
  }
}

///|
/// 可空整数字段：缺失时输出 JSON null。
fn int_opt(value : Int?) -> String {
  match value {
    Some(number) => number.to_string()
    None => "null"
  }
}

///|
/// 源码位置字段：缺失时输出 JSON null，否则输出行、列与偏移量对象。
fn location_opt(value : @step_text.SourceLoc?) -> String {
  match value {
    Some(loc) =>
      "{\"line\":" +
      loc.line().to_string() +
      ",\"column\":" +
      loc.column().to_string() +
      ",\"offset\":" +
      loc.offset().to_string() +
      "}"
    None => "null"
  }
}

///|
pub fn json(report : @model_rules.AuditReport) -> String {
  let items : Array[String] = []
  for finding in report.findings() {
    items.push(
      "{\"code\":" +
      quote(finding.code()) +
      ",\"severity\":" +
      quote(finding.severity().to_string()) +
      ",\"entity_id\":" +
      int_opt(finding.entity_id()) +
      ",\"entity_type\":" +
      quote_opt(finding.entity_type()) +
      ",\"target_id\":" +
      int_opt(finding.target_id()) +
      ",\"location\":" +
      location_opt(finding.location()) +
      ",\"message\":" +
      quote(finding.message()) +
      ",\"suggestion\":" +
      quote_opt(finding.suggestion()) +
      "}",
    )
  }
  "{\"entity_count\":" +
  report.entity_count().to_string() +
  ",\"type_count\":" +
  report.type_count().to_string() +
  ",\"reference_count\":" +
  report.reference_count().to_string() +
  ",\"findings\":[" +
  items.join(",") +
  "]}"
}
