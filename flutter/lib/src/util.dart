bool get assertionsEnabled {
  var k = false;
  assert(k = true);
  return k;
}

bool debugIsInTest = false;
