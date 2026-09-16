///|
fn collect_references(value : @step_text.Value, output : Array[Int]) -> Unit {
  match value {
    @step_text.Reference(id) => output.push(id)
    @step_text.Aggregate(items) => for item in items { collect_references(item, output) }
    _ => ()
  }
}

///|
fn first_string(args : Array[@step_text.Value]) -> String? {
  for value in args {
    match value { @step_text.String(text) => return Some(text); _ => () }
  }
  None
}

///|
pub fn from_record(record : @step_text.EntityRecord) -> Entity {
  let args = record.args()
  let references : Array[Int] = []
  for value in args { collect_references(value, references) }
  {
    id: record.id(),
    kind: record.kind(),
    args,
    references,
    global_id: first_string(args),
    location: record.location(),
  }
}
