///|
pub fn is_supported(kind : String) -> Bool {
  match kind {
    "IFCPROJECT" | "IFCSITE" | "IFCBUILDING" | "IFCBUILDINGSTOREY" | "IFCSPACE" | "IFCWALL" | "IFCDOOR" | "IFCWINDOW" | "IFCRELAGGREGATES" | "IFCRELCONTAINEDINSPATIALSTRUCTURE" | "IFCRELDEFINESBYPROPERTIES" => true
    _ => false
  }
}

///|
pub fn build(document : @step_text.Document) -> Array[Entity] {
  document.entities().map(record => from_record(record))
}
