///|
fn spatial_tree_of(source : String) -> String {
  @report_view.spatial_tree(
    @relation_map.build(@ifc_entities.build(@step_text.parse(source))),
  )
}

///|
test "spatial tree renders aggregation and containment in relationship order" {
  let source =
    #|#4=IFCWALL('W');#3=IFCBUILDINGSTOREY('L');#2=IFCBUILDING('B');#1=IFCPROJECT('P');#5=IFCDOOR('D');
    #|#10=IFCRELAGGREGATES('R1',$,$,$,#1,(#2));
    #|#11=IFCRELAGGREGATES('R2',$,$,$,#2,(#3));
    #|#12=IFCRELCONTAINEDINSPATIALSTRUCTURE('R3',$,$,$,(#5,#4,#5),#3);
  assert_eq(
    spatial_tree_of(source),
    "#1 IFCPROJECT\n  #2 IFCBUILDING\n    #3 IFCBUILDINGSTOREY\n      #5 IFCDOOR\n      #4 IFCWALL",
  )
}

///|
test "spatial tree does not infer hierarchy from ordinary references" {
  assert_eq(
    spatial_tree_of("#3=IFCWALL('W',#1);#1=IFCPROJECT('P');#8=IFCUNKNOWN();"),
    "#3 IFCWALL\n#1 IFCPROJECT",
  )
  assert_eq(spatial_tree_of(""), "")
  assert_eq(spatial_tree_of("#8=IFCUNKNOWN();"), "")
}

///|
test "spatial tree exposes missing children and missing parents" {
  assert_eq(
    spatial_tree_of(
      "#1=IFCPROJECT('P');#2=IFCWALL('W');#10=IFCRELAGGREGATES('A',$,$,$,#1,(#99));#11=IFCRELCONTAINEDINSPATIALSTRUCTURE('B',$,$,$,(#2),#98);",
    ),
    "#1 IFCPROJECT\n  #99 [missing]\n#2 IFCWALL [missing parent #98]",
  )
}

///|
test "spatial tree marks shared children instead of repeating their subtree" {
  assert_eq(
    spatial_tree_of(
      "#1=IFCSPACE('S1');#2=IFCSPACE('S2');#3=IFCWALL('W');#10=IFCRELCONTAINEDINSPATIALSTRUCTURE('A',$,$,$,(#3),#1);#11=IFCRELCONTAINEDINSPATIALSTRUCTURE('B',$,$,$,(#3),#2);",
    ),
    "#1 IFCSPACE\n  #3 IFCWALL\n#2 IFCSPACE\n  #3 IFCWALL [already shown]",
  )
}

///|
test "spatial tree terminates on cycles including components without roots" {
  let source = "#1=IFCBUILDING('B');#2=IFCBUILDINGSTOREY('L');#10=IFCRELAGGREGATES('A',$,$,$,#1,(#2));#11=IFCRELAGGREGATES('B',$,$,$,#2,(#1));"
  let first = spatial_tree_of(source)
  assert_eq(
    first, "#1 IFCBUILDING [unrooted]\n  #2 IFCBUILDINGSTOREY\n    #1 IFCBUILDING [cycle]",
  )
  assert_eq(spatial_tree_of(source), first)
  assert_eq(
    spatial_tree_of("#1=IFCSPACE('S');#10=IFCRELAGGREGATES('A',$,$,$,#1,(#1));"),
    "#1 IFCSPACE [unrooted]\n  #1 IFCSPACE [cycle]",
  )
}

///|
test "spatial tree preserves unsupported descendants and parent context" {
  assert_eq(
    spatial_tree_of("#3=IFCWALL('W');#10=IFCRELAGGREGATES('A',$,$,$,#10,(#3));"),
    "#3 IFCWALL [parent outside tree #10]",
  )
  assert_eq(
    spatial_tree_of(
      "#1=IFCPROJECT('P');#2=IFCUNKNOWN();#3=IFCWALL('W');#10=IFCRELAGGREGATES('A',$,$,$,#1,(#2));#11=IFCRELAGGREGATES('B',$,$,$,#2,(#3));",
    ),
    "#1 IFCPROJECT\n  #2 IFCUNKNOWN\n    #3 IFCWALL",
  )
  assert_eq(
    spatial_tree_of(
      "#2=IFCUNKNOWN();#3=IFCWALL('W');#10=IFCRELAGGREGATES('A',$,$,$,#2,(#3));",
    ),
    "#2 IFCUNKNOWN\n  #3 IFCWALL",
  )
  assert_eq(
    spatial_tree_of(
      "#3=IFCWALL('W');#2=IFCUNKNOWN();#10=IFCRELAGGREGATES('A',$,$,$,#2,(#3));",
    ),
    "#2 IFCUNKNOWN\n  #3 IFCWALL",
  )
}

///|
test "spatial tree handles a deep hierarchy and leaves relation indexes unchanged" {
  let source = StringBuilder()
  for id in 1..<=256 {
    source.write_string("#\{id}=IFCSPACE('S\{id}');\n")
    if id > 1 {
      source.write_string(
        "#\{1000 + id}=IFCRELAGGREGATES('R\{id}',$,$,$,#\{id - 1},(#\{id}));\n",
      )
    }
  }
  let map = @relation_map.build(
    @ifc_entities.build(@step_text.parse(source.to_string())),
  )
  let tree = @report_view.spatial_tree(map)
  let lines = tree.split("\n").to_array()
  assert_eq(lines.length(), 256)
  assert_eq(lines[255], "  ".repeat(255) + "#256 IFCSPACE")
  assert_eq(map.children_of(1), [2])
  assert_eq(map.parent_of(256), Some(255))
  assert_eq(@report_view.spatial_tree(map), tree)
}
