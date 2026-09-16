///|
fn sample() -> String {
  "ISO-10303-21;\nHEADER;\nENDSEC;\nDATA;\n#1=IFCPROJECT('P',());\n#2=IFCWALL('W',#99);\nENDSEC;\nEND-ISO-10303-21;"
}

///|
fn main {
  let document = @step_text.parse(sample())
  let map = @relation_map.build(@ifc_entities.build(document))
  let report = @model_rules.audit(map)
  println(@report_view.text(report))
}
