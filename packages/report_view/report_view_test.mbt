///|
fn report_of(source : String) -> @model_rules.AuditReport {
  @model_rules.audit(
    @relation_map.build(@ifc_entities.build(@step_text.parse(source))),
  )
}

///|
fn map_of(source : String) -> @relation_map.RelationMap {
  @relation_map.build(@ifc_entities.build(@step_text.parse(source)))
}

///|
test "json view reports statistics and an empty findings array" {
  assert_eq(
    @report_view.json(report_of("")),
    "{\"entity_count\":0,\"type_count\":0,\"reference_count\":0,\"findings\":[]}",
  )
  assert_eq(
    @report_view.json(report_of("#1=IFCPROJECT('P',());")),
    "{\"entity_count\":1,\"type_count\":1,\"reference_count\":0,\"findings\":[]}",
  )
}

///|
test "json view emits every finding field with a lowercase severity" {
  let json = @report_view.json(report_of("#4=IFCWALL('W',#404);"))
  assert_eq(
    json,
    "{\"entity_count\":1,\"type_count\":1,\"reference_count\":1,\"findings\":" +
    "[{\"code\":\"REF001\",\"severity\":\"error\",\"entity_id\":4," +
    "\"entity_type\":\"IFCWALL\",\"target_id\":404," +
    "\"location\":{\"line\":1,\"column\":1,\"offset\":0}," +
    "\"message\":\"reference #404 does not exist\"," +
    "\"suggestion\":\"add the referenced entity or correct the stale reference\"}]}",
  )
}

///|
test "json view serializes the source location as an object" {
  let json = @report_view.json(report_of("\n  #4=IFCWALL('W',#404);"))
  assert_true(json.contains("\"location\":{\"line\":2,\"column\":3,\"offset\":3}"))
}

///|
test "json view escapes backslashes in string values" {
  let escaped = @report_view.json(report_of("#1=IFCPROJECT('a\\\\b',());"))
  assert_true(escaped.contains("\\\\"))
}

///|
test "text view reports statistics on the first lines" {
  let text = @report_view.text(report_of("#4=IFCWALL('W',#404);"))
  let lines = text.split("\n").to_array()
  assert_eq(lines[0], "IFC entities: 1")
  assert_eq(lines[1], "Types: 1")
  assert_eq(lines[2], "References: 1")
  assert_true(text.contains("REF001"))
  assert_true(text.contains("#4"))
}

///|
test "tree view lists each entity with its outgoing references" {
  let tree = @report_view.tree(map_of("#1=IFCWALL('W',#2);\n#2=IFCPROJECT('P',());"))
  let lines = tree.split("\n").to_array()
  assert_eq(lines.length(), 2)
  assert_true(lines[0].contains("#1"))
  assert_true(lines[0].contains("IFCWALL"))
  assert_true(lines[0].contains("#2"))
  assert_true(lines[1].contains("IFCPROJECT"))
}
