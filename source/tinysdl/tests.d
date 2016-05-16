module tinysdl.tests;
import tinysdl;
import std.stdio;
import std.array: array, empty, join;
import std.string: replace, splitLines;
import std.algorithm: map, endsWith, stripRight;

unittest {
  // empty document
  { Tag doc = parse(``);
    assert(doc.children.empty);
    assert(doc.values.empty);
    assert(doc.attributes.empty);
  }

  // example document
  { Tag doc = parse(exampleDocument);
    validateExampleDocument(doc);
  }

  { enum withoutIndentation = exampleDocument.replace("\t", "");
    Tag doc = parse(withoutIndentation);
    validateExampleDocument(doc);
  }

  { enum withSpaceIndentation = exampleDocument.replace("\t", " ");
    Tag doc = parse(withSpaceIndentation);
    validateExampleDocument(doc);
  }

  { enum withTrailingSpaces = exampleDocument.replace("\n", " \n");
    Tag doc = parse(withTrailingSpaces);
    validateExampleDocument(doc);
  }

  { enum withTrailingTabs = exampleDocument.replace("\n", "\t\n");
    Tag doc = parse(withTrailingTabs);
    validateExampleDocument(doc);
  }

  { enum withCRs = exampleDocument.replace("\n", "\r\n");
    Tag doc = parse(withCRs);
    validateExampleDocument(doc);
  }

  { enum withEmptyLines = "\n" ~ exampleDocument.replace("\n", "\n\n");
    Tag doc = parse(withEmptyLines);
    validateExampleDocument(doc);
  }

  { enum withoutFinalNewline = exampleDocument.stripRight('\n');
    Tag doc = parse(withoutFinalNewline);
    validateExampleDocument(doc);
  }

  { enum withSemicolons =
        exampleDocument
        .splitLines()
        .map!((a) =>
              a.empty() ? "" :
              a.endsWith('{') ? (a ~ '\n') :
              a.endsWith('}') ? ('\n' ~ a) :
              a ~ ';')
        .join("");
    Tag doc = parse(withSemicolons);
    validateExampleDocument(doc);
  }

  // extra identifier characters
  { enum source = `a-_.$ b-_.$:c-_.$=""`;
    Tag doc = parse(source);
    assert(doc.child(0).name == "a-_.$");
    assert(doc.child(0).attributes.length == 1);
    assert(doc.child(0).attributes[0].name == "b-_.$:c-_.$");
  }

  // number forms
  assert(parse(`1`).child(0).value(0).asNumber == 1);
  assert(parse(`1.`).child(0).value(0).asNumber == 1);
  assert(parse(`1.1`).child(0).value(0).asNumber == 1.1);
  assert(parse(`.1`).child(0).value(0).asNumber == 0.1);
  assert(parse(`1e2`).child(0).value(0).asNumber == 1e2);
  assert(parse(`1e+2`).child(0).value(0).asNumber == 1e2);
  assert(parse(`1e-2`).child(0).value(0).asNumber == 1e-2);
  assert(parse(`1.1e2`).child(0).value(0).asNumber == 1.1e2);
  assert(parse(`1.1e+2`).child(0).value(0).asNumber == 1.1e2);
  assert(parse(`1.1e-2`).child(0).value(0).asNumber == 1.1e-2);
  assert(parse(`.1e2`).child(0).value(0).asNumber == 0.1e2);
  assert(parse(`.1e+2`).child(0).value(0).asNumber == 0.1e2);
  assert(parse(`.1e-2`).child(0).value(0).asNumber == 0.1e-2);
  try { parse(`.`); assert(0); } catch (ParsingError) {}
  try { parse(`.e1`); assert(0); } catch (ParsingError) {}
  try { parse(`1e`); assert(0); } catch (ParsingError) {}
  try { parse(`1e+`); assert(0); } catch (ParsingError) {}
  try { parse(`1e-`); assert(0); } catch (ParsingError) {}

  // unicode strings
  assert(parse(`"Texte en français"`).child(0).value(0).asText == "Texte en français");
  assert(parse(`"النص العربي"`).child(0).value(0).asText == "النص العربي");
  // escape sequences in strings
  assert(parse(`"<\\\0\a\b\t\n\v\f\r>"`).child(0).value(0).asText == "<\\\0\a\b\t\n\v\f\r>");
}

enum exampleDocument = `
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
`;

void validateExampleDocument(Tag doc) {
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
