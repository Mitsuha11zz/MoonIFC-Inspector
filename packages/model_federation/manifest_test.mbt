///|
test "manifest parses model roles and exact shared GlobalId allowlist" {
  let parsed = @model_federation.parse_manifest(
    "{" +
    "\"models\":[" +
    "{\"name\":\"architecture\",\"path\":\"arch.ifc\",\"discipline\":\"architectural\"}," +
    "{\"name\":\"structure\",\"path\":\"struct.ifc\",\"discipline\":\"structural\"}" +
    "],\"allowed_shared_global_ids\":[\"shared-guid\"]}",
  )
  match parsed {
    Err(message) => fail(message)
    Ok(manifest) => {
      let models = manifest.models()
      assert_eq(models.length(), 2)
      assert_eq(models[0].name(), "architecture")
      assert_eq(models[0].path(), "arch.ifc")
      assert_eq(models[1].discipline(), "structural")
      assert_eq(manifest.allowed_shared_global_ids(), ["shared-guid"])
    }
  }
}

///|
test "manifest rejects too few members and duplicate names or paths" {
  assert_true(
    @model_federation.parse_manifest(
      "{\"models\":[{\"name\":\"a\",\"path\":\"a.ifc\",\"discipline\":\"A\"}]}",
    )
    is Err(_),
  )
  assert_true(
    @model_federation.parse_manifest(
      "{\"models\":[" +
      "{\"name\":\"same\",\"path\":\"a.ifc\",\"discipline\":\"A\"}," +
      "{\"name\":\"same\",\"path\":\"b.ifc\",\"discipline\":\"B\"}]}",
    )
    is Err(_),
  )
  assert_true(
    @model_federation.parse_manifest(
      "{\"models\":[" +
      "{\"name\":\"a\",\"path\":\"same.ifc\",\"discipline\":\"A\"}," +
      "{\"name\":\"b\",\"path\":\"same.ifc\",\"discipline\":\"B\"}]}",
    )
    is Err(_),
  )
}

///|
test "manifest rejects malformed JSON, missing fields, and duplicate allowlist entries" {
  assert_true(@model_federation.parse_manifest("{") is Err(_))
  assert_true(
    @model_federation.parse_manifest("{\"models\":[{},{}]}") is Err(_),
  )
  assert_true(
    @model_federation.parse_manifest(
      "{\"models\":[" +
      "{\"name\":\"a\",\"path\":\"a.ifc\",\"discipline\":\"A\"}," +
      "{\"name\":\"b\",\"path\":\"b.ifc\",\"discipline\":\"B\"}]," +
      "\"allowed_shared_global_ids\":[\"g\",\"g\"]}",
    )
    is Err(_),
  )
}
