///|
test "GID001 reports later duplicate against its first owner" {
  let report = audit_source("#1=IFCPROJECT('SAME-ID');\n#2=IFCWALL('SAME-ID');")
  let findings = report.findings()
  assert_eq(findings.length(), 1)
  let finding = findings[0]
  assert_eq(finding.code(), "GID001")
  assert_eq(finding.severity(), @model_rules.Error)
  assert_eq(finding.entity_id(), Some(2))
  assert_eq(finding.entity_type(), Some("IFCWALL"))
  assert_eq(finding.target_id(), Some(1))
  assert_eq(finding.location().map(loc => loc.line()), Some(2))
  assert_eq(finding.message(), "GlobalId 'SAME-ID' is already used by #1")
  assert_eq(finding.suggestion(), Some("assign a unique non-empty GlobalId"))
}

///|
test "GID001 keeps first owner and duplicate source order" {
  let report = audit_source(
    "#7=IFCSPACE('DUP');#3=IFCDOOR('DUP');#9=IFCWINDOW('UNIQUE');#2=IFCWALL('DUP');",
  )
  assert_eq(
    report
    .findings()
    .map(finding => (finding.code(), finding.entity_id(), finding.target_id())),
    [("GID001", Some(3), Some(7)), ("GID001", Some(2), Some(7))],
  )
}

///|
test "missing, empty, unsupported, and case-distinct GlobalIds are ignored" {
  let report = audit_source(
    "#1=IFCWALL($);#2=IFCDOOR($);#3=IFCWINDOW('');#4=IFCSPACE('');#5=IFCUNKNOWN('X');#6=IFCUNKNOWN('X');#7=IFCWALL('Case');#8=IFCDOOR('case');",
  )
  assert_eq(report.findings().length(), 0)
}

///|
test "built-in audit uses stable REF001 then GID001 rule order" {
  let source = "#1=IFCWALL('DUP',#404);#2=IFCDOOR('DUP',#405);"
  let report = audit_source(source)
  assert_eq(report, audit_source(source))
  assert_eq(
    report
    .findings()
    .map(finding => (finding.code(), finding.entity_id(), finding.target_id())),
    [
      ("REF001", Some(1), Some(404)),
      ("REF001", Some(2), Some(405)),
      ("GID001", Some(2), Some(1)),
    ],
  )
}
