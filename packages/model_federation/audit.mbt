///|
priv struct FirstOwner {
  model_index : Int
  model_name : String
  entity_id : Int
  entity_type : String
  location : @step_text.SourceLoc
}

///|
/// Find element GlobalIds reused across separate IFC model inputs.
///
/// The first occurrence in input order is the stable owner reported for each
/// later model. Only supported element entities are compared; project,
/// spatial-structure, and relationship identifiers are not federation
/// candidates. Repeated IDs within one file are left to the per-file GID001
/// audit rule. Empty and absent GlobalIds are ignored.
pub fn audit(models : Array[ModelSource]) -> FederationReport {
  let model_names : Array[String] = []
  let first_owner : Map[String, FirstOwner] = Map([])
  let collisions : Array[GlobalIdCollision] = []
  let mut entity_count = 0
  for model_index, model in models {
    model_names.push(model.name)
    let seen_in_model : Map[String, Bool] = Map([])
    for entity in model.entities {
      entity_count += 1
      if entity.category() == @ifc_entities.Element {
        match entity.global_id() {
          Some(global_id) if global_id != "" &&
            !seen_in_model.contains(global_id) => {
            seen_in_model[global_id] = true
            match first_owner.get(global_id) {
              Some(owner) if owner.model_index != model_index =>
                collisions.push({
                  global_id,
                  first_model: owner.model_name,
                  first_entity_id: owner.entity_id,
                  first_entity_type: owner.entity_type,
                  first_location: owner.location,
                  duplicate_model: model.name,
                  duplicate_entity_id: entity.id(),
                  duplicate_entity_type: entity.kind(),
                  duplicate_location: entity.location(),
                })
              Some(_) => ()
              None =>
                first_owner[global_id] = {
                  model_index,
                  model_name: model.name,
                  entity_id: entity.id(),
                  entity_type: entity.kind(),
                  location: entity.location(),
                }
            }
          }
          _ => ()
        }
      }
    }
  }
  { models: model_names, entity_count, collisions, }
}
