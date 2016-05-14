module tinysdl.tests;
import tinysdl;
import std.array: empty;

unittest {
  // empty document
  { Tag doc = parse(``);
    assert(doc.children.empty);
    assert(doc.values.empty);
    assert(doc.attributes.empty);
  }

  // example document
  { Tag doc = parse(`
	"This is an anonymous tag with two values" 123
	"Another anon tag"
	person "Akiko" "Johnson" dimensions:height=68 {
		son "Nouhiro" "Johnson"
		pet:kitty "Neko"
		daughter "Sabrina" "Johnson" location="Italy" {
			hobbies "swimming" "surfing"
			languages "English" "Italian"
			smoker false
		}
	}
`);
    assert(doc.children.length == 3);

    assert(doc.children[0].name == "");
    assert(doc.children[0].values.length == 2);
    assert(doc.children[0].values[0].asText == "This is an anonymous tag with two values");
    assert(doc.children[0].values[1].asNumber == 123);
    assert(doc.children[0].attributes.empty);
    assert(doc.children[0].children.empty);

    assert(doc.children[1].name == "");
    assert(doc.children[1].values.length == 1);
    assert(doc.children[1].values[0].asText == "Another anon tag");
    assert(doc.children[1].attributes.empty);
    assert(doc.children[1].children.empty);

    doc = doc.children[2];
    assert(doc.name == "person");
    assert(doc.values.length == 2);
    assert(doc.values[0].asText == "Akiko");
    assert(doc.values[1].asText == "Johnson");
    assert(doc.values.length == 2);
    assert(doc.attributes.length == 1);
    assert(doc.attributes[0].name == "dimensions:height");
    assert(doc.attributes[0].value.asNumber == 68);
    assert(doc.children.length == 3);

    assert(doc.children[0].name == "son");
    assert(doc.children[0].values.length == 2);
    assert(doc.children[0].values[0].asText == "Nouhiro");
    assert(doc.children[0].values[1].asText == "Johnson");
    assert(doc.children[0].attributes.empty);
    assert(doc.children[0].children.empty);

    assert(doc.children[1].name == "pet:kitty");
    assert(doc.children[1].values.length == 1);
    assert(doc.children[1].values[0].asText == "Neko");
    assert(doc.children[1].attributes.empty);
    assert(doc.children[1].children.empty);

    doc = doc.children[2];
    assert(doc.name == "daughter");
    assert(doc.values.length == 2);
    assert(doc.values[0].asText == "Sabrina");
    assert(doc.values[1].asText == "Johnson");
    assert(doc.attributes.length == 1);
    assert(doc.attributes[0].name == "location");
    assert(doc.attributes[0].value.asText == "Italy");
    assert(doc.children.length == 3);

    assert(doc.children[0].name == "hobbies");
    assert(doc.children[0].values.length == 2);
    assert(doc.children[0].values[0].asText == "swimming");
    assert(doc.children[0].values[1].asText == "surfing");
    assert(doc.children[0].attributes.empty);
    assert(doc.children[0].children.empty);

    assert(doc.children[1].name == "languages");
    assert(doc.children[1].values.length == 2);
    assert(doc.children[1].values[0].asText == "English");
    assert(doc.children[1].values[1].asText == "Italian");
    assert(doc.children[1].attributes.empty);
    assert(doc.children[1].children.empty);

    assert(doc.children[2].name == "smoker");
    assert(doc.children[2].values.length == 1);
    assert(doc.children[2].values[0].asBoolean == false);
    assert(doc.children[2].attributes.empty);
    assert(doc.children[2].children.empty);
  }
}
