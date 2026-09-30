///|
test "SPAT002 accepts a complete project-to-space aggregation chain" {
  let report = audit_source(
    "#1=IFCPROJECT('P');#2=IFCSITE('S');#3=IFCBUILDING('B');#4=IFCBUILDINGSTOREY('L');#5=IFCSPACE('R');#10=IFCRELAGGREGATES('R1',$,$,$,#1,(#2));#11=IFCRELAGGREGATES('R2',$,$,$,#2,(#3));#12=IFCRELAGGREGATES('R3',$,$,$,#3,(#4));#13=IFCRELAGGREGATES('R4',$,$,$,#4,(#5));",
  )
  assert_eq(findings_for(report, "SPAT002").length(), 0)
  assert_eq(findings_for(report, "SPAT003").length(), 0)
}

///|
test "SPAT002 reports absent and wrong-type direct spatial parents" {
  let report = audit_source(
    "#1=IFCPROJECT('P');\n#2=IFCBUILDING('B');\n#3=IFCBUILDINGSTOREY('L');\n#4=IFCSPACE('R');\n#10=IFCRELAGGREGATES('R1',$,$,$,#1,(#3));\n#11=IFCRELAGGREGATES('R2',$,$,$,#2,(#4));",
  )
  let findings = findings_for(report, "SPAT002")
  assert_eq(findings.length(), 3)
  assert_eq(
    findings.map(finding => (finding.entity_id(), finding.target_id())),
    [(Some(2), None), (Some(3), Some(1)), (Some(4), Some(2))],
  )
  assert_eq(findings[0].severity(), @model_rules.Warning)
  assert_eq(findings[1].location().map(loc => loc.line()), Some(3))
  assert_true(findings[2].message().contains("IFCBUILDINGSTOREY"))
}

///|
test "SPAT003 detects distinct parents but deduplicates repeated same-parent relationships" {
  let report = audit_source(
    "#1=IFCPROJECT('P');#2=IFCSITE('S');#3=IFCBUILDING('B');#10=IFCRELAGGREGATES('R1',$,$,$,#1,(#2));#11=IFCRELAGGREGATES('R2',$,$,$,#1,(#2));#12=IFCRELAGGREGATES('R3',$,$,$,#3,(#2));",
  )
  let findings = findings_for(report, "SPAT003")
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].severity(), @model_rules.Error)
  assert_eq(findings[0].entity_id(), Some(2))
  assert_eq(findings[0].target_id(), Some(1))
  assert_true(findings[0].message().contains("#1, #3"))
}

///|
test "dangling spatial parent is reported by REF001 without duplicate SPAT002" {
  let report = audit_source(
    "#1=IFCBUILDINGSTOREY('L');#10=IFCRELAGGREGATES('R1',$,$,$,#99,(#1));",
  )
  assert_eq(findings_for(report, "REF001").length(), 1)
  assert_eq(findings_for(report, "SPAT002").length(), 0)
}

///|
test "spatial hierarchy findings follow built-in rule and source order" {
  let source = "#1=IFCBUILDING('B');#2=IFCSITE('S');#3=IFCSPACE('R');"
  let report = audit_source(source)
  assert_eq(report, audit_source(source))
  assert_eq(
    report.findings().map(finding => (finding.code(), finding.entity_id())),
    [("SPAT002", Some(1)), ("SPAT002", Some(2)), ("SPAT002", Some(3))],
  )
}
