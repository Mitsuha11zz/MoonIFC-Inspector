///|
fn revision_model_source(
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
test "revision diff ignores STEP id changes and reports spatial relationship context" {
  let before = [
    revision_model_source(
      "architecture",
      "architectural",
      "#10=IFCBUILDINGSTOREY('floor');" +
      "#11=IFCWALL('wall',#90,'Old Name',$);" +
      "#12=IFCRELCONTAINEDINSPATIALSTRUCTURE('rel',$,$,$,(#11),#10);" +
      "#90=IFCOWNERHISTORY('history');",
    ),
  ]
  let after = [
    revision_model_source(
      "architecture",
      "architectural",
      "#100=IFCBUILDINGSTOREY('floor');" +
      "#101=IFCWALL('wall',#190,'New Name',$);" +
      "#102=IFCRELCONTAINEDINSPATIALSTRUCTURE('rel',$,$,$,(#101),#100);" +
      "#190=IFCOWNERHISTORY('history');",
    ),
  ]
  let report = @model_federation.compare_revisions(before, after)
  assert_eq(report.change_count(), 1)
  assert_eq(report.modified_count(), 1)
  let change = report.changes()[0]
  assert_eq(change.kind(), @model_federation.Modified)
  assert_eq(change.global_id(), "wall")
  assert_eq(change.before_entity_id(), Some(11))
  assert_eq(change.after_entity_id(), Some(101))
  assert_eq(change.changed_arguments(), [3])
  assert_eq(change.before_spatial_path(), ["IFCBUILDINGSTOREY#10 [floor]"])
  assert_eq(change.after_spatial_path(), ["IFCBUILDINGSTOREY#100 [floor]"])
  assert_eq(change.before_relationships(), [
    "IFCRELCONTAINEDINSPATIALSTRUCTURE#12 [rel]",
  ])
  assert_eq(change.after_relationships(), [
    "IFCRELCONTAINEDINSPATIALSTRUCTURE#102 [rel]",
  ])
}

///|
test "revision diff ignores renumbered STEP references when structure is unchanged" {
  let before = [
    revision_model_source(
      "architecture",
      "architectural",
      "#10=IFCBUILDINGSTOREY('floor');" +
      "#11=IFCWALL('wall',#90,'Name',$);" +
      "#12=IFCRELCONTAINEDINSPATIALSTRUCTURE('rel',$,$,$,(#11),#10);" +
      "#90=IFCOWNERHISTORY('history');",
    ),
  ]
  let after = [
    revision_model_source(
      "architecture",
      "architectural",
      "#100=IFCBUILDINGSTOREY('floor');" +
      "#101=IFCWALL('wall',#190,'Name',$);" +
      "#102=IFCRELCONTAINEDINSPATIALSTRUCTURE('rel',$,$,$,(#101),#100);" +
      "#190=IFCOWNERHISTORY('history');",
    ),
  ]
  let report = @model_federation.compare_revisions(before, after)
  assert_eq(report.change_count(), 0)
}

///|
test "revision diff classifies added and removed elements in stable order" {
  let report = @model_federation.compare_revisions(
    [revision_model_source("architecture", "A", "#1=IFCWALL('removed');")],
    [revision_model_source("architecture", "A", "#2=IFCDOOR('added');")],
  )
  assert_eq(report.added_count(), 1)
  assert_eq(report.removed_count(), 1)
  let changes = report.changes()
  assert_eq(changes[0].kind(), @model_federation.Removed)
  assert_eq(changes[0].global_id(), "removed")
  assert_eq(changes[1].kind(), @model_federation.Added)
  assert_eq(changes[1].global_id(), "added")
}

///|
test "revision diff identifies other disciplines sharing a changed GlobalId" {
  let before = [
    revision_model_source(
      "architecture", "architectural", "#1=IFCWALL('shared','a');",
    ),
    revision_model_source(
      "structure", "structural", "#2=IFCDOOR('shared','a');",
    ),
  ]
  let after = [
    revision_model_source(
      "architecture", "architectural", "#3=IFCWALL('shared','b');",
    ),
    revision_model_source(
      "structure", "structural", "#4=IFCDOOR('shared','a');",
    ),
  ]
  let report = @model_federation.compare_revisions(before, after)
  assert_eq(report.modified_count(), 1)
  assert_eq(report.changes()[0].related_models(), ["structure"])
}

///|
test "revision diff marks duplicate GlobalIds as ambiguous instead of guessing" {
  let before = [
    revision_model_source(
      "architecture", "architectural", "#1=IFCWALL('duplicate');#2=IFCDOOR('duplicate');",
    ),
  ]
  let after = [
    revision_model_source(
      "architecture", "architectural", "#7=IFCWALL('duplicate');",
    ),
  ]
  let report = @model_federation.compare_revisions(before, after)
  assert_eq(report.ambiguous_count(), 1)
  assert_eq(report.change_count(), 1)
  assert_eq(report.changes()[0].kind(), @model_federation.Ambiguous)
}

///|
test "revision diff recognizes models added and removed by manifest name" {
  let before = [revision_model_source("old-model", "A", "#1=IFCWALL('old');")]
  let after = [revision_model_source("new-model", "B", "#2=IFCWALL('new');")]
  let report = @model_federation.compare_revisions(before, after)
  assert_eq(report.removed_count(), 1)
  assert_eq(report.added_count(), 1)
  assert_eq(report.before_models(), ["old-model [A]"])
  assert_eq(report.after_models(), ["new-model [B]"])
}
