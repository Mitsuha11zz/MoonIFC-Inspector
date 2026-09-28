///|
fn audit_source(source : String) -> @model_rules.AuditReport {
  @model_rules.audit(
    @relation_map.build(@ifc_entities.build(@step_text.parse(source))),
  )
}

///|
test "REF001 identifies the source entity, missing target, and entity location" {
  let report = audit_source("\n  #4=IFCWALL('W',#404);")
  let findings = report.findings()
  assert_eq(findings.length(), 1)
  let finding = findings[0]
  assert_eq(finding.code(), "REF001")
  assert_eq(finding.severity(), @model_rules.Error)
  assert_eq(finding.entity_id(), Some(4))
  assert_eq(finding.entity_type(), Some("IFCWALL"))
  assert_eq(finding.target_id(), Some(404))
  assert_eq(finding.location().map(loc => loc.line()), Some(2))
  assert_eq(finding.location().map(loc => loc.column()), Some(3))
  assert_eq(finding.location().map(loc => loc.offset()), Some(3))
  assert_eq(finding.message(), "reference #404 does not exist")
  assert_true(finding.suggestion() is Some(_))
  assert_eq(report.entity_count(), 1)
  assert_eq(report.type_count(), 1)
  assert_eq(report.reference_count(), 1)
}

///|
test "valid forward, cyclic, and self references do not produce findings" {
  let report = audit_source("#1=IFCWALL(#2,#1);#2=IFCUNKNOWN(#1);")
  assert_eq(report.findings().length(), 0)
  assert_eq(report.entity_count(), 2)
  assert_eq(report.type_count(), 2)
  assert_eq(report.reference_count(), 3)
}

///|
test "nested missing references are unique per entity and ordered stably" {
  let source = "#9=IFCWALL((#404,(#405,#404)),#2);#2=IFCDOOR();#1=IFCWALL(#405,#406);"
  let report = audit_source(source)
  assert_eq(report, audit_source(source))
  assert_eq(
    report.findings().map(finding => (finding.entity_id(), finding.target_id())),
    [
      (Some(9), Some(404)),
      (Some(9), Some(405)),
      (Some(1), Some(405)),
      (Some(1), Some(406)),
    ],
  )
  assert_eq(report.entity_count(), 3)
  assert_eq(report.type_count(), 2)
  assert_eq(report.reference_count(), 5)
}

///|
test "empty or reference free models do not trigger unrelated rules" {
  let empty = audit_source("")
  assert_eq(empty.findings().length(), 0)
  assert_eq(empty.entity_count(), 0)
  assert_eq(empty.type_count(), 0)
  assert_eq(empty.reference_count(), 0)
  let report = audit_source("#1=IFCUNKNOWN();#2=IFCWALL('W');")
  assert_eq(report.findings().length(), 0)
  assert_eq(report.reference_count(), 0)
  assert_eq(@model_rules.Error.to_string(), "error")
  assert_eq(@model_rules.Warning.to_string(), "warning")
  assert_eq(@model_rules.Info.to_string(), "info")
}

///|
test "findings are copied and unknown entities retain reference auditing" {
  let report = audit_source("#8=IFCUNKNOWN(#99);#9=IFCWALL(#99);")
  let findings = report.findings()
  findings.clear()
  assert_eq(report.findings().length(), 2)
  assert_eq(report.findings()[0].entity_type(), Some("IFCUNKNOWN"))
  assert_eq(report.findings()[1].target_id(), Some(99))
}
