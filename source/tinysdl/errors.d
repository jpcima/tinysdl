module tinysdl.errors;

class ValueError: Exception {
  this(A...)(A args) {
    super(args);
  }
}

class ParsingError: Exception {
  this(A...)(A args) {
    super(args);
  }
}
