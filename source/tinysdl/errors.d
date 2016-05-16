module tinysdl.errors;

class SdlException: Exception {
  this(A...)(A args) {
    super(args);
  }
}

class ValueError: SdlException {
  this(A...)(A args) {
    super(args);
  }
}

class ParsingError: SdlException {
  this(A...)(A args) {
    super(args);
  }
}
