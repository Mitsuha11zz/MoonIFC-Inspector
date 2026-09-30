///|
fn review_model_source(
  name : String,
  discipline : String,
  source : String,
) -> @model_federation.ModelSource {
  @model_federation.ModelSource::new(
    name~,
    discipline~,
    entities=@ifc_entities.build(@step_text.parse(source)),
  )
}

///|
test "federation review combines model findings and cross-model collisions" {
  let report = @model_federation.review([
    review_model_source(
      "architecture", "architectural", "#1=IFCWALL('shared',#99);",
    ),
    review_model_source("structure", "structural", "#2=IFCDOOR('shared');"),
  ])
  let audits = report.model_audits()
  assert_eq(audits.length(), 2)
  assert_eq(audits[0].name(), "architecture")
  assert_eq(audits[0].discipline(), "architectural")
  assert_true(audits[0].report().findings().length() > 0)
  assert_eq(report.federation().unexpected_collision_count(), 1)
  assert_true(report.has_findings())
}

///|
test "federation review treats declared sharing as informational" {
  let report = @model_federation.review_with_allowlist(
    [
      review_model_source(
        "architecture",
        "A",
        "#1=IFCPROJECT('p');#2=IFCSITE('s');#3=IFCBUILDING('b');" +
        "#4=IFCBUILDINGSTOREY('floor');#5=IFCSPACE('space');" +
        "#6=IFCWALL('shared');" +
        "#10=IFCRELAGGREGATES('ra',$,$,$,#1,(#2));" +
        "#11=IFCRELAGGREGATES('rb',$,$,$,#2,(#3));" +
        "#12=IFCRELAGGREGATES('rc',$,$,$,#3,(#4));" +
        "#13=IFCRELAGGREGATES('rd',$,$,$,#4,(#5));" +
        "#14=IFCRELCONTAINEDINSPATIALSTRUCTURE('re',$,$,$,(#6),#5);",
      ),
      review_model_source(
        "structure",
        "S",
        "#1=IFCPROJECT('p');#2=IFCSITE('s');#3=IFCBUILDING('b');" +
        "#4=IFCBUILDINGSTOREY('floor');#5=IFCSPACE('space');" +
        "#6=IFCWALL('shared');" +
        "#10=IFCRELAGGREGATES('ra',$,$,$,#1,(#2));" +
        "#11=IFCRELAGGREGATES('rb',$,$,$,#2,(#3));" +
        "#12=IFCRELAGGREGATES('rc',$,$,$,#3,(#4));" +
        "#13=IFCRELAGGREGATES('rd',$,$,$,#4,(#5));" +
        "#14=IFCRELCONTAINEDINSPATIALSTRUCTURE('re',$,$,$,(#6),#5);",
      ),
    ],
    ["shared"],
  )
  assert_eq(report.local_finding_count(), 0)
  assert_eq(report.federation().allowed_collision_count(), 1)
  assert_false(report.has_findings())
}
