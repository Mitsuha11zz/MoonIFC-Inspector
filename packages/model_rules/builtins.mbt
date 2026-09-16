///|
fn has_kind(entities : Array[@ifc_entities.Entity], kind : String) -> Bool {
  entities.any(entity => entity.kind() == kind)
}

///|
pub fn audit(map : @relation_map.RelationMap) -> AuditReport {
  let entities = map.entities()
  let findings : Array[Finding] = []
  let kinds : Array[String] = []
  let reference_count = ref 0
  for entity in entities {
    if not(kinds.contains(entity.kind())) { kinds.push(entity.kind()) }
    reference_count.val += entity.references().length()
    if not(@ifc_entities.is_supported(entity.kind())) {
      findings.push({ code: "IFC001", severity: Warning, entity_id: Some(entity.id()), entity_type: Some(entity.kind()), location: Some(entity), message: "unsupported IFC entity type", suggestion: Some("inspect the entity with a newer rule set") })
    }
    for reference in entity.references() {
      if map.entity_by_id(reference) is None {
        findings.push({ code: "IFC002", severity: Error, entity_id: Some(entity.id()), entity_type: Some(entity.kind()), location: Some(entity), message: "reference #" + reference.to_string() + " does not exist", suggestion: Some("add the referenced entity or remove the stale reference") })
      }
    }
  }
  for entity in entities {
    if (entity.kind() == "IFCWALL" || entity.kind() == "IFCDOOR" || entity.kind() == "IFCWINDOW") && map.incoming_references(entity.id()).length() == 0 {
      findings.push({ code: "IFC003", severity: Warning, entity_id: Some(entity.id()), entity_type: Some(entity.kind()), location: Some(entity), message: "building element has no spatial relationship", suggestion: Some("link the element through IFCRELCONTAINEDINSPATIALSTRUCTURE") })
    }
  }
  if not(has_kind(entities, "IFCPROJECT") || has_kind(entities, "IFCBUILDING")) {
    findings.push({ code: "IFC004", severity: Error, entity_id: None, entity_type: None, location: None, message: "model has no project or building root", suggestion: Some("provide an IFCPROJECT or IFCBUILDING entity") })
  }
  { findings, entity_count: entities.length(), type_count: kinds.length(), reference_count: reference_count.val }
}
