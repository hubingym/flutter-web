import 'dart:async';

typedef LicenseEntryCollector = Stream<LicenseEntry> Function();

class LicenseParagraph {
  const LicenseParagraph(this.text, this.indent);

  final String text;

  final int indent;

  static const int centeredIndent = -1;
}

abstract class LicenseEntry {
  const LicenseEntry();

  Iterable<String> get packages;

  Iterable<LicenseParagraph> get paragraphs;
}

enum _LicenseEntryWithLineBreaksParserState {
  beforeParagraph,
  inParagraph,
}

class LicenseEntryWithLineBreaks extends LicenseEntry {
  const LicenseEntryWithLineBreaks(this.packages, this.text);

  @override
  final List<String> packages;

  final String text;

  @override
  Iterable<LicenseParagraph> get paragraphs sync* {
    int lineStart = 0;
    int currentPosition = 0;
    int lastLineIndent = 0;
    int currentLineIndent = 0;
    int currentParagraphIndentation;
    _LicenseEntryWithLineBreaksParserState state =
        _LicenseEntryWithLineBreaksParserState.beforeParagraph;
    final List<String> lines = <String>[];

    void addLine() {
      assert(lineStart < currentPosition);
      lines.add(text.substring(lineStart, currentPosition));
    }

    LicenseParagraph getParagraph() {
      assert(lines.isNotEmpty);
      assert(currentParagraphIndentation != null);
      final LicenseParagraph result =
          LicenseParagraph(lines.join(' '), currentParagraphIndentation);
      assert(result.text.trimLeft() == result.text);
      assert(result.text.isNotEmpty);
      lines.clear();
      return result;
    }

    while (currentPosition < text.length) {
      switch (state) {
        case _LicenseEntryWithLineBreaksParserState.beforeParagraph:
          assert(lineStart == currentPosition);
          switch (text[currentPosition]) {
            case ' ':
              lineStart = currentPosition + 1;
              currentLineIndent += 1;
              state = _LicenseEntryWithLineBreaksParserState.beforeParagraph;
              break;
            case '\t':
              lineStart = currentPosition + 1;
              currentLineIndent += 8;
              state = _LicenseEntryWithLineBreaksParserState.beforeParagraph;
              break;
            case '\n':
            case '\f':
              if (lines.isNotEmpty) {
                yield getParagraph();
              }
              lastLineIndent = 0;
              currentLineIndent = 0;
              currentParagraphIndentation = null;
              lineStart = currentPosition + 1;
              state = _LicenseEntryWithLineBreaksParserState.beforeParagraph;
              break;
            case '[':
              currentLineIndent += 1;
              continue startParagraph;
            startParagraph:
            default:
              if (lines.isNotEmpty && currentLineIndent > lastLineIndent) {
                yield getParagraph();
                currentParagraphIndentation = null;
              }

              if (currentParagraphIndentation == null) {
                if (currentLineIndent > 10)
                  currentParagraphIndentation = LicenseParagraph.centeredIndent;
                else
                  currentParagraphIndentation = currentLineIndent ~/ 3;
              }
              state = _LicenseEntryWithLineBreaksParserState.inParagraph;
          }
          break;
        case _LicenseEntryWithLineBreaksParserState.inParagraph:
          switch (text[currentPosition]) {
            case '\n':
              addLine();
              lastLineIndent = currentLineIndent;
              currentLineIndent = 0;
              lineStart = currentPosition + 1;
              state = _LicenseEntryWithLineBreaksParserState.beforeParagraph;
              break;
            case '\f':
              addLine();
              yield getParagraph();
              lastLineIndent = 0;
              currentLineIndent = 0;
              currentParagraphIndentation = null;
              lineStart = currentPosition + 1;
              state = _LicenseEntryWithLineBreaksParserState.beforeParagraph;
              break;
            default:
              state = _LicenseEntryWithLineBreaksParserState.inParagraph;
          }
          break;
      }
      currentPosition += 1;
    }
    switch (state) {
      case _LicenseEntryWithLineBreaksParserState.beforeParagraph:
        if (lines.isNotEmpty) {
          yield getParagraph();
        }
        break;
      case _LicenseEntryWithLineBreaksParserState.inParagraph:
        addLine();
        yield getParagraph();
        break;
    }
  }
}

class LicenseRegistry {
  LicenseRegistry._();

  static List<LicenseEntryCollector> _collectors;

  static void addLicense(LicenseEntryCollector collector) {
    _collectors ??= <LicenseEntryCollector>[];
    _collectors.add(collector);
  }

  static Stream<LicenseEntry> get licenses async* {
    if (_collectors == null) return;
    for (LicenseEntryCollector collector in _collectors) yield* collector();
  }
}
