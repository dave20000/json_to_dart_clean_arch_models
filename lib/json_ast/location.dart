class Loc {
  final int line;
  final int column;

  Loc({required this.line, required this.column});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Loc && other.line == line && other.column == column;
  }

  @override
  int get hashCode => line.hashCode ^ column.hashCode;
}

class Segment extends Loc {
  final int offset;

  Segment(int line, int column, this.offset)
      : super(line: line, column: column);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Segment && other.offset == offset;
  }

  @override
  int get hashCode => offset.hashCode;
}

class Location {
  final Segment start;
  final Segment end;
  final String source;

  Location(this.start, this.end, [this.source = ""]);

  static Location create(int startLine, int startColumn, int startOffset,
      int endLine, int endColumn, int endOffset,
      [String source = ""]) {
    final startSegment = Segment(startLine, startColumn, startOffset);
    final endSegment = Segment(endLine, endColumn, endOffset);
    return Location(startSegment, endSegment, source);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Location &&
        other.start == start &&
        other.end == end &&
        other.source == source;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode ^ source.hashCode;
}
