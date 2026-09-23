///|
fn map_from(source : String) -> @relation_map.RelationMap {
  @relation_map.build(@ifc_entities.build(@step_text.parse(source)))
}

///|
test "indexes entities and direct references in source order" {
  let graph = map_from(
    "#3=IFCWALL('W-3',(#2,#9,#2));#1=IFCWALL('W-1',#2);#2=IFCSPACE('S-2');",
  )
  assert_eq(graph.entities().map(entity => entity.id()), [3, 1, 2])
  assert_eq(graph.entity_by_id(3).map(entity => entity.kind()), Some("IFCWALL"))
  assert_eq(graph.entity_by_id(404), None)
  assert_eq(graph.entities_by_type("ifcwall").map(entity => entity.id()), [3, 1])
  assert_eq(graph.outgoing_references(3), [2, 9])
  assert_eq(graph.incoming_references(2), [3, 1])
  assert_eq(graph.incoming_references(9), [3])
  assert_eq(graph.outgoing_references(404), [])
}

///|
test "aggregate and containment relations identify actual children" {
  let graph = map_from(
    "#1=IFCPROJECT('P');#2=IFCBUILDING('B');#3=IFCBUILDINGSTOREY('L');#4=IFCWALL('W');#5=IFCDOOR('D');#10=IFCRELAGGREGATES('R1',$,$,$,#1,(#2));#11=IFCRELAGGREGATES('R2',$,$,$,#2,(#3));#12=IFCRELCONTAINEDINSPATIALSTRUCTURE('R3',$,$,$,(#4,#5),#3);",
  )
  assert_eq(graph.children_of(1), [2])
  assert_eq(graph.children_of(2), [3])
  assert_eq(graph.children_of(3), [4, 5])
  assert_eq(graph.parent_of(2), Some(1))
  assert_eq(graph.parent_of(4), Some(3))
  assert_eq(graph.parent_of(10), None)
  assert_eq(graph.children_of(10), [])
  assert_eq(graph.outgoing_references(12), [4, 5, 3])
  assert_eq(graph.incoming_references(3), [11, 12])
}

///|
test "ignores unrelated and malformed relationship shapes" {
  let graph = map_from(
    "#1=IFCSPACE('S');#2=IFCWALL('W',#1);#10=IFCRELDEFINESBYPROPERTIES('P',$,$,$,(#2),#1);#11=IFCRELAGGREGATES('A',#1,(#2));#12=IFCRELAGGREGATES('B',$,$,$,#1,#2);",
  )
  assert_eq(graph.children_of(1), [])
  assert_eq(graph.parent_of(2), None)
  assert_eq(graph.incoming_references(1), [2, 10, 11, 12])
}

///|
test "relationship results are stable, unique, and copied" {
  let source = "#1=IFCSPACE('S');#2=IFCWALL('W');#3=IFCDOOR('D');#6=IFCSPACE('S2');#10=IFCRELCONTAINEDINSPATIALSTRUCTURE('R1',$,$,$,(#2,#3,#2),#1);#11=IFCRELCONTAINEDINSPATIALSTRUCTURE('R2',$,$,$,(#3),#6);"
  let graph = map_from(source)
  assert_eq(graph.children_of(1), [2, 3])
  assert_eq(graph.children_of(6), [3])
  assert_eq(graph.parent_of(3), Some(1))
  assert_eq(graph.incoming_references(3), [10, 11])
  let children = graph.children_of(1)
  children.push(99)
  let entities = graph.entities()
  entities.push(entities[0])
  assert_eq(graph.children_of(1), [2, 3])
  assert_eq(graph.entities().length(), 6)
  assert_eq(graph.children_of(1), map_from(source).children_of(1))
}
