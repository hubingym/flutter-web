bool setEquals<T>(Set<T> a, Set<T> b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (T value in a) {
    if (!b.contains(value)) return false;
  }
  return true;
}

bool listEquals<T>(List<T> a, List<T> b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
