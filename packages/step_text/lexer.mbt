///|
pub(all) enum Value {
  Integer(Int64)
  Real(Double)
  String(String)
  Boolean(Bool)
  Enum(String)
  Reference(Int)
  Aggregate(Array[Value])
  Omitted
  Derived
} derive(Eq, Debug)

///|
pub struct EntityRecord {
  id : Int
  kind : String
  args : Array[Value]
  location : SourceLoc
} derive(Eq, Debug)

///|
pub struct Document {
  entities : Array[EntityRecord]
  header_present : Bool
  data_present : Bool
  errors : Array[ParseError]
} derive(Eq, Debug)

///|
pub fn EntityRecord::id(self : EntityRecord) -> Int {
  self.id
}

///|
pub fn EntityRecord::kind(self : EntityRecord) -> String {
  self.kind
}

///|
pub fn EntityRecord::args(self : EntityRecord) -> Array[Value] {
  self.args.copy()
}

///|
pub fn EntityRecord::location(self : EntityRecord) -> SourceLoc {
  self.location
}

///|
pub fn Document::entities(self : Document) -> Array[EntityRecord] {
  self.entities.copy()
}

///|
pub fn Document::errors(self : Document) -> Array[ParseError] {
  self.errors.copy()
}

///|
pub fn Document::header_present(self : Document) -> Bool {
  self.header_present
}

///|
pub fn Document::data_present(self : Document) -> Bool {
  self.data_present
}
