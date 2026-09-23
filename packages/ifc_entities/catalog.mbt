///|
pub(all) enum EntityClass {
  Project
  Spatial
  Element
  Relationship
  Unsupported
} derive(Eq, Debug)

///|
pub extend EntityClass with Eq::{not_equal, equal}

///|
pub extend EntityClass with Debug::{to_repr}

///|
pub fn classify(kind : String) -> EntityClass {
  match kind.to_upper() {
    "IFCPROJECT" => Project
    "IFCSITE" | "IFCBUILDING" | "IFCBUILDINGSTOREY" | "IFCSPACE" => Spatial
    "IFCWALL" | "IFCDOOR" | "IFCWINDOW" => Element
    "IFCRELAGGREGATES"
    | "IFCRELCONTAINEDINSPATIALSTRUCTURE"
    | "IFCRELDEFINESBYPROPERTIES" => Relationship
    _ => Unsupported
  }
}

///|
pub fn is_supported(kind : String) -> Bool {
  classify(kind) != Unsupported
}

///|
pub fn build(document : @step_text.Document) -> Array[Entity] {
  document.entities().map(record => from_record(record))
}
