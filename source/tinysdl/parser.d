module tinysdl.parser;
import tinysdl.data;
import tinysdl.errors;
import std.stdio;
import std.string: format;
import std.range: popBack;
import std.conv: to;
static import std.utf;

Tag parse(string source) {
  Context ctx = new Context;
  ctx.source = source;

  Tag root = new Tag;
  root.children = ctx.readListOfTags();

  assert(ctx.atEndOfFile());
  return root;
}

private:

final class Context {
  string source;
  size_t position = 0;
  size_t line = 1;
  size_t column = 1;
  size_t[] position_stack;
}

const dchar EOFCharacter = dchar.max;

enum CharSet {
  Space = 0b0000_0001,
  Tab = 0b0000_0010,
  SpaceTab = Space|Tab,
  Alpha = 0b0000_0100,
  Num = 0b0000_1000,
  AlphaNum = Alpha|Num,
  IdentifierExtra = 0b0001_0000,
};

void pushPosition(Context ctx) {
  ctx.position_stack ~= [ctx.line, ctx.column, ctx.position];
}

void popPosition(Context ctx) {
  ctx.line = ctx.position_stack[$-3];
  ctx.column = ctx.position_stack[$-2];
  ctx.position = ctx.position_stack[$-1];
  ctx.discardPosition();
}

void discardPosition(Context ctx) {
  ctx.position_stack = ctx.position_stack[0..$-3];
}

Tag[] readListOfTags(Context ctx) {
  Tag[] list;
  for (Tag tag; (tag = ctx.maybeReadTag()) !is null;)
    list ~= tag;
  return list;
}

Tag maybeReadTag(Context ctx) {
  ctx.skipEmptyLines();

  if (ctx.atEndOfFile())
    return null;

  Tag tag = new Tag;
  if (ctx.atBeginningOfIdentifier()) {
    tag.name = ctx.readIdentifier();
    if (ctx.currentCharacter() == ':') {
      ctx.skip();
      tag.name = tag.name ~ ':' ~ ctx.readIdentifier();
    }
  } else
    tag.name = "";

  size_t nthItem = 0;
  for (bool endOfTag = false; !endOfTag; ++nthItem) {
    size_t countWs = ctx.skipMembers(CharSet.SpaceTab);
    dchar c = ctx.currentCharacter();
    if (c == EOFCharacter) {
      endOfTag = true;

    } else if (ctx.atBeginningOfValue()) {
      if (countWs == 0 && !(nthItem == 0 && tag.name == ""))
        ctx.raiseUnexpectedCharacter();
      tag.values ~= ctx.readValue();

    } else if (ctx.atBeginningOfIdentifier()) {
      if (countWs == 0 && !(nthItem == 0 && tag.name == ""))
        ctx.raiseUnexpectedCharacter();
      tag.attributes ~= ctx.readAttribute();

    } else if (c == '\r' || c == '\n') {
      endOfTag = true;
      if (!ctx.maybeConsumeNewline)
        ctx.raiseParsingError("expected newline");

    } else if (c == ';') {
      endOfTag = true;
      ctx.skip();
      ctx.maybeConsumeNewline();

    } else if (c == '{') {
      if (countWs == 0 && !(nthItem == 0 && tag.name == ""))
        ctx.raiseUnexpectedCharacter();

      endOfTag = true;
      ctx.skip();
      if (!ctx.maybeConsumeNewline())
        ctx.raiseParsingError("expected a new line following '{'");

      do {
        ctx.skipEmptyLines();
        c = ctx.currentCharacter();
        if (c == '}') {
          ctx.skip();
        } else {
          ctx.pushPosition();
          scope(success) ctx.discardPosition();

          Tag child = ctx.maybeReadTag();
          if (child is null) {
            ctx.popPosition();
            ctx.raiseParsingError("expected tag");
          }
          tag.children ~= child;
        }
      } while (c != '}');

      if (!ctx.maybeConsumeNewline() && ctx.currentCharacter() != EOFCharacter)
        ctx.raiseParsingError("expected a new line following '}'");
    } else {
      ctx.raiseUnexpectedCharacter();
    }
  }

  return tag;
}

bool maybeConsumeNewline(Context ctx) {
  ctx.skipMembers(CharSet.SpaceTab);

  dchar c;
  size_t csize;
  c = ctx.currentCharacter(/+ref+/csize);
  if (c == '\n') {
    ctx.skip();
  } else if (c == '\r' && ctx.characterAt(ctx.position + csize) == '\n') {
    ctx.skip(2);
  } else {
    return false;
  }
  return true;
}

void skipEmptyLines(Context ctx) {
  do { ctx.skipMembers(CharSet.SpaceTab); }
  while (ctx.maybeConsumeNewline());
}

string readIdentifier(Context ctx) {
  if (!ctx.atBeginningOfIdentifier())
    ctx.raiseUnexpectedCharacterForItem("identifier");
  return ctx.collectMembers(CharSet.AlphaNum|CharSet.IdentifierExtra);
}

Value readValue(Context ctx) {
  dchar initialChar = ctx.currentCharacter();
  switch (initialChar) {
    case '0': .. case '9': case '-': case '+': case '.':
      return ctx.readNumber();
    case '"':
      return ctx.readString();
    default: {
      Value v = ctx.maybeReadBoolean();
      if (v)
        return v;
      ctx.raiseParsingError("expected value");
    }
  }
  assert(0);
}

Value readNumber(Context ctx) {
  size_t startpos = ctx.position;

  switch (ctx.currentCharacter()) {
    case '+': case '-': ctx.skip(); break;
    default:
  }

  size_t countBeforePoint = ctx.skipMembers(CharSet.Num);
  size_t countAfterPoint = 0;
  if (ctx.currentCharacter() == '.') {
    ctx.skip();
    countAfterPoint = ctx.skipMembers(CharSet.Num);
  }

  if (countBeforePoint + countAfterPoint == 0)
    ctx.raiseParsingError("invalid number value");

  switch (ctx.currentCharacter()) {
    case 'e': case 'E':
      ctx.skip();
      switch (ctx.currentCharacter()) {
        case '+': case '-':
          ctx.skip();
          break;
        default:
      }
      if (ctx.skipMembers(CharSet.Num) == 0)
        ctx.raiseParsingError("invalid number value");
      break;
    default:
  }

  string valueText = ctx.source[startpos..ctx.position];
  double valueNum = valueText.to!double;

  Value v = new Value;
  v.kind = ValueKind.Number;
  v.value.number = valueNum;
  return v;
}

Value readString(Context ctx) {
  if (ctx.currentCharacter() != '"')
    ctx.raiseUnexpectedCharacterForItem("string");
  ctx.skip();

  string valueString;
  for (dchar c; (c = ctx.currentCharacter()) != '"'; ctx.skip()) {
    if (c == EOFCharacter) {
      ctx.raiseParsingError("premature end of string");
    } else if (c == '\\') {
      ctx.skip();
      c = ctx.currentCharacter();
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
  ctx.skip();

  Value v = new Value;
  v.kind = ValueKind.Text;
  v.value.text = valueString;
  return v;
}

Attribute readAttribute(Context ctx) {
  string name = ctx.readIdentifier();
  if (ctx.currentCharacter() == ':') {
    ctx.skip();
    name = name ~ ':' ~ ctx.readIdentifier();
  }
  if (ctx.currentCharacter() != '=') {
    ctx.raiseParsingError("expected '=' after attribute name, got %s",
                      ctx.currentCharacter().characterRepresentation);
  }
  ctx.skip();

  Value value = ctx.readValue();
  Attribute attr = new Attribute;
  attr.name = name;
  attr.value = value;
  return attr;
}

Value maybeReadBoolean(Context ctx) {
  Value v = null;
  if (ctx.atBeginningOfSymbol("true")) {
    v = new Value;
    v.kind = ValueKind.Boolean;
    v.value.boolean = true;
    ctx.skip(4);
    return v;
  } else if (ctx.atBeginningOfSymbol("false")) {
    v = new Value;
    v.kind = ValueKind.Boolean;
    v.value.boolean = false;
    ctx.skip(5);
    return v;
  }
  return v;
}

bool atBeginningOfIdentifier(Context ctx) {
  dchar initialChar = ctx.currentCharacter();
  return initialChar.isMember(CharSet.Alpha);
}

bool atBeginningOfValue(Context ctx) {
  dchar initialChar = ctx.currentCharacter();
  return initialChar == '"' || initialChar.isMember(CharSet.Num) ||
      initialChar == '+' || initialChar == '-' || initialChar == '.' ||
      ctx.atBeginningOfBooleanLiteral();
}

bool atBeginningOfBooleanLiteral(Context ctx) {
  return ctx.atBeginningOfSymbol("true") || ctx.atBeginningOfSymbol("false");
}

bool atBeginningOfSymbol(Context ctx, string ident) {
  string sourceFrom = ctx.source[ctx.position..$];
  return sourceFrom.length >= ident.length &&
      sourceFrom[0..ident.length] == ident &&
      (sourceFrom.length == ident.length ||
       !sourceFrom[ident.length].isMember(CharSet.AlphaNum));
}

dchar characterAt(Context ctx, size_t index, ref size_t bytesize) {
  assert(index <= ctx.source.length);
  if (index == ctx.source.length) {
    bytesize = 0;
    return EOFCharacter;
  }
  size_t newindex = index;
  dchar c;
  try {
    c = std.utf.decode(ctx.source, /+ref+/newindex);
  } catch (std.utf.UTFException) {
    throw new ParsingError(
        format("encountered invalid Unicode at byte position %d",
               ctx.position));
  }
  bytesize = newindex - index;
  return c;
}

dchar characterAt(Context ctx, size_t index) {
  size_t bytesize;
  return ctx.characterAt(index, /+ref+/bytesize);
}

dchar currentCharacter(Context ctx, ref size_t bytesize) {
  return ctx.characterAt(ctx.position, bytesize);
}

dchar currentCharacter(Context ctx) {
  size_t bytesize;
  return ctx.currentCharacter(/+ref+/bytesize);
}

bool atEndOfFile(Context ctx) {
  return ctx.currentCharacter() == EOFCharacter;
}

string collectMembers(Context ctx, CharSet set) {
  size_t startpos = ctx.position;
  while (ctx.currentCharacter().isMember(set))
    ctx.skip();
  return ctx.source[startpos..ctx.position];
}

size_t skipMembers(Context ctx, CharSet set) {
  return ctx.collectMembers(set).length;
}

void skip(Context ctx, size_t n = 1) {
  while (n-- > 0) {
    dchar c;
    size_t csize;
    c = ctx.currentCharacter(/+ref+/csize);
    if (c == '\n') {
      ++ctx.line;
      ctx.column = 1;
    } else {
      ++ctx.column;
    }
    ctx.position += csize;
  }
}

bool isMember(dchar c, CharSet set) {
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
  if (!res && (set & CharSet.IdentifierExtra))
    res = c == '-' || c == '_' || c == '.' || c == '$';
  return res;
}

void raiseParsingError(A...)(Context ctx, string fmt, A args) {
  string msg = format("at line %d, column %d: " ~ fmt,
                      ctx.line, ctx.column, args);
  throw new ParsingError(msg);
}

void raiseUnexpectedCharacter(Context ctx) {
  ctx.raiseParsingError("unexpected character %s",
                        ctx.currentCharacter().characterRepresentation);
}

void raiseUnexpectedCharacterForItem(Context ctx, string itemName) {
  ctx.raiseParsingError("expected %s, got %s", itemName,
                        ctx.currentCharacter().characterRepresentation);
}

string characterRepresentation(dchar character) {
  if (character == EOFCharacter) {
    return "<EOF>";
  } else {
    if (std.utf.isValidDchar(character)) {
      char[4] buf;
      return format("'%s'", buf[0..std.utf.encode(buf, character)]);
    } else {
      return format("'\\U%08x'", character);
    }
  }
}
