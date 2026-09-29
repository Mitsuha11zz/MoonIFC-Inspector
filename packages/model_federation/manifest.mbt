///|
/// One discipline model described by a federation manifest.
pub struct FederationMember {
  name : String
  path : String
  discipline : String
} derive(Debug)

///|
pub extend FederationMember with Debug::{to_repr}

///|
pub fn FederationMember::name(self : FederationMember) -> String {
  self.name
}

///|
pub fn FederationMember::path(self : FederationMember) -> String {
  self.path
}

///|
pub fn FederationMember::discipline(self : FederationMember) -> String {
  self.discipline
}

///|
/// A manifest groups discipline models and exact GlobalIds permitted to be shared.
pub struct FederationManifest {
  models : Array[FederationMember]
  allowed_shared_global_ids : Array[String]
} derive(Debug)

///|
pub extend FederationManifest with Debug::{to_repr}

///|
pub fn FederationManifest::models(
  self : FederationManifest,
) -> Array[FederationMember] {
  self.models.copy()
}

///|
pub fn FederationManifest::allowed_shared_global_ids(
  self : FederationManifest,
) -> Array[String] {
  self.allowed_shared_global_ids.copy()
}

///|
fn required_string(
  value : Json,
  key : String,
  context : String,
) -> Result[String, String] {
  match value {
    Object(fields) =>
      match fields.get(key) {
        Some(String(text)) if text.trim() != "" => Ok(text.trim().to_owned())
        Some(String(_)) => Err(context + "." + key + " must not be blank")
        Some(_) => Err(context + "." + key + " must be a string")
        None => Err(context + "." + key + " is required")
      }
    _ => Err(context + " must be an object")
  }
}

///|
fn parse_member(value : Json, index : Int) -> Result[FederationMember, String] {
  let context = "models[" + index.to_string() + "]"
  match required_string(value, "name", context) {
    Err(message) => Err(message)
    Ok(name) =>
      match required_string(value, "path", context) {
        Err(message) => Err(message)
        Ok(path) =>
          match required_string(value, "discipline", context) {
            Err(message) => Err(message)
            Ok(discipline) => Ok({ name, path, discipline, })
          }
      }
  }
}

///|
/// Parse and validate a JSON federation manifest.
///
/// Each model needs a unique name and path plus a non-empty discipline label.
/// Shared GlobalIds are exact, case-sensitive allowlist entries.
pub fn parse_manifest(source : String) -> Result[FederationManifest, String] {
  let decoded : Result[Json, String] = Ok(@json.parse(source)) catch {
    _ => Err("manifest is not valid JSON")
  }
  let fields = match decoded {
    Err(message) => return Err(message)
    Ok(Object(fields)) => fields
    Ok(_) => return Err("manifest root must be a JSON object")
  }
  let entries = match fields.get("models") {
    Some(Array(entries)) => entries
    Some(_) => return Err("models must be an array")
    None => return Err("models is required")
  }
  if entries.length() < 2 {
    return Err("models must contain at least two IFC inputs")
  }
  let models : Array[FederationMember] = []
  let names : Map[String, Bool] = Map([])
  let paths : Map[String, Bool] = Map([])
  for index, entry in entries {
    match parse_member(entry, index) {
      Err(message) => return Err(message)
      Ok(model_entry) => {
        if names.contains(model_entry.name) {
          return Err("duplicate model name: " + model_entry.name)
        }
        if paths.contains(model_entry.path) {
          return Err("duplicate model path: " + model_entry.path)
        }
        names[model_entry.name] = true
        paths[model_entry.path] = true
        models.push(model_entry)
      }
    }
  }
  let allowed_shared_global_ids : Array[String] = []
  let allowed_seen : Map[String, Bool] = Map([])
  match fields.get("allowed_shared_global_ids") {
    None => ()
    Some(Array(values)) =>
      for index, value in values {
        match value {
          String(global_id) if global_id.trim() != "" => {
            let normalized = global_id.trim().to_owned()
            if allowed_seen.contains(normalized) {
              return Err(
                "duplicate allowed_shared_global_ids entry: " + normalized,
              )
            }
            allowed_seen[normalized] = true
            allowed_shared_global_ids.push(normalized)
          }
          String(_) =>
            return Err(
              "allowed_shared_global_ids[" +
              index.to_string() +
              "] must not be blank",
            )
          _ =>
            return Err(
              "allowed_shared_global_ids[" +
              index.to_string() +
              "] must be a string",
            )
        }
      }
    Some(_) => return Err("allowed_shared_global_ids must be an array")
  }
  Ok({ models, allowed_shared_global_ids, })
}
