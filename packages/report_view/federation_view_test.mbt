///|
fn federation_report_for_view() -> @model_federation.FederationReport {
  let first = @ifc_entities.build(
    @step_text.parse("DATA;\n#1=IFCWALL('shared-guid');\nENDSEC;"),
  )
  let second = @ifc_entities.build(
    @step_text.parse("DATA;\n#2=IFCDOOR('shared-guid');\nENDSEC;"),
  )
  @model_federation.audit([
    @model_federation.ModelSource::new(name="architecture.ifc", entities=first),
    @model_federation.ModelSource::new(name="structure.ifc", entities=second),
  ])
}

///|
test "federation text view includes both model names and source positions" {
  let text = @report_view.federation_text(federation_report_for_view())
  assert_true(text.contains("IFC models: 2"))
  assert_true(text.contains("Cross-file GlobalId collisions: 1"))
  assert_true(text.contains("[warning] FED001"))
  assert_true(text.contains("architecture.ifc #1 IFCWALL at line 2:1"))
  assert_true(text.contains("structure.ifc #2 IFCDOOR at line 2:1"))
}

///|
test "federation JSON view is stable and escapes model names" {
  let entities = @ifc_entities.build(
    @step_text.parse("DATA;\n#1=IFCWALL('shared-guid');\nENDSEC;"),
  )
  let report = @model_federation.audit([
    @model_federation.ModelSource::new(name="architecture\n.ifc", entities~),
    @model_federation.ModelSource::new(name="structure.ifc", entities~),
  ])
  let json = @report_view.federation_json(report)
  assert_true(
    json.contains("\"models\":[\"architecture\\n.ifc\",\"structure.ifc\"]"),
  )
  assert_true(json.contains("\"code\":\"FED001\""))
  assert_true(json.contains("\"severity\":\"warning\""))
  assert_true(
    json.contains("\"first_location\":{\"line\":2,\"column\":1,\"offset\":6}"),
  )
  assert_true(json.contains("\"duplicate_model\":\"structure.ifc\""))
}

///|
test "federation views mark manifest-approved sharing as informational" {
  let report = @model_federation.audit_with_allowlist(
    [
      @model_federation.ModelSource::new(
        name="architecture",
        entities=@ifc_entities.build(
          @step_text.parse("#1=IFCWALL('shared-guid');"),
        ),
        discipline="architectural",
      ),
      @model_federation.ModelSource::new(
        name="structure",
        entities=@ifc_entities.build(
          @step_text.parse("#2=IFCDOOR('shared-guid');"),
        ),
        discipline="structural",
      ),
    ],
    ["shared-guid"],
  )
  let text = @report_view.federation_text(report)
  let json = @report_view.federation_json(report)
  assert_true(text.contains("unexpected: 0, declared shared: 1"))
  assert_true(text.contains("[info] FED002"))
  assert_true(text.contains("architecture [architectural]"))
  assert_true(json.contains("\"unexpected_collision_count\":0"))
  assert_true(json.contains("\"declared_shared\":true"))
  assert_true(json.contains("\"severity\":\"info\""))
  assert_true(json.contains("\"duplicate_discipline\":\"structural\""))
}
