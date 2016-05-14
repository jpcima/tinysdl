module tinysdl.data;
import tinysdl.errors;
import std.algorithm: filter;
import std.string: format;

final class Tag {
  string name;
  Tag[] children;
  Value[] values;
  Attribute[] attributes;
}

final class Attribute {
  string name;
  Value value;
}

final class Value {
  ValueKind kind;
  ValueUnion value;
}

enum ValueKind {
  Number,
  Text,
  Boolean,
}

union ValueUnion {
  double number;
  string text;
  bool boolean;
};

auto children(Tag t, string name) {
  return t.children.filter!(c => c.name == name)();
}

Attribute attribute(Tag t, string name) {
  Attribute attr = attributeOrNull(t, name);
  if (attr is null)
    throw new ValueError(
        format("the tag has no attribute with the name '%s'", name));
  return attr;
}

Attribute attributeOrNull(Tag t, string name) {
  foreach (Attribute attr; t.attributes)
    if (attr.name == name)
      return attr;
  return null;
}

Attribute opIndex(Tag t, string name) {
  return attribute(t, name);
}

bool isNumber(Value v) {
  return v.kind == ValueKind.Number;
}

bool isText(Value v) {
  return v.kind == ValueKind.Text;
}

bool isBoolean(Value v) {
  return v.kind == ValueKind.Boolean;
}

double asNumber(Value v) {
  if (!v.isNumber)
    throw new ValueError("the value is not a number");
  return v.value.number;
}

string asText(Value v) {
  if (!v.isText)
    throw new ValueError("the value is not text");
  return v.value.text;
}

bool asBoolean(Value v) {
  if (!v.isBoolean)
    throw new ValueError("the value is not boolean");
  return v.value.boolean;
}
