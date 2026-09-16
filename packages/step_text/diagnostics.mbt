///|
pub struct SourceLoc {
  line : Int
  column : Int
  offset : Int
} derive(Eq, Debug)

///|
pub(all) enum ParseErrorKind {
  InvalidSection
  InvalidEntity
  InvalidValue
  UnterminatedString
  UnterminatedAggregate
  DuplicateEntityId
} derive(Eq, Debug)

///|
pub struct ParseError {
  kind : ParseErrorKind
  message : String
  location : SourceLoc
} derive(Eq, Debug)

///|
pub fn ParseError::kind(self : ParseError) -> ParseErrorKind {
  self.kind
}

///|
pub fn ParseError::message(self : ParseError) -> String {
  self.message
}

///|
pub fn ParseError::location(self : ParseError) -> SourceLoc {
  self.location
}

///|
pub fn SourceLoc::line(self : SourceLoc) -> Int {
  self.line
}

///|
pub fn SourceLoc::column(self : SourceLoc) -> Int {
  self.column
}

///|
pub fn SourceLoc::offset(self : SourceLoc) -> Int {
  self.offset
}

///|
pub fn SourceLoc::to_string(self : SourceLoc) -> String {
  "line " + self.line.to_string() + ":" + self.column.to_string()
}
