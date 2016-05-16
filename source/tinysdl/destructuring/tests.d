module tinysdl.destructuring.tests;
import tinysdl;
import tinysdl.destructuring;
import std.stdio;

unittest {
  // destructuring into variables
  { enum source = `example aText="someText" aReal=3.14 aBoolean=true`;
    string aText;
    double aReal;
    bool aBoolean;
    destructureAttributes(parse(source).child(0),
                          option.required, "aText", &aText,
                          option.required, "aReal", &aReal,
                          option.required, "aBoolean", &aBoolean);
    assert(aText == "someText");
    assert(aReal == 3.14);
    assert(aBoolean == true);
  }

  // destructuring into functions
  { enum source = `example aText="someText" aReal=3.14 aBoolean=true`;
    string aText;
    double aReal;
    bool aBoolean;
    destructureAttributes(parse(source).child(0),
                          option.required, "aText", delegate(string v) { aText = v; },
                          option.required, "aReal", delegate(double v) { aReal = v; },
                          option.required, "aBoolean", delegate(bool v) { aBoolean = v; });
    assert(aText == "someText");
    assert(aReal == 3.14);
    assert(aBoolean == true);
  }

  // destructuring without storing
  { enum source = `example aText="someText" aReal=3.14 aBoolean=true`;
    destructureAttributes(parse(source).child(0),
                          option.required, "aText", null,
                          option.required, "aReal", null,
                          option.required, "aBoolean", null);
  }

  // optional
  { enum source = `example aRequired="a"`;
    destructureAttributes(parse(source).child(0),
                          option.required, "aRequired", null,
                          "aOptional", null);
  }
  // required
  { enum source = `example`;
    try {
      destructureAttributes(parse(source).child(0),
                            option.required, "aRequired", null,
                            "aOptional", null);
      assert(0);
    } catch (DestructuringError) {}
  }

  // unknown attributes
  { enum source = `example aKnown="" aUnknown=""`;
    try {
      destructureAttributes(parse(source).child(0),
                            "aKnown", null);
    } catch (DestructuringError) {}
  }

  // automatic conversions into variables
  { enum source = `example aInteger=3`;
    int aInteger;
    destructureAttributes(parse(source).child(0),
                          option.required, "aInteger", &aInteger);
    assert(aInteger == 3);
  }
  { enum source = `example aInteger=3.14`;
    int aInteger;
    try {
      destructureAttributes(parse(source).child(0),
                            option.required, "aInteger", &aInteger);
      assert(0);
    } catch (DestructuringError) {}
  }
  { enum source = `example aInteger=-3`;
    uint aInteger;
    try {
      destructureAttributes(parse(source).child(0),
                            option.required, "aInteger", &aInteger);
      assert(0);
    } catch (DestructuringError ex) {}
  }

  // automatic conversions into functions
  { enum source = `example aInteger=3`;
    int aInteger;
    destructureAttributes(parse(source).child(0),
                          option.required, "aInteger", delegate(int v) { aInteger = v; });
    assert(aInteger == 3);
  }
  { enum source = `example aInteger=3.14`;
    try {
      destructureAttributes(parse(source).child(0),
                            option.required, "aInteger", delegate(int v) {});
      assert(0);
    } catch (DestructuringError) {}
  }
  { enum source = `example aInteger=-3`;
    try {
      destructureAttributes(parse(source).child(0),
                            option.required, "aInteger", delegate(uint v) {});
      assert(0);
    } catch (DestructuringError ex) {}
  }
}
