///|
fn revision_view_source(
  name : String,
  source : String,
) -> @model_federation.ModelSource {
  @model_federation.ModelSource::new(
    name~,
    discipline="architectural",
    entities=@ifc_entities.build(@step_text.parse(source)),
  )
}

///|
test "federation diff JSON has a stable empty report shape" {
  let report = @model_federation.compare_revisions([], [])
  assert_eq(
    @report_view.federation_diff_json(report),
    "{\"before_models\":[],\"after_models\":[],\"change_count\":0," +
    "\"added_count\":0,\"removed_count\":0,\"modified_count\":0," +
    "\"ambiguous_count\":0,\"changes\":[]}",
  )
}

///|
test "federation diff JSON and text expose changes and spatial impact" {
  let before = [
    revision_view_source(
      "architecture",
      "#10=IFCBUILDINGSTOREY('floor');" +
      "#11=IFCWALL('wall','old');" +
      "#12=IFCRELCONTAINEDINSPATIALSTRUCTURE('rel',$,$,$,(#11),#10);",
    ),
  ]
  let after = [
    revision_view_source(
      "architecture",
      "#20=IFCBUILDINGSTOREY('floor');" +
      "#21=IFCWALL('wall','new');" +
      "#22=IFCRELCONTAINEDINSPATIALSTRUCTURE('rel',$,$,$,(#21),#20);",
    ),
  ]
  let report = @model_federation.compare_revisions(before, after)
  let json = @report_view.federation_diff_json(report)
  assert_true(json.contains("\"status\":\"modified\""))
  assert_true(json.contains("\"changed_arguments\":[2]"))
  assert_true(json.contains("IFCBUILDINGSTOREY#10 [floor]"))
  assert_true(json.contains("IFCRELCONTAINEDINSPATIALSTRUCTURE#22 [rel]"))
  assert_true(json.contains("\"after_impact_paths\":[{"))
  assert_true(json.contains("\"after_impact_paths_truncated\":false"))
  assert_eq(json, @report_view.federation_diff_json(report))
  let text = @report_view.federation_diff_text(report)
  assert_true(text.contains("Changes: 1 (added: 0, removed: 0, modified: 1"))
  assert_true(
    text.contains("Before spatial path: IFCBUILDINGSTOREY#10 [floor]"),
  )
  assert_true(text.contains("After referring relationships:"))
  assert_true(text.contains("After structural impact paths:"))
  assert_true(
    text.contains(
      "IFCWALL#21 [wall] -> IFCRELCONTAINEDINSPATIALSTRUCTURE#22 [rel]",
    ),
  )
}
