module tinysdl.destructuring.attributes;
import tinysdl.destructuring.impl;
import tinysdl.destructuring.common;
import tinysdl.destructuring.errors;
import tinysdl.data;
import std.traits;
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
        assert(opt == option.required);
        recurse!(A[1..$])(tag, opts|opt, args[1..$]);
      } else {
        string attname = args[0];
        bool found = false;
        foreach (Attribute a; tag.attributes) {
          if (a.name == attname) {
            storeValue(tag, a.value, args[1]);
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

  void storeValue(T)(Tag tag, Value value, T dst) {
    static if (is(T == typeof(null))) {
    } else static if (isPointer!T) {
      auto val = valueForTargetType!(PointerTarget!T)(tag, value);
      if (dst) *dst = val;
    } else static if (isSomeFunction!T && Parameters!T.length == 1) {
      alias Parameter = Parameters!T[0];
      auto val = convert!Parameter(valueForTargetType!Parameter(tag, value));
      dst(val);
    } else
      static assert(0);
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
}
