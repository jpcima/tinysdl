module tinysdl.destructuring.tests;
import tinysdl;
import tinysdl.destructuring;
import std.stdio;

// Attribute destructuring
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
  { enum source = `example aOptional="a"`;
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

// Child destructuring
unittest {
  // destructuring into variables
  { enum source = `t1; t2; t3 a=1; t3 a=2;`;
    Tag t1;
    Tag t2;
    Tag[] t3;
    destructureChildren(parse(source),
                        option.required, "t1", &t1,
                        option.required, "t2", &t2,
                        option.required, "t3", &t3);
    assert(t1 !is null && t1.name == "t1");
    assert(t2 !is null && t2.name == "t2");
    assert(t3.length == 2);
    assert(t3[0].name == "t3" && t3[1].name == "t3");
    assert(t3[0].attribute("a").value.asNumber == 1 && t3[1].attribute("a").value.asNumber == 2);
  }

  // destructuring into functions
  { enum source = `t1; t2; t3 a=1; t3 a=2;`;
    Tag t1;
    Tag t2;
    Tag[] t3;
    destructureChildren(parse(source),
                        option.required, "t1", delegate(Tag v) { t1 = v; },
                        option.required, "t2", delegate(Tag v) { t2 = v; },
                        option.required, "t3", delegate(Tag v) { t3 ~= v; });
    assert(t1 !is null && t1.name == "t1");
    assert(t2 !is null && t2.name == "t2");
    assert(t3.length == 2);
    assert(t3[0].name == "t3" && t3[1].name == "t3");
    assert(t3[0].attribute("a").value.asNumber == 1 && t3[1].attribute("a").value.asNumber == 2);
  }

  // destructuring without storing
  { enum source = `t1; t2; t3 a=1; t3 a=2;`;
    destructureChildren(parse(source),
                        option.required, "t1", null,
                        option.required, "t2", null,
                        option.required, "t3", null);
  }

  // optional
  { enum source = `aRequired`;
    destructureChildren(parse(source),
                        option.required, "aRequired", null,
                        "aOptional", null);
  }
  // required
  { enum source = `aOptional`;
    try {
      destructureChildren(parse(source),
                          option.required, "aRequired", null,
                          "aOptional", null);
      assert(0);
    } catch (DestructuringError) {}
  }

  // unknown children
  { enum source = `aKnown; aUnknown`;
    try {
      destructureAttributes(parse(source).child(0),
                            "aKnown", null);
    } catch (DestructuringError) {}
  }

  // multivalues
  { enum source = `t1; t1`;
    Tag t1;
    try {
      destructureChildren(parse(source),
                          option.required, "t1", &t1);
      assert(0);
    } catch (DestructuringError) {}
  }
}

// Value destructuring
unittest {
  // destructuring into variables
  { enum source = `t1 "someText" 3.14 true`;
    string v1;
    double v2;
    bool v3;
    destructureValues(parse(source).child(0),
                      &v1, &v2, &v3);
    assert(v1 == "someText");
    assert(v2 == 3.14);
    assert(v3 == true);
  }

  // destructuring into functions
  { enum source = `t1 "someText" 3.14 true`;
    string v1;
    double v2;
    bool v3;
    destructureValues(parse(source).child(0),
                      delegate(string v) { v1 = v; },
                      delegate(double v) { v2 = v; },
                      delegate(bool v) { v3 = v; });
    assert(v1 == "someText");
    assert(v2 == 3.14);
    assert(v3 == true);
  }

  // destructuring without storing
  { enum source = `t1 "someText" 3.14 true`;
    destructureValues(parse(source).child(0),
                      null, null, null);
  }

  // destructuring with rest into variables
  { enum source = `t1 "someText" 3.14 true 1 2 3`;
    string v1;
    double v2;
    bool v3;
    int[] rest;
    destructureValues(parse(source).child(0),
                      &v1, &v2, &v3,
                      option.rest, &rest);
    assert(v1 == "someText");
    assert(v2 == 3.14);
    assert(v3 == true);
    assert(rest == [1, 2, 3]);
  }

  // destructuring with rest into functions
  { enum source = `t1 "someText" 3.14 true 1 2 3`;
    string v1;
    double v2;
    bool v3;
    int[] rest;
    destructureValues(parse(source).child(0),
                      delegate(string v) { v1 = v; },
                      delegate(double v) { v2 = v; },
                      delegate(bool v) { v3 = v; },
                      option.rest, delegate(int v) { rest ~= v; });
    assert(v1 == "someText");
    assert(v2 == 3.14);
    assert(v3 == true);
    assert(rest == [1, 2, 3]);
  }

  // destructuring with rest without storing
  { enum source = `t1 "someText" 3.14 true 1 2 3`;
    destructureValues(parse(source).child(0),
                      null, null, null,
                      option.rest, null);
  }

  // too many elements
  { enum source = `t1 1 2`;
    try {
      destructureValues(parse(source).child(0),
                        null);
      assert(0);
    } catch (DestructuringError) {}
  }

  // too few elements
  { enum source = `t1 1 2`;
    try {
      destructureValues(parse(source).child(0),
                        null, null, null);
      assert(0);
    } catch (DestructuringError) {}
  }
}
