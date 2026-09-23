///|
fn collect_references(
  value : @step_text.Value,
  output : Array[Int],
  seen : Map[Int, Bool],
) -> Unit {
  match value {
    @step_text.Reference(id) =>
      if !seen.contains(id) {
        seen[id] = true
        output.push(id)
      }
    @step_text.Aggregate(items) =>
      for item in items {
        collect_references(item, output, seen)
      }
    _ => ()
  }
}

///|
fn global_id_from_first_attribute(
  kind : String,
  args : Array[@step_text.Value],
) -> String? {
  if !is_supported(kind) || args.length() == 0 {
    return None
  }
  match args[0] {
    @step_text.String(text) => Some(text)
    _ => None
  }
}

///|
pub fn from_record(record : @step_text.EntityRecord) -> Entity {
  let args = record.args()
  let references : Array[Int] = []
  let seen : Map[Int, Bool] = Map([])
  for value in args {
    collect_references(value, references, seen)
  }
  {
    id: record.id(),
    kind: record.kind(),
    args,
    references,
    global_id: global_id_from_first_attribute(record.kind(), args),
    location: record.location(),
  }
}
