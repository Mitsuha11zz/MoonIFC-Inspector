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
