///|
priv enum Section {
  Outside
  Header
  Data
}

///|
priv enum StatementResult {
  Ignore
  EnterHeader
  EnterData
  LeaveSection
  Entity(EntityRecord)
  Problem(ParseError)
}

///|
fn location_after(
  base : SourceLoc,
  chars : Array[Char],
  end : Int,
) -> SourceLoc {
  let mut line = base.line()
  let mut column = base.column()
  for index in 0..<end {
    if chars[index] == '\n' {
      line += 1
      column = 1
    } else {
      column += 1
    }
  }
  { line, column, offset: base.offset() + end, }
}

///|
fn error(
  kind : ParseErrorKind,
  message : String,
  location : SourceLoc,
) -> ParseError {
  { kind, message, location, }
}

///|
fn is_space(ch : Char) -> Bool {
  ch.is_whitespace()
}

///|
fn skip_space(chars : Array[Char], start : Int) -> Int {
  let mut index = start
  while index < chars.length() && is_space(chars[index]) {
    index += 1
  }
  index
}

///|
fn digit_value(ch : Char) -> Int? {
  if ch.is_ascii_digit() {
    Some(ch.to_int() - '0'.to_int())
  } else {
    None
  }
}

///|
fn read_integer(chars : Array[Char], start : Int) -> (Int64, Int, Bool) {
  let mut index = start
  let mut negative = false
  if index < chars.length() && (chars[index] == '+' || chars[index] == '-') {
    negative = chars[index] == '-'
    index += 1
  }
  let mut value : Int64 = 0L
  let mut digits = 0
  while index < chars.length() {
    match digit_value(chars[index]) {
      Some(digit) => {
        value = value * 10L + digit.to_int64()
        digits += 1
        index += 1
      }
      None => break
    }
  }
  if negative {
    value = -value
  }
  (value, index, digits > 0)
}

///|
fn read_number(chars : Array[Char], start : Int) -> (Value, Int)? {
  let (whole, after_whole, has_whole) = read_integer(chars, start)
  let mut index = after_whole
  let mut real = whole.to_double()
  let mut is_real = false
  if index < chars.length() && chars[index] == '.' {
    is_real = true
    index += 1
    let mut place = 0.1
    let mut fraction_digits = 0
    while index < chars.length() {
      match digit_value(chars[index]) {
        Some(digit) => {
          real += digit.to_double() * place
          place *= 0.1
          fraction_digits += 1
          index += 1
        }
        None => break
      }
    }
    if !has_whole && fraction_digits == 0 {
      return None
    }
  }
  if !has_whole {
    return None
  }
  if index < chars.length() && (chars[index] == 'e' || chars[index] == 'E') {
    is_real = true
    index += 1
    let mut exponent_negative = false
    if index < chars.length() && (chars[index] == '+' || chars[index] == '-') {
      exponent_negative = chars[index] == '-'
      index += 1
    }
    let (raw_exponent, exponent_end, exponent_ok) = read_integer(chars, index)
    if !exponent_ok {
      return None
    }
    let mut exponent = raw_exponent.to_int()
    if exponent_negative {
      exponent = -exponent.abs()
    }
    if exponent >= 0 {
      for _ in 0..<exponent {
        real *= 10.0
      }
    } else {
      for _ in 0..<-exponent {
        real *= 0.1
      }
    }
    index = exponent_end
  }
  if is_real {
    Some((Real(real), index))
  } else {
    Some((Integer(whole), index))
  }
}

///|
fn parse_string(
  chars : Array[Char],
  start : Int,
  base : SourceLoc,
) -> Result[(Value, Int), ParseError] {
  let mut index = start + 1
  let output : Array[Char] = []
  while index < chars.length() {
    let ch = chars[index]
    if ch == '\'' {
      if index + 1 < chars.length() && chars[index + 1] == '\'' {
        output.push('\'')
        index += 2
      } else {
        return Ok((String(String::from_array(output[:])), index + 1))
      }
    } else {
      output.push(ch)
      index += 1
    }
  }
  Err(
    error(
      UnterminatedString,
      "unterminated STEP string",
      location_after(base, chars, start),
    ),
  )
}

///|
fn parse_enum(
  chars : Array[Char],
  start : Int,
  base : SourceLoc,
) -> Result[(Value, Int), ParseError] {
  let mut index = start + 1
  while index < chars.length() && chars[index] != '.' {
    index += 1
  }
  if index >= chars.length() {
    return Err(
      error(
        InvalidValue,
        "unterminated enumeration",
        location_after(base, chars, start),
      ),
    )
  }
  let token = String::from_array(chars[start:index + 1])
  let value = token.to_upper()
  if value == ".T." {
    Ok((Boolean(true), index + 1))
  } else if value == ".F." {
    Ok((Boolean(false), index + 1))
  } else {
    Ok((Enum(value), index + 1))
  }
}

///|
fn parse_value(
  chars : Array[Char],
  start : Int,
  base : SourceLoc,
) -> Result[(Value, Int), ParseError] {
  let index = skip_space(chars, start)
  if index >= chars.length() {
    return Err(
      error(
        InvalidValue,
        "missing STEP value",
        location_after(base, chars, index),
      ),
    )
  }
  match chars[index] {
    '$' => Ok((Omitted, index + 1))
    '*' => Ok((Derived, index + 1))
    '#' => {
      let (number, next, valid) = read_integer(chars, index + 1)
      if valid {
        Ok((Reference(number.to_int()), next))
      } else {
        Err(
          error(
            InvalidValue,
            "invalid entity reference",
            location_after(base, chars, index),
          ),
        )
      }
    }
    '\'' => parse_string(chars, index, base)
    '.' => parse_enum(chars, index, base)
    '(' => {
      let mut cursor = skip_space(chars, index + 1)
      let values : Array[Value] = []
      if cursor < chars.length() && chars[cursor] == ')' {
        return Ok((Aggregate(values), cursor + 1))
      }
      while cursor < chars.length() {
        let (value, next) = match parse_value(chars, cursor, base) {
          Ok(result) => result
          Err(problem) => return Err(problem)
        }
        values.push(value)
        cursor = skip_space(chars, next)
        if cursor < chars.length() && chars[cursor] == ',' {
          cursor = skip_space(chars, cursor + 1)
          continue
        }
        if cursor < chars.length() && chars[cursor] == ')' {
          return Ok((Aggregate(values), cursor + 1))
        }
        return Err(
          error(
            UnterminatedAggregate,
            "aggregate is missing ')'",
            location_after(base, chars, cursor),
          ),
        )
      }
      Err(
        error(
          UnterminatedAggregate,
          "aggregate is missing ')'",
          location_after(base, chars, index),
        ),
      )
    }
    _ =>
      match read_number(chars, index) {
        Some(result) => Ok(result)
        None =>
          Err(
            error(
              InvalidValue,
              "unsupported STEP value",
              location_after(base, chars, index),
            ),
          )
      }
  }
}

///|
fn parse_entity(
  statement : String,
  base : SourceLoc,
) -> Result[EntityRecord, ParseError] {
  let chars = statement.to_array()
  let mut index = skip_space(chars, 0)
  if index >= chars.length() || chars[index] != '#' {
    return Err(error(InvalidEntity, "entity must start with '#'", base))
  }
  let (raw_id, after_id, id_ok) = read_integer(chars, index + 1)
  if !id_ok {
    return Err(
      error(
        InvalidEntity,
        "entity id is missing digits",
        location_after(base, chars, index),
      ),
    )
  }
  let id = raw_id.to_int()
  index = skip_space(chars, after_id)
  if index >= chars.length() || chars[index] != '=' {
    return Err(
      error(
        InvalidEntity,
        "entity is missing '='",
        location_after(base, chars, index),
      ),
    )
  }
  index = skip_space(chars, index + 1)
  let kind_start = index
  while index < chars.length() && chars[index].is_ascii_alphabetic() {
    index += 1
  }
  if kind_start == index {
    return Err(
      error(
        InvalidEntity,
        "entity type is missing",
        location_after(base, chars, index),
      ),
    )
  }
  let kind = String::from_array(chars[kind_start:index]).to_upper()
  index = skip_space(chars, index)
  if index >= chars.length() || chars[index] != '(' {
    return Err(
      error(
        InvalidEntity,
        "entity is missing '('",
        location_after(base, chars, index),
      ),
    )
  }
  index = skip_space(chars, index + 1)
  let args : Array[Value] = []
  let mut closed = false
  if index < chars.length() && chars[index] == ')' {
    index += 1
    closed = true
  } else {
    while index < chars.length() {
      let (value, next) = match parse_value(chars, index, base) {
        Ok(result) => result
        Err(problem) => return Err(problem)
      }
      args.push(value)
      index = skip_space(chars, next)
      if index < chars.length() && chars[index] == ',' {
        index = skip_space(chars, index + 1)
        continue
      }
      if index < chars.length() && chars[index] == ')' {
        index += 1
        closed = true
        break
      }
      if index >= chars.length() {
        return Err(
          error(
            UnterminatedAggregate,
            "entity argument list is missing ')'",
            location_after(base, chars, index),
          ),
        )
      }
      return Err(
        error(
          InvalidEntity,
          "entity is missing ')'",
          location_after(base, chars, index),
        ),
      )
    }
  }
  if !closed {
    return Err(
      error(
        UnterminatedAggregate,
        "entity argument list is missing ')'",
        location_after(base, chars, index),
      ),
    )
  }
  index = skip_space(chars, index)
  if index != chars.length() {
    return Err(
      error(
        InvalidEntity,
        "unexpected text after entity",
        location_after(base, chars, index),
      ),
    )
  }
  Ok({ id, kind, args, location: base, })
}

///|
fn classify_statement(statement : String, base : SourceLoc) -> StatementResult {
  let trimmed = statement.trim().to_owned()
  if trimmed.is_empty() {
    return Ignore
  }
  let upper = trimmed.to_upper()
  if upper == "HEADER;" {
    return EnterHeader
  }
  if upper == "DATA;" {
    return EnterData
  }
  if upper == "ENDSEC;" {
    return LeaveSection
  }
  if upper == "ISO-10303-21;" || upper == "END-ISO-10303-21;" {
    return Ignore
  }
  if trimmed.has_prefix("#") {
    let without_semicolon = if trimmed.has_suffix(";") {
      trimmed.sub(end=trimmed.length() - 1).to_owned()
    } else {
      trimmed
    }
    match parse_entity(without_semicolon, base) {
      Ok(entity) => Entity(entity)
      Err(problem) => Problem(problem)
    }
  } else {
    Ignore
  }
}

///|
pub fn parse(source : String) -> Document {
  let entities : Array[EntityRecord] = []
  let errors : Array[ParseError] = []
  let mut section = Outside
  let mut header_present = false
  let mut data_present = false
  let seen : Array[Int] = []
  let chars = source.to_array()
  let mut statement : Array[Char] = []
  let mut statement_location = { line: 1, column: 1, offset: 0, }
  let mut line = 1
  let mut column = 1
  let mut offset = 0
  let mut in_string = false
  for ch in chars {
    if statement.length() == 0 && is_space(ch) {
      if ch == '\n' {
        line += 1
        column = 1
      } else {
        column += 1
      }
      offset += 1
    } else {
      if statement.length() == 0 {
        statement_location = { line, column, offset, }
      }
      statement.push(ch)
      if ch == '\'' {
        in_string = !in_string
      }
      if ch == ';' && !in_string {
        match
          classify_statement(
            String::from_array(statement[:]),
            statement_location,
          ) {
          EnterHeader => {
            section = Header
            header_present = true
          }
          EnterData => {
            section = Data
            data_present = true
          }
          LeaveSection =>
            match section {
              Outside =>
                errors.push(
                  error(
                    InvalidSection,
                    "ENDSEC is outside a section",
                    statement_location,
                  ),
                )
              Header | Data => section = Outside
            }
          Entity(entity) =>
            if seen.contains(entity.id()) {
              errors.push(
                error(
                  DuplicateEntityId,
                  "duplicate entity id",
                  entity.location(),
                ),
              )
            } else {
              seen.push(entity.id())
              entities.push(entity)
            }
          Problem(problem) => errors.push(problem)
          Ignore => ()
        }
        statement = []
        in_string = false
      }
      if ch == '\n' {
        line += 1
        column = 1
      } else {
        column += 1
      }
      offset += 1
    }
  }
  if statement.length() > 0 {
    let kind = if in_string { UnterminatedString } else { InvalidEntity }
    let message = if in_string {
      "unterminated STEP string"
    } else {
      "statement is missing ';'"
    }
    errors.push(error(kind, message, statement_location))
  }
  { entities, header_present, data_present, errors, }
}
