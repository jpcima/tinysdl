module tinysdl.destructuring.values;
import tinysdl.destructuring.impl;
import tinysdl.destructuring.common;
import tinysdl.destructuring.errors;
import tinysdl.data;
import std.traits;
import std.range: ElementType;
import std.string: format;
import std.typecons: BitFlags;

template destructureValues(A...) {
  void destructureValues(Tag tag, A args) {
    recurse(tag, BitFlags!option(), tag.values, args);
  }

  void recurse(A...)(Tag tag, BitFlags!option opts, Value[] values, A args) {
    static if (A.length > 0) {
      static if (is(A[0] == option)) {
        option opt = args[0];
        assert(opt == option.rest);
        recurse!(A[1..$])(tag, opts|opt, values, args[1..$]);
      } else {
        if (opts & option.rest) {
          if (A.length == 1 &&canBeMultiTarget!(A[0])) {
            foreach (Value value; values)
              storeValue(tag, value, args[0]);
          } else
            assert(0);
        } else {
          if (values.length == 0)
            throw new DestructuringError(
                format("not enough values in tag `%s`", tag.name));
          assert(canBeSingleTarget!(A[0]));
          storeValue(tag, values[0], args[0]);
          recurse!(A[1..$])(tag, BitFlags!option(), values[1..$], args[1..$]);
        }
      }
    } else {
      if (values.length != 0)
        throw new DestructuringError(
            format("excess values in tag `%s`", tag.name));
    }
  }

  enum bool isArrayOfTarget(T) = isArray!T && isValidTargetType!(ElementType!T);

  bool canBeSingleTarget(T)() {
    static if (is(T == typeof(null)) || isSomeFunction!T ||
               (isPointer!T && !isArrayOfTarget!(PointerTarget!T)))
      return true;
    else
      return false;
  }

  bool canBeMultiTarget(T)() {
    static if (is(T == typeof(null)) || isSomeFunction!T ||
               (isPointer!T && isArrayOfTarget!(PointerTarget!T)))
      return true;
    else
      return false;
  }

  void storeValue(T)(Tag tag, Value value, T dst) {
    static if (is(T == typeof(null))) {
    } else static if (isPointer!T && isArrayOfTarget!(PointerTarget!T)) {
      alias Element = ElementType!(PointerTarget!T);
      if (dst) *dst ~= valueForTargetType!Element(tag, value);
    } else static if (isPointer!T) {
      alias Pointee = PointerTarget!T;
      if (dst) *dst = valueForTargetType!Pointee(tag, value);
    } else static if (isSomeFunction!T && Parameters!T.length == 1) {
      alias Parameter = Parameters!T[0];
      dst(valueForTargetType!Parameter(tag, value));
    } else
      static assert(0);
  }
}
