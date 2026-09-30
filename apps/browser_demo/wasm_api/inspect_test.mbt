///|
test "browser API returns audit JSON and a spatial tree" {
  let source = "DATA;\n#1=IFCPROJECT('P');\n#2=IFCWALL('W',#404);\nENDSEC;"
  let result = @wasm_api.inspect_ifc(source)
  assert_true(result.contains("\"entity_count\":2"))
  assert_true(result.contains("\"spatial_tree\":\"#1 IFCPROJECT"))
  assert_true(result.contains("\"code\":\"REF001\""))
  assert_true(result.contains("\"parse_errors\":[]"))
}

///|
test "browser API preserves parser diagnostics and source locations" {
  let result = @wasm_api.inspect_ifc("DATA;\n#1=IFCWALL(1;")
  assert_true(result.contains("\"kind\":\"unterminated_aggregate\""))
  assert_true(result.contains("\"parse_errors\":["))
  assert_true(result.contains("\"location\":{\"line\":2,"))
}

///|
test "browser API JSON-escapes all spatial tree lines" {
  let result = @wasm_api.inspect_ifc("#1=IFCPROJECT();#2=IFCPROJECT();")
  assert_true(result.contains("#1 IFCPROJECT\\n#2 IFCPROJECT"))
  assert_true(!result.contains("#1 IFCPROJECT\n#2 IFCPROJECT"))
}

///|
test "numeric WASM bridge round-trips Unicode and can be reused" {
  let source = "DATA;\n#1=IFCPROJECT('🧱');\n#2=IFCWALL('W',#404);\nENDSEC;"
  @wasm_api.reset_input()
  for character in source.to_array() {
    @wasm_api.push_input_char(character.to_int())
  }
  @wasm_api.run_inspection()
  let first = StringBuilder()
  for index in 0..<@wasm_api.result_length() {
    match @wasm_api.result_char(index).to_char() {
      Some(character) => first.write_char(character)
      None => first.write_char('�')
    }
  }
  let result = first.to_string()
  assert_true(result.contains("\"entity_count\":2"))
  assert_true(result.contains("\"offset\":26"))
  assert_true(result.contains("\"code\":\"REF001\""))
}
