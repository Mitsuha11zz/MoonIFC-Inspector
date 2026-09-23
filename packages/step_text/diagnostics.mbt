///|
pub struct SourceLoc {
  line : Int
  column : Int
  offset : Int
} derive(Eq, Debug)

///|
pub extend SourceLoc with Eq::{not_equal, equal}

///|
pub extend SourceLoc with Debug::{to_repr}

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
pub extend ParseErrorKind with Eq::{not_equal, equal}

///|
pub extend ParseErrorKind with Debug::{to_repr}

///|
pub struct ParseError {
  kind : ParseErrorKind
  message : String
  location : SourceLoc
} derive(Eq, Debug)

///|
pub extend ParseError with Eq::{not_equal, equal}

///|
pub extend ParseError with Debug::{to_repr}

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
