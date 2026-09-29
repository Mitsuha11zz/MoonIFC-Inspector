///|
#cfg(target="js")
test "Node runtime and script prefixes are excluded from user arguments" {
  assert_eq(
    user_args(["node", "inspector.js", "--spatial-tree", "building.ifc"]),
    ["--spatial-tree", "building.ifc"],
  )
  assert_eq(user_args(["node", "inspector.js"]), [])
  assert_eq(user_args(["node"]), [])
  assert_eq(user_args([]), [])
}

///|
#cfg(not(target="js"))
test "host executable prefix is excluded from user arguments" {
  assert_eq(user_args(["inspector", "--spatial-tree", "building.ifc"]), [
    "--spatial-tree", "building.ifc",
  ])
  assert_eq(user_args(["inspector"]), [])
  assert_eq(user_args([]), [])
}

///|
test "spatial tree option is distinct from the existing reference list" {
  assert_true(parse_view("--spatial-tree") is Some(SpatialTree))
  assert_true(parse_view("--tree") is Some(Tree))
  assert_true(parse_view("building.ifc") is None)
}

///|
test "federation arguments accept multiple model files and JSON output" {
  let args = parse_arguments([
    "--federation", "--json", "architecture.ifc", "structure.ifc",
  ])
  assert_true(args.federation)
  assert_true(args.view is Json)
  assert_eq(args.paths, ["architecture.ifc", "structure.ifc"])
  assert_false(args.help)
}

///|
test "federation mode can be combined with options in either order" {
  let args = parse_arguments([
    "architecture.ifc", "--federation", "structure.ifc",
  ])
  assert_true(args.federation)
  assert_eq(args.paths, ["architecture.ifc", "structure.ifc"])
}

///|
test "federation mode distinguishes report views from tree views" {
  let json = parse_arguments(["--federation", "--json", "a.ifc", "b.ifc"])
  let tree = parse_arguments([
    "--federation", "--spatial-tree", "a.ifc", "b.ifc",
  ])
  assert_true(json.view is Json)
  assert_true(tree.view is SpatialTree)
}

///|
test "federation mode deduplicates repeated path arguments in first-seen order" {
  assert_eq(unique_paths(["a.ifc", "b.ifc", "a.ifc"]), ["a.ifc", "b.ifc"])
}
