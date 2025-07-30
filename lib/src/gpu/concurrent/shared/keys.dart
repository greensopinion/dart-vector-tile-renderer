class GeometryKeys {
  static const indices = "idx";
  static const vertices = "vtx";
  static const type = "typ";
  static const jobId = "id";
}

enum GeometryType {
  line, poly;
}

class LineKeys {
  static const lines = "ln";
  static const joins = "jn";
  static const ends = "en";
}

enum LineJoin {
  bevel, round, miter;
}

enum LineEnd {
  butt, round, square;
}