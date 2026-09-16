///|
fn main {
  let source = "DATA;\n#1=IFCPROJECT('P');\n#2=IFCWALL('W',#1);\nENDSEC;"
  let document = @step_text.parse(source)
  let report = @model_rules.audit(@relation_map.build(@ifc_entities.build(document)))
  println(@report_view.json(report))
}
