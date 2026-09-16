///|
pub fn Severity::to_string(self : Severity) -> String {
  match self { Error => "error"; Warning => "warning"; Info => "info" }
}
