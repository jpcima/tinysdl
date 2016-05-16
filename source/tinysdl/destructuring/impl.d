module tinysdl.destructuring.impl;
import tinysdl.destructuring.errors;
import tinysdl.data;
import std.traits;
import std.string: format;
import std.conv: to, ConvException;

T convert(T, S)(S source) {
  T target;
  try {
    target = to!T(source);
  } catch (ConvException) {
    throw new DestructuringError(
        format("cannot convert the value `%s` to %s", source, T.stringof));
  }
  return target;
}

enum isValidTargetType(T) = isBoolean!T || isNumeric!T || isSomeString!T;

auto valueForTargetType(T)(Tag tag, Value value) {
  static if (isBoolean!T) {
    typeCheck(tag, value, ValueKind.Boolean);
    return convert!T(value.value.boolean);
  } else static if (isNumeric!T) {
    typeCheck(tag, value, ValueKind.Number);
    double source = value.value.number;
    T target = convert!T(source);
    static if (isIntegral!T) {
      if (source != target)
        throw new DestructuringError(
            format("value expected to be of integral type in tag `%s`",
                   tag.name));
    }
    return target;
  } else static if (isSomeString!T) {
    typeCheck(tag, value, ValueKind.Text);
    return convert!T(value.value.text);
  } else {
    static assert(0);
  }
}

void typeCheck(Tag tag, Value value, ValueKind kind) {
  if (value.kind != kind)
    throw new DestructuringError(
        format("value expected to be of type %s in tag `%s`",
               kind, tag.name));
}
