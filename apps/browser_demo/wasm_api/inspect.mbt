///|
fn quote_json(value : String) -> String {
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
fn parse_error_kind_name(kind : @step_text.ParseErrorKind) -> String {
  match kind {
    @step_text.InvalidSection => "invalid_section"
    @step_text.InvalidEntity => "invalid_entity"
    @step_text.InvalidValue => "invalid_value"
    @step_text.UnterminatedString => "unterminated_string"
    @step_text.UnterminatedAggregate => "unterminated_aggregate"
    @step_text.DuplicateEntityId => "duplicate_entity_id"
  }
}

///|
fn parse_error_json(error : @step_text.ParseError) -> String {
  let location = error.location()
  "{\"kind\":" +
  quote_json(parse_error_kind_name(error.kind())) +
  ",\"message\":" +
  quote_json(error.message()) +
  ",\"location\":{\"line\":" +
  location.line().to_string() +
  ",\"column\":" +
  location.column().to_string() +
  ",\"offset\":" +
  location.offset().to_string() +
  "}}"
}

///|
/// Parse and audit an IFC STEP string, returning one JSON object for the browser UI.
pub fn inspect_ifc(source : String) -> String {
  let document = @step_text.parse(source)
  let entities = @ifc_entities.build(document)
  let relation_map = @relation_map.build(entities)
  let report = @model_rules.audit(relation_map)
  let parse_errors : Array[String] = []
  for error in document.errors() {
    parse_errors.push(parse_error_json(error))
  }
  "{\"audit\":" +
  @report_view.json(report) +
  ",\"spatial_tree\":" +
  quote_json(@report_view.spatial_tree(relation_map)) +
  ",\"parse_errors\":[" +
  parse_errors.join(",") +
  "]}"
}

///|
/// The browser bridge exchanges Unicode scalar values through numeric WASM
/// exports because raw wasm-gc exports cannot accept JavaScript strings.
let bridge_buffer : Array[Int] = [0]

///|
#export_name("moonifc_reset_input")
pub fn reset_input() -> Unit {
  bridge_buffer.set(0, 0)
}

///|
#export_name("moonifc_push_input_char")
pub fn push_input_char(codepoint : Int) -> Unit {
  let next = bridge_buffer[0] + 1
  if next < bridge_buffer.length() {
    bridge_buffer.set(next, codepoint)
  } else {
    bridge_buffer.push(codepoint)
  }
  bridge_buffer[0] = next
}

///|
#export_name("moonifc_run_inspection")
pub fn run_inspection() -> Unit {
  let source = StringBuilder()
  for index in 1..<(bridge_buffer[0] + 1) {
    match bridge_buffer[index].to_char() {
      Some(character) => source.write_char(character)
      None => source.write_char('�')
    }
  }
  let result = inspect_ifc(source.to_string()).to_array()
  for index in 0..<result.length() {
    let target = index + 1
    let codepoint = result[index].to_int()
    if target < bridge_buffer.length() {
      bridge_buffer.set(target, codepoint)
    } else {
      bridge_buffer.push(codepoint)
    }
  }
  bridge_buffer.set(0, result.length())
}

///|
#export_name("moonifc_result_length")
pub fn result_length() -> Int {
  bridge_buffer[0]
}

///|
#export_name("moonifc_result_char")
pub fn result_char(index : Int) -> Int {
  bridge_buffer[index + 1]
}
