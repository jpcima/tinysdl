module tinysdl.destructuring.errors;
import tinysdl.errors;

class DestructuringError: SdlException {
  this(A...)(A args) {
    super(args);
  }
}
