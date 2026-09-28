///|
/// Run built-in rules in stable rule order. Findings within each rule follow
/// entity source order, then the rule-specific value order.
/// Parser diagnostics are not merged into this report.
pub fn audit(map : @relation_map.RelationMap) -> AuditReport {
  let entities = map.entities()
  let findings : Array[Finding] = []
  let kinds : Map[String, Bool] = Map([])
  let mut reference_count = 0
  for entity in entities {
    kinds[entity.kind().to_upper()] = true
    let references = entity.references()
    reference_count += references.length()
    for reference in references {
      if map.entity_by_id(reference) is None {
        findings.push({
          code: "REF001",
          severity: Error,
          entity_id: Some(entity.id()),
          entity_type: Some(entity.kind()),
          location: Some(entity.location()),
          target_id: Some(reference),
          message: "reference #" + reference.to_string() + " does not exist",
          suggestion: Some(
            "add the referenced entity or correct the stale reference",
          ),
        })
      }
    }
  }
  check_duplicate_global_ids(entities, findings)
  {
    findings,
    entity_count: entities.length(),
    type_count: kinds.length(),
    reference_count,
  }
}
