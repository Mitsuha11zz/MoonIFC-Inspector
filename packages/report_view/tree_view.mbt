///|
pub fn tree(map : @relation_map.RelationMap) -> String {
  let lines : Array[String] = []
  for entity in map.entities() {
    lines.push("#" + entity.id().to_string() + " " + entity.kind() + " -> " + entity.references().map(id => "#" + id.to_string()).join(", "))
  }
  lines.join("\n")
}
