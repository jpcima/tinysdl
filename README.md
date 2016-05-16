# TinySDL
TinySDL is not exactly a parser library for the [SDLang](https://sdlang.org/) data language.

I develop this as part of a larger project where the other library does not provide the feature I need, which is operation at compile time.
I only implement the features I need, so you should only use this if you have a good reason not to prefer [SDLang-D](https://github.com/Abscissa/SDLang-D).

Goal of this project:
* Providing a compact yet robust D implementation
* Ability to parse at compile time
* Limited compatibility with SDLang

Non-goals:
* Full compatibility
* Write support

## Parsing and traversal

The library features simple DOM style parsing and traversal.

    import tinysdl;
    ///
    Tag root = parse(aSourceText);
    foreach (Tag child; root.children) {
      ///
      foreach (Attribute attr; child.attributes) {
        ///
      }
    }

## Destructuring

Another way to process homogeneous inputs is to use the provided destructuring functionality.

It is similar in concept to the package [std.getopt](https://dlang.org/phobos/std_getopt.html) of the Phobos standard library.

    import tinysdl;
    import tinysdl.destructuring;
    ///
    enum source = `example aText="someText" aReal=3.14 aBoolean=true`;
    string aText;
    double aReal;
    bool aBoolean;
    destructureAttributes(parse(source).child(0),
                          option.required, "aText", &aText,
                          option.required, "aReal", &aReal,
                          option.required, "aBoolean", &aBoolean);

## Notes

Refer to [tests.d](source/tinysdl/tests.d) and [destructuring/tests.d](source/tinysdl/destructuring/tests.d) for some usage examples.
