module tinysdl.destructuring.children;
import tinysdl.destructuring.common;
import tinysdl.destructuring.errors;
import tinysdl.data;
import std.traits;
import std.string: format;
import std.typecons: BitFlags;

template destructureChildren(A...) {
  void destructureChildren(Tag tag, A args) {
    foreach (Tag child; tag.children)
      if (!isKnownTag(child.name, args))
        throw new DestructuringError(
            format("unknown child named `%s` found in tag `%s`",
                   child.name, tag.name));
    recurse(tag, BitFlags!option(), args);
  }

  void recurse(A...)(Tag tag, BitFlags!option opts, A args) {
    static if (A.length > 0) {
      static if (is(A[0] == option)) {
        option opt = args[0];
        recurse!(A[1..$])(tag, opts|opt, args[1..$]);
      } else {
        string childname = args[0];
        uint count = 0;
        foreach (Tag child; tag.children) {
          if (child.name == childname) {
            if (!targetAcceptsMultivalues!(A[1]) && count > 0)
              throw new DestructuringError(
                  format("children named `%s` occur multiple times in tag `%s`",
                         childname, tag.name));
            storeChild(child, args[1]);
            ++count;
          }
        }
        if (opts & option.required) {
          if (count == 0)
            throw new DestructuringError(
                format("no child named `%s` found in tag `%s`",
                       childname, tag.name));
        }
        recurse!(A[2..$])(tag, BitFlags!option(), args[2..$]);
      }
    }
  }

  void storeChild(T)(Tag child, T dst) {
    static if (is(T == typeof(null))) {
    } else static if (is(T == Tag *)) {
      if (dst) *dst = child;
    } else static if (is(T == Tag[] *)) {
      if (dst) *dst ~= child;
    } else static if (isSomeFunction!T && Parameters!T.length == 1
                      && is(Parameters!T[0] == Tag)) {
      dst(child);
    } else
      static assert(0);
  }

  bool isKnownTag(A...)(string name, A args) {
    static if (A.length > 0) {
      static if (is(A[0] == option)) {
        return isKnownTag!(A[1..$])(name, args[1..$]);
      } else {
        return name == args[0] || isKnownTag!(A[2..$])(name, args[2..$]);
      }
    } else
      return false;
  }

  bool targetAcceptsMultivalues(T)() {
    static if (is(T == Tag *))
      return false;
    else
      return true;
  }
}
