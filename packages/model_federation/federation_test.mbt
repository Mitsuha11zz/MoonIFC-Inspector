///|
fn model_source(
  name : String,
  source : String,
) -> @model_federation.ModelSource {
  @model_federation.ModelSource::new(
    name~,
    entities=@ifc_entities.build(
      @step_text.parse("DATA;\n" + source + "\nENDSEC;"),
    ),
  )
}

///|
test "federation audit reports a GlobalId shared by two files with provenance" {
  let report = @model_federation.audit([
    model_source("architecture.ifc", "#1=IFCWALL('shared-guid');"),
    model_source("structure.ifc", "#1=IFCDOOR('shared-guid');"),
  ])
  assert_eq(report.model_count(), 2)
  assert_eq(report.entity_count(), 2)
  let collisions = report.collisions()
  assert_eq(collisions.length(), 1)
  let collision = collisions[0]
  assert_eq(collision.code(), "FED001")
  assert_eq(collision.global_id(), "shared-guid")
  assert_eq(collision.first_model(), "architecture.ifc")
  assert_eq(collision.first_entity_id(), 1)
  assert_eq(collision.first_entity_type(), "IFCWALL")
  assert_eq(collision.duplicate_model(), "structure.ifc")
  assert_eq(collision.duplicate_entity_id(), 1)
  assert_eq(collision.duplicate_entity_type(), "IFCDOOR")
  assert_eq(collision.first_location().line(), 2)
  assert_eq(collision.duplicate_location().column(), 1)
}

///|
test "federation audit ignores duplicate IDs contained within one file" {
  let report = @model_federation.audit([
    model_source(
      "single-discipline.ifc", "#1=IFCWALL('same-guid');#2=IFCDOOR('same-guid');",
    ),
  ])
  assert_eq(report.collisions().length(), 0)
}

///|
test "federation audit ignores shared project and spatial context identifiers" {
  let report = @model_federation.audit([
    model_source(
      "architecture.ifc", "#1=IFCPROJECT('shared-project');#2=IFCBUILDING('shared-building');",
    ),
    model_source(
      "structure.ifc", "#1=IFCPROJECT('shared-project');#2=IFCBUILDING('shared-building');",
    ),
  ])
  assert_eq(report.collisions().length(), 0)
}

///|
test "federation audit reports each later model against the first owner" {
  let report = @model_federation.audit([
    model_source("a.ifc", "#10=IFCWALL('guid');"),
    model_source("b.ifc", "#20=IFCDOOR('guid');"),
    model_source("c.ifc", "#30=IFCWINDOW('guid');"),
  ])
  let collisions = report.collisions()
  assert_eq(collisions.length(), 2)
  assert_eq(collisions[0].first_model(), "a.ifc")
  assert_eq(collisions[0].duplicate_model(), "b.ifc")
  assert_eq(collisions[1].first_model(), "a.ifc")
  assert_eq(collisions[1].duplicate_model(), "c.ifc")
}

///|
test "federation audit ignores empty IDs and treats IDs as case-sensitive" {
  let report = @model_federation.audit([
    model_source("a.ifc", "#1=IFCWALL('');#2=IFCWALL('guid');"),
    model_source("b.ifc", "#3=IFCDOOR('GUID');#4=IFCDOOR($);"),
  ])
  assert_eq(report.collisions().length(), 0)
}

///|
test "federation report exposes copies of its model and finding arrays" {
  let report = @model_federation.audit([
    model_source("a.ifc", "#1=IFCWALL('guid');"),
    model_source("b.ifc", "#2=IFCDOOR('guid');"),
  ])
  let models = report.models()
  models.push("mutated.ifc")
  let collisions = report.collisions()
  collisions.clear()
  assert_eq(report.model_count(), 2)
  assert_eq(report.models().length(), 2)
  assert_eq(report.collisions().length(), 1)
}

///|
test "allowlisted shared GlobalIds are informational and retain discipline labels" {
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
  let collisions = report.collisions()
  assert_eq(collisions.length(), 1)
  assert_eq(collisions[0].code(), "FED002")
  assert_true(collisions[0].is_allowed())
  assert_eq(collisions[0].first_discipline(), "architectural")
  assert_eq(collisions[0].duplicate_discipline(), "structural")
  assert_eq(report.unexpected_collision_count(), 0)
  assert_eq(report.allowed_collision_count(), 1)
}

///|
test "shared GlobalId allowlist comparison is exact and case-sensitive" {
  let report = @model_federation.audit_with_allowlist(
    [
      model_source("architecture.ifc", "#1=IFCWALL('shared-guid');"),
      model_source("structure.ifc", "#2=IFCDOOR('shared-guid');"),
    ],
    ["SHARED-GUID"],
  )
  let collisions = report.collisions()
  assert_eq(collisions.length(), 1)
  assert_eq(collisions[0].code(), "FED001")
  assert_false(collisions[0].is_allowed())
  assert_eq(report.unexpected_collision_count(), 1)
}
