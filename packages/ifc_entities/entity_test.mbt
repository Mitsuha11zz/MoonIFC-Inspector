///|
test "build preserves source order, location, and entity categories" {
  let source = "DATA;\n#7=IFCWALL('WALL-7',#2);\n#2=IFCBUILDINGSTOREY('FLOOR-2');\n#9=IFCRELAGGREGATES('REL-9',#2,(#7));\nENDSEC;"
  let entities = @ifc_entities.build(@step_text.parse(source))
  assert_eq(entities.length(), 3)
  assert_eq(entities[0].id(), 7)
  assert_eq(entities[1].id(), 2)
  assert_eq(entities[2].id(), 9)
  assert_eq(entities[0].category(), @ifc_entities.Element)
  assert_eq(entities[1].category(), @ifc_entities.Spatial)
  assert_eq(entities[2].category(), @ifc_entities.Relationship)
  assert_eq(entities[0].location().line(), 2)
  assert_eq(entities[0].global_id(), Some("WALL-7"))
}

///|
test "GlobalId is the first attribute only for supported entities" {
  let source = "#1=IFCWALL($,'display name');#2=IFCMATERIAL('concrete',#3);#3=IFCPROJECT('PROJECT-3');"
  let entities = @ifc_entities.build(@step_text.parse(source))
  assert_eq(entities[0].global_id(), None)
  assert_eq(entities[1].category(), @ifc_entities.Unsupported)
  assert_eq(entities[1].global_id(), None)
  assert_eq(entities[1].references(), [3])
  assert_eq(entities[2].category(), @ifc_entities.Project)
  assert_eq(entities[2].global_id(), Some("PROJECT-3"))
  assert_true(@ifc_entities.is_supported("ifcdoor"))
  assert_false(@ifc_entities.is_supported("IFCMATERIAL"))
}

///|
test "nested references are unique and retain first appearance order" {
  let document = @step_text.parse("#1=IFCWALL('W-1',(#9,#2,(#9,#3)),#2,#9);")
  let entity = @ifc_entities.build(document)[0]
  assert_eq(entity.references(), [9, 2, 3])
  let references = entity.references()
  references.push(42)
  assert_eq(entity.references(), [9, 2, 3])
  let args = entity.args()
  args.push(@step_text.Derived)
  assert_eq(entity.args().length(), 4)
}
