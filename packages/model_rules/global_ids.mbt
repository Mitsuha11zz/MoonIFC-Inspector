///|
fn check_duplicate_global_ids(
  entities : Array[@ifc_entities.Entity],
  findings : Array[Finding],
) -> Unit {
  let first_owner : Map[String, Int] = Map([])
  for entity in entities {
    match entity.global_id() {
      Some(global_id) if global_id != "" =>
        match first_owner.get(global_id) {
          Some(owner_id) =>
            findings.push({
              code: "GID001",
              severity: Error,
              entity_id: Some(entity.id()),
              entity_type: Some(entity.kind()),
              location: Some(entity.location()),
              target_id: Some(owner_id),
              message: "GlobalId '" +
              global_id +
              "' is already used by #" +
              owner_id.to_string(),
              suggestion: Some("assign a unique non-empty GlobalId"),
            })
          None => first_owner[global_id] = entity.id()
        }
      _ => ()
    }
  }
}
