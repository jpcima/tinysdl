module tinysdl.parser;
import tinysdl.data;
import tinysdl.errors;
import std.stdio;
import std.ascii: isPrintable;
import std.string: format;
import std.range: popBack;
import std.conv: to;

Tag parse(string sourceText) {
  source = sourceText;
  position = 0;
  line = 1;
  column = 1;

  Tag root = new Tag;
  root.children = readListOfTags();

  assert(atEndOfFile());
  return root;
}

private:

string source;
uint position;
uint line;
uint column;

const int EOFCharacter = -1;

enum CharSet {
  Space = 0b0000_0001,
  Tab = 0b0000_0010,
  SpaceTab = Space|Tab,
  Alpha = 0b0000_1000,
  Num = 0b0001_0000,
  AlphaNum = Alpha|Num,
};

uint[] position_stack;

void pushPosition() {
  position_stack ~= [line, column, position];
}

void popPosition() {
  line = position_stack[$-3];
  column = position_stack[$-2];
  position = position_stack[$-1];
  discardPosition();
}

void discardPosition() {
  position_stack = position_stack[0..$-3];
}

Tag[] readListOfTags() {
  Tag[] list;
  for (Tag tag; (tag = maybeReadTag()) !is null;)
    list ~= tag;
  return list;
}

Tag maybeReadTag() {
  skipEmptyLines();

  if (atEndOfFile())
    return null;

  Tag tag = new Tag;
  if (atBeginningOfIdentifier()) {
    tag.name = readIdentifier();
    if (currentCharacter() == ':') {
      skip();
      tag.name = tag.name ~ ':' ~ readIdentifier();
    }
  } else
    tag.name = "";

  uint nthItem = 0;
  for (bool endOfTag = false; !endOfTag; ++nthItem) {
    uint countWs = skipMembers(CharSet.SpaceTab);
    int c = currentCharacter();
    if (c == EOFCharacter) {
      endOfTag = true;

    } else if (atBeginningOfValue()) {
      if (countWs == 0 && !(nthItem == 0 && tag.name == ""))
        raiseUnexpectedCharacter();
      tag.values ~= readValue();

    } else if (atBeginningOfIdentifier()) {
      if (countWs == 0 && !(nthItem == 0 && tag.name == ""))
        raiseUnexpectedCharacter();
      tag.attributes ~= readAttribute();

    } else if (c == '\r' || c == '\n') {
      endOfTag = true;
      if (!maybeConsumeNewline)
        raiseParsingError("expected newline");

    } else if (c == ';') {
      endOfTag = true;
      skip();
      maybeConsumeNewline();

    } else if (c == '{') {
      if (countWs == 0 && !(nthItem == 0 && tag.name == ""))
        raiseUnexpectedCharacter();

      endOfTag = true;
      skip();
      if (!maybeConsumeNewline())
        raiseParsingError("expected a new line following '{'");

      do {
        skipEmptyLines();
        c = currentCharacter();
        if (c == '}') {
          skip();
        } else {
          pushPosition();
          scope(success) discardPosition();

          Tag child = maybeReadTag();
          if (child is null) {
            popPosition();
            raiseParsingError("expected tag");
          }
          tag.children ~= child;
        }
      } while (c != '}');

      if (!maybeConsumeNewline())
        raiseParsingError("expected a new line following '}'");
    } else {
      raiseUnexpectedCharacter();
    }
  }

  return tag;
}

bool maybeConsumeNewline() {
  skipMembers(CharSet.SpaceTab);
  if (currentCharacter == '\n') {
    skip();
  } else if (currentCharacter == '\r' &&
             characterAt(position + 1) == '\n') {
    skip(2);
  } else {
    return false;
  }
  return true;
}

void skipEmptyLines() {
  do { skipMembers(CharSet.SpaceTab); }
  while (maybeConsumeNewline());
}

string readIdentifier() {
  if (!atBeginningOfIdentifier())
    raiseUnexpectedCharacterForItem("identifier");
  return collectMembers(CharSet.AlphaNum);
}

Value readValue() {
  int initialChar = currentCharacter;
  switch (initialChar) {
    case '0': .. case '9':
      return readNumber();
    case '"':
      return readString();
    default: {
      Value v = maybeReadBoolean();
      if (v)
        return v;
      raiseParsingError("expected value");
    }
  }
  assert(0);
}

Value readNumber() {
  uint startpos = position;

  switch (currentCharacter()) {
    case '+': case '-': skip(); break;
    default:
  }

  uint countBeforePoint = skipMembers(CharSet.Num);
  uint countAfterPoint = 0;
  if (currentCharacter() == '.') {
    skip();
    countAfterPoint = skipMembers(CharSet.Num);
  }

  if (countBeforePoint + countAfterPoint == 0)
    raiseParsingError("invalid number value");

  switch (currentCharacter()) {
    case 'e': case 'E':
      skip();
      switch (currentCharacter()) {
        case '+': case '-':
          skip();
          break;
        default:
      }
      if (skipMembers(CharSet.Num) == 0)
        raiseParsingError("invalid number value");
      break;
    default:
  }

  string valueText = source[startpos..position];
  double valueNum = valueText.to!double;

  Value v = new Value;
  v.kind = ValueKind.Number;
  v.value.number = valueNum;
  return v;
}

Value readString() {
  if (currentCharacter() != '"')
    raiseUnexpectedCharacterForItem("string");
  skip();

  string valueString;
  for (int c; (c = currentCharacter()) != '"'; skip()) {
    if (c == EOFCharacter) {
      raiseParsingError("premature end of string");
    } else if (c == '\\') {
      skip();
      c = currentCharacter();
      switch (c) {
        case '0': valueString ~= '\0'; break;
        case 'a': valueString ~= '\a'; break;
        case 'b': valueString ~= '\b'; break;
        case 't': valueString ~= '\t'; break;
        case 'n': valueString ~= '\n'; break;
        case 'v': valueString ~= '\v'; break;
        case 'f': valueString ~= '\f'; break;
        case 'r': valueString ~= '\r'; break;
          // TODO? hex sequences with \x
        default: valueString ~= c;
      }
    } else {
      valueString ~= c;
    }
  }
  skip();

  Value v = new Value;
  v.kind = ValueKind.Text;
  v.value.text = valueString;
  return v;
}

Attribute readAttribute() {
  string name = readIdentifier();
  if (currentCharacter() == ':') {
    skip();
    name = name ~ ':' ~ readIdentifier();
  }
  if (currentCharacter() != '=') {
    raiseParsingError("expected '=' after attribute name, got %s",
                      currentCharacter().characterRepresentation);
  }
  skip();

  Value value = readValue();
  Attribute attr = new Attribute;
  attr.name = name;
  attr.value = value;
  return attr;
}

Value maybeReadBoolean() {
  Value v = null;
  if (atBeginningOfSymbol("true")) {
    v = new Value;
    v.kind = ValueKind.Boolean;
    v.value.boolean = true;
    skip(4);
    return v;
  } else if (atBeginningOfSymbol("false")) {
    v = new Value;
    v.kind = ValueKind.Boolean;
    v.value.boolean = false;
    skip(5);
    return v;
  }
  return v;
}

bool atBeginningOfIdentifier() {
  int initialChar = currentCharacter();
  return initialChar.isMember(CharSet.Alpha);
}

bool atBeginningOfValue() {
  int initialChar = currentCharacter();
  return initialChar == '"' || initialChar.isMember(CharSet.Num) ||
      atBeginningOfBooleanLiteral();
}

bool atBeginningOfBooleanLiteral() {
  return atBeginningOfSymbol("true") || atBeginningOfSymbol("false");
}

bool atBeginningOfSymbol(string ident) {
  string sourceFrom = source[position..$];
  return sourceFrom.length >= ident.length &&
      sourceFrom[0..ident.length] == ident &&
      (sourceFrom.length == ident.length ||
       !sourceFrom[ident.length].isMember(CharSet.AlphaNum));
}

int characterAt(uint index) {
  if (index >= source.length)
    return EOFCharacter;
  return source[index];
}

int currentCharacter() {
  return characterAt(position);
}

bool atEndOfFile() {
  return currentCharacter() == EOFCharacter;
}

string collectMembers(int set) {
  uint n = 0;
  for (; currentCharacter().isMember(set); ++n)
    skip();
  return source[position-n..position];
}

uint skipMembers(int set) {
  return cast(uint)collectMembers(set).length;
}

void skip(uint n = 1) {
  while (n-- > 0) {
    assert(position < source.length);
    if (currentCharacter() == '\n') {
      ++line;
      column = 1;
    } else {
      ++column;
    }
    ++position;
  }
}

bool isMember(int c, int set) {
  bool res = false;
  if (!res && (set & CharSet.Space))
    res = c == ' ';
  if (!res && (set & CharSet.Tab))
    res = c == '\t';
  if (!res && (set & CharSet.Alpha))
    res = (c >= 'a' && c <= 'z') ||
          (c >= 'A' && c <= 'Z');
  if (!res && (set & CharSet.Num))
    res = c >= '0' && c <= '9';
  return res;
}

void raiseParsingError(A...)(string fmt, A args) {
  string msg = format("at line %d, column %d: " ~ fmt, line, column, args);
  throw new ParsingError(msg);
}

void raiseUnexpectedCharacter() {
  raiseParsingError("unexpected character %s",
                    currentCharacter().characterRepresentation);
}

void raiseUnexpectedCharacterForItem(string itemName) {
  raiseParsingError("expected %s, got %s",
                    itemName, currentCharacter().characterRepresentation);
}

string characterRepresentation(int character) {
  if (character == EOFCharacter) {
    return "<EOF>";
  } else {
    char c = cast(char)cast(uint)character;
    if (c.isPrintable)
      return "'" ~ c ~ "'";
    else
      return character.to!string;
  }
}
