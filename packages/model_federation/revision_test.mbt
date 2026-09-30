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
test "revision diff traces deterministic multi-hop structural impact paths" {
  let before = [
    revision_model_source(
      "architecture",
      "architectural",
      "#1=IFCBUILDINGSTOREY('floor');" +
      "#2=IFCSPACE('room_a');" +
      "#3=IFCSPACE('room_b');" +
      "#4=IFCWALL('wall','Old Name');" +
      "#5=IFCDOOR('door','Door Name');" +
      "#6=IFCWALL('other_wall','Other Wall');" +
      "#20=IFCRELAGGREGATES('building_rel',$,$,$,#1,(#2,#3));" +
      "#21=IFCRELCONTAINEDINSPATIALSTRUCTURE('rel_a',$,$,$,(#4,#5),#2);" +
      "#22=IFCRELCONTAINEDINSPATIALSTRUCTURE('rel_b',$,$,$,(#6),#3);",
    ),
  ]
  let after = [
    revision_model_source(
      "architecture",
      "architectural",
      "#1=IFCBUILDINGSTOREY('floor');" +
      "#2=IFCSPACE('room_a');" +
      "#3=IFCSPACE('room_b');" +
      "#4=IFCWALL('wall','New Name');" +
      "#5=IFCDOOR('door','Door Name');" +
      "#6=IFCWALL('other_wall','Other Wall');" +
      "#20=IFCRELAGGREGATES('building_rel',$,$,$,#1,(#2,#3));" +
      "#21=IFCRELCONTAINEDINSPATIALSTRUCTURE('rel_a',$,$,$,(#4,#5),#2);" +
      "#22=IFCRELCONTAINEDINSPATIALSTRUCTURE('rel_b',$,$,$,(#6),#3);",
    ),
  ]
  let report = @model_federation.compare_revisions(before, after)
  assert_eq(report.change_count(), 1)
  let change = report.changes()[0]
  let paths = change.after_impact_paths()
  assert_true(paths.length() >= 5)
  assert_true(!change.after_impact_paths_truncated())
  let mut found_remote_wall = false
  for path in paths {
    if path.entity_id() == 6 {
      found_remote_wall = true
      assert_eq(path.entity_type(), "IFCWALL")
      assert_eq(path.path(), [
        "IFCWALL#4 [wall]", "IFCRELCONTAINEDINSPATIALSTRUCTURE#21 [rel_a]", "IFCSPACE#2 [room_a]",
        "IFCRELAGGREGATES#20 [building_rel]", "IFCSPACE#3 [room_b]", "IFCRELCONTAINEDINSPATIALSTRUCTURE#22 [rel_b]",
        "IFCWALL#6 [other_wall]",
      ])
    }
  }
  assert_true(found_remote_wall)
  assert_eq(paths, change.after_impact_paths())
}

///|
test "revision impact paths stop at a stable limit and report truncation" {
  let mut before_source = ""
  let mut after_source = ""
  let mut related_ids = ""
  for index in 0..<102 {
    let id = index + 1
    let global_id = "wall_" + id.to_string()
    let before_name = if id == 1 { "Old" } else { "Same" }
    let after_name = if id == 1 { "New" } else { "Same" }
    before_source = before_source +
      "#" +
      id.to_string() +
      "=IFCWALL('" +
      global_id +
      "','" +
      before_name +
      "');"
    after_source = after_source +
      "#" +
      id.to_string() +
      "=IFCWALL('" +
      global_id +
      "','" +
      after_name +
      "');"
    if index > 0 {
      related_ids = related_ids + ","
    }
    related_ids = related_ids + "#" + id.to_string()
  }
  let relation = "#2000=IFCSPACE('room');" +
    "#3000=IFCRELCONTAINEDINSPATIALSTRUCTURE('contains',$,$,$,(" +
    related_ids +
    "),#2000);"
  before_source = before_source + relation
  after_source = after_source + relation
  let report = @model_federation.compare_revisions(
    [revision_model_source("architecture", "A", before_source)],
    [revision_model_source("architecture", "A", after_source)],
  )
  assert_eq(report.change_count(), 1)
  let paths = report.changes()[0].after_impact_paths()
  assert_eq(paths.length(), 100)
  assert_true(report.changes()[0].after_impact_paths_truncated())
  assert_eq(paths[0].entity_id(), 2)
  assert_eq(paths[99].entity_id(), 101)
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
