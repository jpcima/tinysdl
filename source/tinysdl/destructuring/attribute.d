module tinysdl.destructuring.attribute;
import tinysdl.destructuring.common;
import tinysdl.destructuring.errors;
import tinysdl.data;
import std.traits;
import std.conv: to, ConvException;
import std.string: format;
import std.typecons: BitFlags;

template destructureAttributes(A...) {
  void destructureAttributes(Tag tag, A args) {
    foreach (Attribute attr; tag.attributes)
      if (!isKnownAttribute(attr.name, args))
        throw new DestructuringError(
            format("unknown attribute named `%s` found in tag `%s`",
                   attr.name, tag.name));
    recurse(tag, BitFlags!option(), args);
  }

  void recurse(A...)(Tag tag, BitFlags!option opts, A args) {
    static if (A.length > 0) {
      static if (is(A[0] == option)) {
        option opt = args[0];
        recurse!(A[1..$])(tag, opts|opt, args[1..$]);
      } else {
        string attname = args[0];
        bool found = false;
        foreach (Attribute a; tag.attributes) {
          if (a.name == attname) {
            storeAttribute(tag, a, args[1]);
            found = true;
            break;
          }
        }
        if (opts & option.required) {
          if (!found)
            throw new DestructuringError(
                format("no attribute named `%s` found in tag `%s`",
                       attname, tag.name));
        }
        recurse!(A[2..$])(tag, BitFlags!option(), args[2..$]);
      }
    }
  }

  void storeAttribute(T)(Tag tag, Attribute attr, T dst) {
    static if (is(T == typeof(null))) {
    } else static if (isPointer!T) {
      alias Pointee = typeof(*T);
      auto val = valueForTargetType!Pointee(tag, attr);
      if (dst) *dst = val;
    } else static if (isSomeFunction!T && Parameters!T.length == 1) {
      alias Parameter = Parameters!T[0];
      auto val = convert!Parameter(valueForTargetType!Parameter(tag, attr));
      dst(val);
    } else
      static assert(0);
  }

  auto valueForTargetType(T)(Tag tag, Attribute attr) {
    static if (isBoolean!T) {
      typeCheck(tag, attr, ValueKind.Boolean);
      return convert!T(attr.value.value.boolean);
    } else static if (isNumeric!T) {
      typeCheck(tag, attr, ValueKind.Number);
      double source = attr.value.value.number;
      T target = convert!T(source);
      static if (isIntegral!T) {
        if (source != target)
          throw new DestructuringError(
              format("attribute `%s` expected to be of integral type in tag `%s`",
                     attr.name, tag.name));
      }
      return target;
    } else static if (isSomeString!T) {
      typeCheck(tag, attr, ValueKind.Text);
      return convert!T(attr.value.value.text);
    } else {
      static assert(0);
    }
  }

  void typeCheck(Tag tag, Attribute attr, ValueKind kind) {
    if (attr.value.kind != kind)
      throw new DestructuringError(
          format("attribute `%s` expected to be of type %s in tag `%s`",
                 attr.name, kind, tag.name));
  }

  bool isKnownAttribute(A...)(string name, A args) {
    static if (A.length > 0) {
      static if (is(A[0] == option)) {
        return isKnownAttribute!(A[1..$])(name, args[1..$]);
      } else {
        return name == args[0] || isKnownAttribute!(A[2..$])(name, args[2..$]);
      }
    } else
      return false;
  }

  T convert(T, S)(S source) {
    T target;
    try {
      target = to!T(source);
    } catch (ConvException) {
      throw new DestructuringError(
          format("cannot convert the value `%s` to %s",
                 source, T.stringof));
    }
    return target;
  }
}
