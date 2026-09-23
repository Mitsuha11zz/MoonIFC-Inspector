///|
test "parses sections, entities, and source locations" {
  let source = "ISO-10303-21;\nHEADER;\nFILE_DESCRIPTION(('ViewDefinition [CoordinationView]'),'2;1');\nENDSEC;\nDATA;\n#42 = IFCWALL(\n  'North wall',\n  12,\n  3.5,\n  .T.,\n  .USERDEFINED.,\n  #7,\n  (1, #8, (2, 3))\n);\nENDSEC;\nEND-ISO-10303-21;"
  let document = @step_text.parse(source)
  assert_true(document.header_present())
  assert_true(document.data_present())
  assert_eq(document.errors().length(), 0)
  assert_eq(document.entities().length(), 1)
  let entity = document.entities()[0]
  assert_eq(entity.id(), 42)
  assert_eq(entity.kind(), "IFCWALL")
  assert_eq(entity.location().line(), 6)
  assert_eq(entity.location().column(), 1)
  assert_eq(entity.location().offset(), 99)
}

///|
test "parses scalar values and escaped strings" {
  let document = @step_text.parse(
    "#1=IFCVALUES('O''Brien',-7,2.25,.F.,.ENUM.,$,*);",
  )
  let values = document.entities()[0].args()
  assert_true(values[0] is String("O'Brien"))
  assert_true(values[1] is Integer(-7L))
  assert_true(values[2] is Real(2.25))
  assert_true(values[3] is Boolean(false))
  assert_true(values[4] is Enum(".ENUM."))
  assert_true(values[5] is Omitted)
  assert_true(values[6] is Derived)
}

///|
test "parses references and nested aggregates" {
  let document = @step_text.parse("#2=IFCREL(#1,(#3,(#4,#5)));#1=IFCPROJECT();")
  let values = document.entities()[0].args()
  assert_true(values[0] is Reference(1))
  match values[1] {
    Aggregate(items) => {
      assert_eq(items.length(), 2)
      assert_true(items[0] is Reference(3))
      match items[1] {
        Aggregate(inner) => assert_true(inner[1] is Reference(5))
        _ => fail("expected nested aggregate")
      }
    }
    _ => fail("expected aggregate")
  }
}

///|
test "collects duplicate and malformed entity errors in order" {
  let source = "#1=IFCPROJECT();\n#1=IFCSITE();\n#bad=IFCWALL();\n#3=IFCWALL(1;\n#4=IFCDOOR('unterminated);"
  let document = @step_text.parse(source)
  assert_eq(document.entities().length(), 1)
  let errors = document.errors()
  assert_eq(errors.length(), 4)
  assert_eq(errors[0].kind(), DuplicateEntityId)
  assert_eq(errors[0].location().line(), 2)
  assert_eq(errors[1].kind(), InvalidEntity)
  assert_eq(errors[1].location().line(), 3)
  assert_eq(errors[2].kind(), UnterminatedAggregate)
  assert_eq(errors[2].location().line(), 4)
  assert_eq(errors[3].kind(), UnterminatedString)
  assert_eq(errors[3].location().line(), 5)
}

///|
test "reports missing delimiters and aggregate closure" {
  let missing_equal = @step_text.parse("#1 IFCWALL();")
  assert_eq(missing_equal.errors().length(), 1)
  assert_eq(missing_equal.errors()[0].kind(), InvalidEntity)

  let missing_paren = @step_text.parse("#2=IFCWALL(1;")
  assert_eq(missing_paren.errors().length(), 1)
  assert_eq(missing_paren.errors()[0].kind(), UnterminatedAggregate)

  let outside_endsec = @step_text.parse("ENDSEC;")
  assert_eq(outside_endsec.errors().length(), 1)
  assert_eq(outside_endsec.errors()[0].kind(), InvalidSection)
}

///|
test "reports an unterminated statement and handles empty input" {
  assert_eq(@step_text.parse("").entities().length(), 0)
  assert_eq(@step_text.parse("").errors().length(), 0)
  let document = @step_text.parse("#9=IFCWALL()")
  assert_eq(document.entities().length(), 0)
  assert_eq(document.errors().length(), 1)
  assert_eq(document.errors()[0].kind(), InvalidEntity)
  assert_eq(document.errors()[0].location().line(), 1)
  assert_eq(document.errors()[0].location().column(), 1)
}

///|
test "keeps entity and error order stable across repeated parses" {
  let source = "#3=IFCWALL(#8);#1=IFCPROJECT();#3=IFCSITE();#2=IFCSPACE();"
  let first = @step_text.parse(source)
  let second = @step_text.parse(source)
  assert_eq(first, second)
  assert_eq(first.entities()[0].id(), 3)
  assert_eq(first.entities()[1].id(), 1)
  assert_eq(first.entities()[2].id(), 2)
  assert_eq(first.errors()[0].kind(), DuplicateEntityId)
}
