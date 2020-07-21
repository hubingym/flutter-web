import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'assertions.dart';
import 'constants.dart';
import 'debug.dart';

enum DiagnosticLevel {
  hidden,

  fine,

  debug,

  info,

  warning,

  hint,

  summary,

  error,

  off,
}

enum DiagnosticsTreeStyle {
  none,

  sparse,

  offstage,

  dense,

  transition,

  error,

  whitespace,

  flat,

  singleLine,

  errorProperty,

  shallow,

  truncateChildren,
}

class TextTreeConfiguration {
  TextTreeConfiguration({
    @required this.prefixLineOne,
    @required this.prefixOtherLines,
    @required this.prefixLastChildLineOne,
    @required this.prefixOtherLinesRootNode,
    @required this.linkCharacter,
    @required this.propertyPrefixIfChildren,
    @required this.propertyPrefixNoChildren,
    this.lineBreak = '\n',
    this.lineBreakProperties = true,
    this.afterName = ':',
    this.afterDescriptionIfBody = '',
    this.afterDescription = '',
    this.beforeProperties = '',
    this.afterProperties = '',
    this.mandatoryAfterProperties = '',
    this.propertySeparator = '',
    this.bodyIndent = '',
    this.footer = '',
    this.showChildren = true,
    this.addBlankLineIfNoChildren = true,
    this.isNameOnOwnLine = false,
    this.isBlankLineBetweenPropertiesAndChildren = true,
    this.beforeName = '',
    this.suffixLineOne = '',
    this.manditoryFooter = '',
  })  : assert(prefixLineOne != null),
        assert(prefixOtherLines != null),
        assert(prefixLastChildLineOne != null),
        assert(prefixOtherLinesRootNode != null),
        assert(linkCharacter != null),
        assert(propertyPrefixIfChildren != null),
        assert(propertyPrefixNoChildren != null),
        assert(lineBreak != null),
        assert(lineBreakProperties != null),
        assert(afterName != null),
        assert(afterDescriptionIfBody != null),
        assert(afterDescription != null),
        assert(beforeProperties != null),
        assert(afterProperties != null),
        assert(propertySeparator != null),
        assert(bodyIndent != null),
        assert(footer != null),
        assert(showChildren != null),
        assert(addBlankLineIfNoChildren != null),
        assert(isNameOnOwnLine != null),
        assert(isBlankLineBetweenPropertiesAndChildren != null),
        childLinkSpace = ' ' * linkCharacter.length;

  final String prefixLineOne;

  final String suffixLineOne;

  final String prefixOtherLines;

  final String prefixLastChildLineOne;

  final String prefixOtherLinesRootNode;

  final String propertyPrefixIfChildren;

  final String propertyPrefixNoChildren;

  final String linkCharacter;

  final String childLinkSpace;

  final String lineBreak;

  final bool lineBreakProperties;

  final String beforeName;

  final String afterName;

  final String afterDescriptionIfBody;

  final String afterDescription;

  final String beforeProperties;

  final String afterProperties;

  final String mandatoryAfterProperties;

  final String propertySeparator;

  final String bodyIndent;

  final bool showChildren;

  final bool addBlankLineIfNoChildren;

  final bool isNameOnOwnLine;

  final String footer;

  final String manditoryFooter;

  final bool isBlankLineBetweenPropertiesAndChildren;
}

final TextTreeConfiguration sparseTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '├─',
  prefixOtherLines: ' ',
  prefixLastChildLineOne: '└─',
  linkCharacter: '│',
  propertyPrefixIfChildren: '│ ',
  propertyPrefixNoChildren: '  ',
  prefixOtherLinesRootNode: ' ',
);

final TextTreeConfiguration dashedTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '╎╌',
  prefixLastChildLineOne: '└╌',
  prefixOtherLines: ' ',
  linkCharacter: '╎',
  propertyPrefixIfChildren: '│ ',
  propertyPrefixNoChildren: '  ',
  prefixOtherLinesRootNode: ' ',
);

final TextTreeConfiguration denseTextConfiguration = TextTreeConfiguration(
  propertySeparator: ', ',
  beforeProperties: '(',
  afterProperties: ')',
  lineBreakProperties: false,
  prefixLineOne: '├',
  prefixOtherLines: '',
  prefixLastChildLineOne: '└',
  linkCharacter: '│',
  propertyPrefixIfChildren: '│',
  propertyPrefixNoChildren: ' ',
  prefixOtherLinesRootNode: '',
  addBlankLineIfNoChildren: false,
  isBlankLineBetweenPropertiesAndChildren: false,
);

final TextTreeConfiguration transitionTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '╞═╦══ ',
  prefixLastChildLineOne: '╘═╦══ ',
  prefixOtherLines: ' ║ ',
  footer: ' ╚═══════════',
  linkCharacter: '│',
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  prefixOtherLinesRootNode: '',
  afterName: ' ═══',
  afterDescriptionIfBody: ':',
  bodyIndent: '  ',
  isNameOnOwnLine: true,
  addBlankLineIfNoChildren: false,
  isBlankLineBetweenPropertiesAndChildren: false,
);

final TextTreeConfiguration errorTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '╞═╦',
  prefixLastChildLineOne: '╘═╦',
  prefixOtherLines: ' ║ ',
  footer: ' ╚═══════════',
  linkCharacter: '│',
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  prefixOtherLinesRootNode: '',
  beforeName: '══╡ ',
  suffixLineOne: ' ╞══',
  manditoryFooter: '═════',
  addBlankLineIfNoChildren: false,
  isBlankLineBetweenPropertiesAndChildren: false,
);

final TextTreeConfiguration whitespaceTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '',
  prefixLastChildLineOne: '',
  prefixOtherLines: ' ',
  prefixOtherLinesRootNode: '  ',
  bodyIndent: '',
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  linkCharacter: ' ',
  addBlankLineIfNoChildren: false,
  afterDescriptionIfBody: ':',
  isBlankLineBetweenPropertiesAndChildren: false,
);

final TextTreeConfiguration flatTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '',
  prefixLastChildLineOne: '',
  prefixOtherLines: '',
  prefixOtherLinesRootNode: '',
  bodyIndent: '',
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  linkCharacter: '',
  addBlankLineIfNoChildren: false,
  afterDescriptionIfBody: ':',
  isBlankLineBetweenPropertiesAndChildren: false,
);

final TextTreeConfiguration singleLineTextConfiguration = TextTreeConfiguration(
  propertySeparator: ', ',
  beforeProperties: '(',
  afterProperties: ')',
  prefixLineOne: '',
  prefixOtherLines: '',
  prefixLastChildLineOne: '',
  lineBreak: '',
  lineBreakProperties: false,
  addBlankLineIfNoChildren: false,
  showChildren: false,
  propertyPrefixIfChildren: '  ',
  propertyPrefixNoChildren: '  ',
  linkCharacter: '',
  prefixOtherLinesRootNode: '',
);

final TextTreeConfiguration errorPropertyTextConfiguration =
    TextTreeConfiguration(
  propertySeparator: ', ',
  beforeProperties: '(',
  afterProperties: ')',
  prefixLineOne: '',
  prefixOtherLines: '',
  prefixLastChildLineOne: '',
  lineBreak: '\n',
  lineBreakProperties: false,
  addBlankLineIfNoChildren: false,
  showChildren: false,
  propertyPrefixIfChildren: '  ',
  propertyPrefixNoChildren: '  ',
  linkCharacter: '',
  prefixOtherLinesRootNode: '',
  afterName: ':',
  isNameOnOwnLine: true,
);

final TextTreeConfiguration shallowTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '',
  prefixLastChildLineOne: '',
  prefixOtherLines: ' ',
  prefixOtherLinesRootNode: '  ',
  bodyIndent: '',
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  linkCharacter: ' ',
  addBlankLineIfNoChildren: false,
  afterDescriptionIfBody: ':',
  isBlankLineBetweenPropertiesAndChildren: false,
  showChildren: false,
);

enum _WordWrapParseMode { inSpace, inWord, atBreak }

class _PrefixedStringBuilder {
  _PrefixedStringBuilder(
      {@required this.prefixLineOne,
      @required String prefixOtherLines,
      this.wrapWidth})
      : _prefixOtherLines = prefixOtherLines;

  final String prefixLineOne;

  String get prefixOtherLines => _nextPrefixOtherLines ?? _prefixOtherLines;
  String _prefixOtherLines;
  set prefixOtherLines(String prefix) {
    _prefixOtherLines = prefix;
    _nextPrefixOtherLines = null;
  }

  String _nextPrefixOtherLines;
  void incrementPrefixOtherLines(String suffix,
      {@required bool updateCurrentLine}) {
    if (_currentLine.isEmpty || updateCurrentLine) {
      _prefixOtherLines = prefixOtherLines + suffix;
      _nextPrefixOtherLines = null;
    } else {
      _nextPrefixOtherLines = prefixOtherLines + suffix;
    }
  }

  final int wrapWidth;

  final StringBuffer _buffer = StringBuffer();

  final StringBuffer _currentLine = StringBuffer();

  final List<int> _wrappableRanges = <int>[];

  bool get requiresMultipleLines =>
      _numLines > 1 ||
      (_numLines == 1 && _currentLine.isNotEmpty) ||
      (_currentLine.length + _getCurrentPrefix(true).length > wrapWidth);

  bool get isCurrentLineEmpty => _currentLine.isEmpty;

  int _numLines = 0;

  void _finalizeLine(bool addTrailingLineBreak) {
    final bool firstLine = _buffer.isEmpty;
    final String text = _currentLine.toString();
    _currentLine.clear();

    if (_wrappableRanges.isEmpty) {
      _writeLine(
        text,
        includeLineBreak: addTrailingLineBreak,
        firstLine: firstLine,
      );
      return;
    }
    final Iterable<String> lines = _wordWrapLine(
      text,
      _wrappableRanges,
      wrapWidth,
      startOffset: firstLine ? prefixLineOne.length : _prefixOtherLines.length,
      otherLineOffset:
          firstLine ? _prefixOtherLines.length : _prefixOtherLines.length,
    );
    int i = 0;
    final int length = lines.length;
    for (String line in lines) {
      i++;
      _writeLine(
        line,
        includeLineBreak: addTrailingLineBreak || i < length,
        firstLine: firstLine,
      );
    }
    _wrappableRanges.clear();
  }

  static Iterable<String> _wordWrapLine(
      String message, List<int> wrapRanges, int width,
      {int startOffset = 0, int otherLineOffset = 0}) sync* {
    if (message.length + startOffset < width) {
      yield message;
      return;
    }
    int startForLengthCalculations = -startOffset;
    bool addPrefix = false;
    int index = 0;
    _WordWrapParseMode mode = _WordWrapParseMode.inSpace;
    int lastWordStart;
    int lastWordEnd;
    int start = 0;

    int currentChunk = 0;

    bool noWrap(int index) {
      while (true) {
        if (currentChunk >= wrapRanges.length) return true;

        if (index < wrapRanges[currentChunk + 1]) break;
        currentChunk += 2;
      }
      return index < wrapRanges[currentChunk];
    }

    while (true) {
      switch (mode) {
        case _WordWrapParseMode.inSpace:
          while ((index < message.length) && (message[index] == ' '))
            index += 1;
          lastWordStart = index;
          mode = _WordWrapParseMode.inWord;
          break;
        case _WordWrapParseMode.inWord:
          while ((index < message.length) &&
              (message[index] != ' ' || noWrap(index))) index += 1;
          mode = _WordWrapParseMode.atBreak;
          break;
        case _WordWrapParseMode.atBreak:
          if ((index - startForLengthCalculations > width) ||
              (index == message.length)) {
            if ((index - startForLengthCalculations <= width) ||
                (lastWordEnd == null)) {
              lastWordEnd = index;
            }
            final String line = message.substring(start, lastWordEnd);
            yield line;
            addPrefix = true;
            if (lastWordEnd >= message.length) return;

            if (lastWordEnd == index) {
              while ((index < message.length) && (message[index] == ' '))
                index += 1;
              start = index;
              mode = _WordWrapParseMode.inWord;
            } else {
              assert(lastWordStart > lastWordEnd);
              start = lastWordStart;
              mode = _WordWrapParseMode.atBreak;
            }
            startForLengthCalculations = start - otherLineOffset;
            assert(addPrefix);
            lastWordEnd = null;
          } else {
            lastWordEnd = index;

            mode = _WordWrapParseMode.inSpace;
          }
          break;
      }
    }
  }

  void write(String s, {bool allowWrap = false}) {
    if (s.isEmpty) return;

    final List<String> lines = s.split('\n');
    for (int i = 0; i < lines.length; i += 1) {
      if (i > 0) {
        _finalizeLine(true);
        _updatePrefix();
      }
      final String line = lines[i];
      if (line.isNotEmpty) {
        if (allowWrap && wrapWidth != null) {
          final int wrapStart = _currentLine.length;
          final int wrapEnd = wrapStart + line.length;
          if (_wrappableRanges.isNotEmpty &&
              _wrappableRanges.last == wrapStart) {
            _wrappableRanges.last = wrapEnd;
          } else {
            _wrappableRanges..add(wrapStart)..add(wrapEnd);
          }
        }
        _currentLine.write(line);
      }
    }
  }

  void _updatePrefix() {
    if (_nextPrefixOtherLines != null) {
      _prefixOtherLines = _nextPrefixOtherLines;
      _nextPrefixOtherLines = null;
    }
  }

  void _writeLine(
    String line, {
    @required bool includeLineBreak,
    @required bool firstLine,
  }) {
    line = '${_getCurrentPrefix(firstLine)}$line';
    _buffer.write(line.trimRight());
    if (includeLineBreak) _buffer.write('\n');
    _numLines++;
  }

  String _getCurrentPrefix(bool firstLine) {
    return _buffer.isEmpty
        ? prefixLineOne
        : (firstLine ? _prefixOtherLines : _prefixOtherLines);
  }

  void writeRawLines(String lines) {
    if (lines.isEmpty) return;

    if (_currentLine.isNotEmpty) {
      _finalizeLine(true);
    }
    assert(_currentLine.isEmpty);

    _buffer.write(lines);
    if (!lines.endsWith('\n')) _buffer.write('\n');
    _numLines++;
    _updatePrefix();
  }

  void writeStretched(String text, int targetLineLength) {
    write(text);
    final int currentLineLength =
        _currentLine.length + _getCurrentPrefix(_buffer.isEmpty).length;
    assert(_currentLine.length > 0);
    final int targetLength = targetLineLength - currentLineLength;
    if (targetLength > 0) {
      assert(text.isNotEmpty);
      final String lastChar = text[text.length - 1];
      assert(lastChar != '\n');
      _currentLine.write(lastChar * targetLength);
    }

    _wrappableRanges.clear();
  }

  String build() {
    if (_currentLine.isNotEmpty) _finalizeLine(false);

    return _buffer.toString();
  }
}

class _NoDefaultValue {
  const _NoDefaultValue();
}

const _NoDefaultValue kNoDefaultValue = _NoDefaultValue();

bool _isSingleLine(DiagnosticsTreeStyle style) {
  return style == DiagnosticsTreeStyle.singleLine;
}

class TextTreeRenderer {
  TextTreeRenderer({
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
    int wrapWidth = 100,
    int wrapWidthProperties = 65,
    int maxDescendentsTruncatableNode = -1,
  })  : assert(minLevel != null),
        _minLevel = minLevel,
        _wrapWidth = wrapWidth,
        _wrapWidthProperties = wrapWidthProperties,
        _maxDescendentsTruncatableNode = maxDescendentsTruncatableNode;

  final int _wrapWidth;
  final int _wrapWidthProperties;
  final DiagnosticLevel _minLevel;
  final int _maxDescendentsTruncatableNode;

  TextTreeConfiguration _childTextConfiguration(
    DiagnosticsNode child,
    TextTreeConfiguration textStyle,
  ) {
    final DiagnosticsTreeStyle childStyle = child?.style;
    return (_isSingleLine(childStyle) ||
            childStyle == DiagnosticsTreeStyle.errorProperty)
        ? textStyle
        : child.textTreeConfiguration;
  }

  String render(
    DiagnosticsNode node, {
    String prefixLineOne = '',
    String prefixOtherLines,
    TextTreeConfiguration parentConfiguration,
  }) {
    if (kReleaseMode) {
      return '';
    }
    final bool isSingleLine = _isSingleLine(node.style) &&
        parentConfiguration?.lineBreakProperties != true;
    prefixOtherLines ??= prefixLineOne;
    if (node.linePrefix != null) {
      prefixLineOne += node.linePrefix;
      prefixOtherLines += node.linePrefix;
    }

    final TextTreeConfiguration config = node.textTreeConfiguration;
    if (prefixOtherLines.isEmpty)
      prefixOtherLines += config.prefixOtherLinesRootNode;

    if (node.style == DiagnosticsTreeStyle.truncateChildren) {
      final List<String> descendants = <String>[];
      const int maxDepth = 5;
      int depth = 0;
      const int maxLines = 25;
      int lines = 0;
      void visitor(DiagnosticsNode node) {
        for (DiagnosticsNode child in node.getChildren()) {
          if (lines < maxLines) {
            depth += 1;
            descendants.add('$prefixOtherLines${"  " * depth}$child');
            if (depth < maxDepth) visitor(child);
            depth -= 1;
          } else if (lines == maxLines) {
            descendants.add(
                '$prefixOtherLines  ...(descendants list truncated after $lines lines)');
          }
          lines += 1;
        }
      }

      visitor(node);
      final StringBuffer information = StringBuffer(prefixLineOne);
      if (lines > 1) {
        information.writeln(
            'This ${node.name} had the following descendants (showing up to depth $maxDepth):');
      } else if (descendants.length == 1) {
        information.writeln('This ${node.name} had the following child:');
      } else {
        information.writeln('This ${node.name} has no descendants.');
      }
      information.writeAll(descendants, '\n');
      return information.toString();
    }
    final _PrefixedStringBuilder builder = _PrefixedStringBuilder(
      prefixLineOne: prefixLineOne,
      prefixOtherLines: prefixOtherLines,
      wrapWidth:
          math.max(_wrapWidth, prefixOtherLines.length + _wrapWidthProperties),
    );

    List<DiagnosticsNode> children = node.getChildren();

    String description =
        node.toDescription(parentConfiguration: parentConfiguration);
    if (config.beforeName.isNotEmpty) {
      builder.write(config.beforeName);
    }
    final bool wrapName = !isSingleLine && node.allowNameWrap;
    final bool wrapDescription = !isSingleLine && node.allowWrap;
    final bool uppercaseTitle = node.style == DiagnosticsTreeStyle.error;
    String name = node.name;
    if (uppercaseTitle) {
      name = name?.toUpperCase();
    }
    if (description == null || description.isEmpty) {
      if (node.showName && name != null)
        builder.write(name, allowWrap: wrapName);
    } else {
      bool includeName = false;
      if (name != null && name.isNotEmpty && node.showName) {
        includeName = true;
        builder.write(name, allowWrap: wrapName);
        if (node.showSeparator)
          builder.write(config.afterName, allowWrap: wrapName);

        builder.write(
          config.isNameOnOwnLine || description.contains('\n') ? '\n' : ' ',
          allowWrap: wrapName,
        );
      }
      if (!isSingleLine &&
          builder.requiresMultipleLines &&
          !builder.isCurrentLineEmpty) {
        builder.write('\n');
      }
      if (includeName) {
        builder.incrementPrefixOtherLines(
          children.isEmpty
              ? config.propertyPrefixNoChildren
              : config.propertyPrefixIfChildren,
          updateCurrentLine: true,
        );
      }

      if (uppercaseTitle) {
        description = description.toUpperCase();
      }
      builder.write(description.trimRight(), allowWrap: wrapDescription);

      if (!includeName) {
        builder.incrementPrefixOtherLines(
          children.isEmpty
              ? config.propertyPrefixNoChildren
              : config.propertyPrefixIfChildren,
          updateCurrentLine: false,
        );
      }
    }
    if (config.suffixLineOne.isNotEmpty) {
      builder.writeStretched(config.suffixLineOne, builder.wrapWidth);
    }

    final Iterable<DiagnosticsNode> propertiesIterable = node
        .getProperties()
        .where((DiagnosticsNode n) => !n.isFiltered(_minLevel));
    List<DiagnosticsNode> properties;
    if (_maxDescendentsTruncatableNode >= 0 && node.allowTruncate) {
      if (propertiesIterable.length < _maxDescendentsTruncatableNode) {
        properties =
            propertiesIterable.take(_maxDescendentsTruncatableNode).toList();
        properties.add(DiagnosticsNode.message('...'));
      } else {
        properties = propertiesIterable.toList();
      }
      if (_maxDescendentsTruncatableNode < children.length) {
        children = children.take(_maxDescendentsTruncatableNode).toList();
        children.add(DiagnosticsNode.message('...'));
      }
    } else {
      properties = propertiesIterable.toList();
    }

    if ((properties.isNotEmpty ||
            children.isNotEmpty ||
            node.emptyBodyDescription != null) &&
        (node.showSeparator || description?.isNotEmpty == true)) {
      builder.write(config.afterDescriptionIfBody);
    }

    if (config.lineBreakProperties) builder.write(config.lineBreak);

    if (properties.isNotEmpty) builder.write(config.beforeProperties);

    builder.incrementPrefixOtherLines(config.bodyIndent,
        updateCurrentLine: false);

    if (node.emptyBodyDescription != null &&
        properties.isEmpty &&
        children.isEmpty &&
        prefixLineOne.isNotEmpty) {
      builder.write(node.emptyBodyDescription);
      if (config.lineBreakProperties) builder.write(config.lineBreak);
    }

    for (int i = 0; i < properties.length; ++i) {
      final DiagnosticsNode property = properties[i];
      if (i > 0) builder.write(config.propertySeparator);

      final TextTreeConfiguration propertyStyle =
          property.textTreeConfiguration;
      if (_isSingleLine(property.style)) {
        final String propertyRender = render(
          property,
          prefixLineOne: '${propertyStyle.prefixLineOne}',
          prefixOtherLines:
              '${propertyStyle.childLinkSpace}${propertyStyle.prefixOtherLines}',
          parentConfiguration: config,
        );
        final List<String> propertyLines = propertyRender.split('\n');
        if (propertyLines.length == 1 && !config.lineBreakProperties) {
          builder.write(propertyLines.first);
        } else {
          builder.write(propertyRender, allowWrap: false);
          if (!propertyRender.endsWith('\n')) builder.write('\n');
        }
      } else {
        final String propertyRender = render(
          property,
          prefixLineOne:
              '${builder.prefixOtherLines}${propertyStyle.prefixLineOne}',
          prefixOtherLines:
              '${builder.prefixOtherLines}${propertyStyle.childLinkSpace}${propertyStyle.prefixOtherLines}',
          parentConfiguration: config,
        );
        builder.writeRawLines(propertyRender);
      }
    }
    if (properties.isNotEmpty) builder.write(config.afterProperties);

    builder.write(config.mandatoryAfterProperties);

    if (!config.lineBreakProperties) builder.write(config.lineBreak);

    final String prefixChildren = '${config.bodyIndent}';
    final String prefixChildrenRaw = '$prefixOtherLines$prefixChildren';
    if (children.isEmpty &&
        config.addBlankLineIfNoChildren &&
        builder.requiresMultipleLines &&
        builder.prefixOtherLines.trimRight().isNotEmpty) {
      builder.write(config.lineBreak);
    }

    if (children.isNotEmpty && config.showChildren) {
      if (config.isBlankLineBetweenPropertiesAndChildren &&
          properties.isNotEmpty &&
          children.first.textTreeConfiguration
              .isBlankLineBetweenPropertiesAndChildren) {
        builder.write(config.lineBreak);
      }

      builder.prefixOtherLines = prefixOtherLines;

      for (int i = 0; i < children.length; i++) {
        final DiagnosticsNode child = children[i];
        assert(child != null);
        final TextTreeConfiguration childConfig =
            _childTextConfiguration(child, config);
        if (i == children.length - 1) {
          final String lastChildPrefixLineOne =
              '$prefixChildrenRaw${childConfig.prefixLastChildLineOne}';
          final String childPrefixOtherLines =
              '$prefixChildrenRaw${childConfig.childLinkSpace}${childConfig.prefixOtherLines}';
          builder.writeRawLines(render(
            child,
            prefixLineOne: lastChildPrefixLineOne,
            prefixOtherLines: childPrefixOtherLines,
            parentConfiguration: config,
          ));
          if (childConfig.footer.isNotEmpty) {
            builder.prefixOtherLines = prefixChildrenRaw;
            builder.write('${childConfig.childLinkSpace}${childConfig.footer}');
            if (childConfig.manditoryFooter.isNotEmpty) {
              builder.writeStretched(
                childConfig.manditoryFooter,
                math.max(builder.wrapWidth,
                    _wrapWidthProperties + childPrefixOtherLines.length),
              );
            }
            builder.write(config.lineBreak);
          }
        } else {
          final TextTreeConfiguration nextChildStyle =
              _childTextConfiguration(children[i + 1], config);
          final String childPrefixLineOne =
              '$prefixChildrenRaw${childConfig.prefixLineOne}';
          final String childPrefixOtherLines =
              '$prefixChildrenRaw${nextChildStyle.linkCharacter}${childConfig.prefixOtherLines}';
          builder.writeRawLines(render(
            child,
            prefixLineOne: childPrefixLineOne,
            prefixOtherLines: childPrefixOtherLines,
            parentConfiguration: config,
          ));
          if (childConfig.footer.isNotEmpty) {
            builder.prefixOtherLines = prefixChildrenRaw;
            builder.write('${childConfig.linkCharacter}${childConfig.footer}');
            if (childConfig.manditoryFooter.isNotEmpty) {
              builder.writeStretched(
                childConfig.manditoryFooter,
                math.max(builder.wrapWidth,
                    _wrapWidthProperties + childPrefixOtherLines.length),
              );
            }
            builder.write(config.lineBreak);
          }
        }
      }
    }
    if (parentConfiguration == null && config.manditoryFooter.isNotEmpty) {
      builder.writeStretched(config.manditoryFooter, builder.wrapWidth);
      builder.write(config.lineBreak);
    }
    return builder.build();
  }
}

abstract class DiagnosticsNode {
  DiagnosticsNode({
    @required this.name,
    this.style,
    this.showName = true,
    this.showSeparator = true,
    this.linePrefix,
  })  : assert(showName != null),
        assert(showSeparator != null),
        assert(
            name == null || !name.endsWith(':'),
            'Names of diagnostic nodes must not end with colons.\n'
            'name:\n'
            '  "$name"');

  factory DiagnosticsNode.message(
    String message, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
    bool allowWrap = true,
  }) {
    assert(style != null);
    assert(level != null);
    return DiagnosticsProperty<void>(
      '',
      null,
      description: message,
      style: style,
      showName: false,
      allowWrap: allowWrap,
      level: level,
    );
  }

  final String name;

  String toDescription({TextTreeConfiguration parentConfiguration});

  final bool showSeparator;

  bool isFiltered(DiagnosticLevel minLevel) =>
      kReleaseMode || level.index < minLevel.index;

  DiagnosticLevel get level =>
      kReleaseMode ? DiagnosticLevel.hidden : DiagnosticLevel.info;

  final bool showName;

  final String linePrefix;

  String get emptyBodyDescription => null;

  Object get value;

  final DiagnosticsTreeStyle style;

  bool get allowWrap => false;

  bool get allowNameWrap => false;

  bool get allowTruncate => false;

  List<DiagnosticsNode> getProperties();

  List<DiagnosticsNode> getChildren();

  String get _separator => showSeparator ? ':' : '';

  @mustCallSuper
  Map<String, Object> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    if (kReleaseMode) {
      return <String, Object>{};
    }
    final bool hasChildren = getChildren().isNotEmpty;
    return <String, Object>{
      'description': toDescription(),
      'type': runtimeType.toString(),
      if (name != null) 'name': name,
      if (!showSeparator) 'showSeparator': showSeparator,
      if (level != DiagnosticLevel.info) 'level': describeEnum(level),
      if (showName == false) 'showName': showName,
      if (emptyBodyDescription != null)
        'emptyBodyDescription': emptyBodyDescription,
      if (style != DiagnosticsTreeStyle.sparse) 'style': describeEnum(style),
      if (allowTruncate) 'allowTruncate': allowTruncate,
      if (hasChildren) 'hasChildren': hasChildren,
      if (linePrefix?.isNotEmpty == true) 'linePrefix': linePrefix,
      if (!allowWrap) 'allowWrap': allowWrap,
      if (allowNameWrap) 'allowNameWrap': allowNameWrap,
      ...delegate.additionalNodeProperties(this),
      if (delegate.includeProperties)
        'properties': toJsonList(
          delegate.filterProperties(getProperties(), this),
          this,
          delegate,
        ),
      if (delegate.subtreeDepth > 0)
        'children': toJsonList(
          delegate.filterChildren(getChildren(), this),
          this,
          delegate,
        ),
    };
  }

  static List<Map<String, Object>> toJsonList(
    List<DiagnosticsNode> nodes,
    DiagnosticsNode parent,
    DiagnosticsSerializationDelegate delegate,
  ) {
    bool truncated = false;
    if (nodes == null) return const <Map<String, Object>>[];
    final int originalNodeCount = nodes.length;
    nodes = delegate.truncateNodesList(nodes, parent);
    if (nodes.length != originalNodeCount) {
      nodes.add(DiagnosticsNode.message('...'));
      truncated = true;
    }
    final List<Map<String, Object>> json =
        nodes.map<Map<String, Object>>((DiagnosticsNode node) {
      return node.toJsonMap(delegate.delegateForNode(node));
    }).toList();
    if (truncated) json.last['truncated'] = true;
    return json;
  }

  @override
  String toString({
    TextTreeConfiguration parentConfiguration,
    DiagnosticLevel minLevel = DiagnosticLevel.info,
  }) {
    if (kReleaseMode) {
      return super.toString();
    }
    assert(style != null);
    assert(minLevel != null);
    if (_isSingleLine(style))
      return toStringDeep(
          parentConfiguration: parentConfiguration, minLevel: minLevel);

    final String description =
        toDescription(parentConfiguration: parentConfiguration);

    if (name == null || name.isEmpty || !showName) return description;

    return description.contains('\n')
        ? '$name$_separator\n$description'
        : '$name$_separator $description';
  }

  @protected
  TextTreeConfiguration get textTreeConfiguration {
    assert(style != null);
    switch (style) {
      case DiagnosticsTreeStyle.none:
        return null;
      case DiagnosticsTreeStyle.dense:
        return denseTextConfiguration;
      case DiagnosticsTreeStyle.sparse:
        return sparseTextConfiguration;
      case DiagnosticsTreeStyle.offstage:
        return dashedTextConfiguration;
      case DiagnosticsTreeStyle.whitespace:
        return whitespaceTextConfiguration;
      case DiagnosticsTreeStyle.transition:
        return transitionTextConfiguration;
      case DiagnosticsTreeStyle.singleLine:
        return singleLineTextConfiguration;
      case DiagnosticsTreeStyle.errorProperty:
        return errorPropertyTextConfiguration;
      case DiagnosticsTreeStyle.shallow:
        return shallowTextConfiguration;
      case DiagnosticsTreeStyle.error:
        return errorTextConfiguration;
      case DiagnosticsTreeStyle.truncateChildren:
        return whitespaceTextConfiguration;
      case DiagnosticsTreeStyle.flat:
        return flatTextConfiguration;
    }
    return null;
  }

  String toStringDeep({
    String prefixLineOne = '',
    String prefixOtherLines,
    TextTreeConfiguration parentConfiguration,
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    if (kReleaseMode) {
      return '';
    }
    return TextTreeRenderer(
      minLevel: minLevel,
      wrapWidth: 65,
      wrapWidthProperties: 65,
    ).render(
      this,
      prefixLineOne: prefixLineOne,
      prefixOtherLines: prefixOtherLines,
      parentConfiguration: parentConfiguration,
    );
  }
}

class MessageProperty extends DiagnosticsProperty<void> {
  MessageProperty(
    String name,
    String message, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(name != null),
        assert(message != null),
        assert(style != null),
        assert(level != null),
        super(name, null, description: message, style: style, level: level);
}

class StringProperty extends DiagnosticsProperty<String> {
  StringProperty(
    String name,
    String value, {
    String description,
    String tooltip,
    bool showName = true,
    Object defaultValue = kNoDefaultValue,
    this.quoted = true,
    String ifEmpty,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(showName != null),
        assert(quoted != null),
        assert(style != null),
        assert(level != null),
        super(
          name,
          value,
          description: description,
          defaultValue: defaultValue,
          tooltip: tooltip,
          showName: showName,
          ifEmpty: ifEmpty,
          style: style,
          level: level,
        );

  final bool quoted;

  @override
  Map<String, Object> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object> json = super.toJsonMap(delegate);
    json['quoted'] = quoted;
    return json;
  }

  @override
  String valueToString({TextTreeConfiguration parentConfiguration}) {
    String text = _description ?? value;
    if (parentConfiguration != null &&
        !parentConfiguration.lineBreakProperties &&
        text != null) {
      text = text.replaceAll('\n', '\\n');
    }

    if (quoted && text != null) {
      if (ifEmpty != null && text.isEmpty) return ifEmpty;
      return '"$text"';
    }
    return text.toString();
  }
}

abstract class _NumProperty<T extends num> extends DiagnosticsProperty<T> {
  _NumProperty(
    String name,
    T value, {
    String ifNull,
    this.unit,
    bool showName = true,
    Object defaultValue = kNoDefaultValue,
    String tooltip,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  }) : super(
          name,
          value,
          ifNull: ifNull,
          showName: showName,
          defaultValue: defaultValue,
          tooltip: tooltip,
          level: level,
          style: style,
        );

  _NumProperty.lazy(
    String name,
    ComputePropertyValueCallback<T> computeValue, {
    String ifNull,
    this.unit,
    bool showName = true,
    Object defaultValue = kNoDefaultValue,
    String tooltip,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  }) : super.lazy(
          name,
          computeValue,
          ifNull: ifNull,
          showName: showName,
          defaultValue: defaultValue,
          tooltip: tooltip,
          style: style,
          level: level,
        );

  @override
  Map<String, Object> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object> json = super.toJsonMap(delegate);
    if (unit != null) json['unit'] = unit;

    json['numberToString'] = numberToString();
    return json;
  }

  final String unit;

  String numberToString();

  @override
  String valueToString({TextTreeConfiguration parentConfiguration}) {
    if (value == null) return value.toString();

    return unit != null ? '${numberToString()}$unit' : numberToString();
  }
}

class DoubleProperty extends _NumProperty<double> {
  DoubleProperty(
    String name,
    double value, {
    String ifNull,
    String unit,
    String tooltip,
    Object defaultValue = kNoDefaultValue,
    bool showName = true,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(showName != null),
        assert(style != null),
        assert(level != null),
        super(
          name,
          value,
          ifNull: ifNull,
          unit: unit,
          tooltip: tooltip,
          defaultValue: defaultValue,
          showName: showName,
          style: style,
          level: level,
        );

  DoubleProperty.lazy(
    String name,
    ComputePropertyValueCallback<double> computeValue, {
    String ifNull,
    bool showName = true,
    String unit,
    String tooltip,
    Object defaultValue = kNoDefaultValue,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(showName != null),
        assert(level != null),
        super.lazy(
          name,
          computeValue,
          showName: showName,
          ifNull: ifNull,
          unit: unit,
          tooltip: tooltip,
          defaultValue: defaultValue,
          level: level,
        );

  @override
  String numberToString() => debugFormatDouble(value);
}

class IntProperty extends _NumProperty<int> {
  IntProperty(
    String name,
    int value, {
    String ifNull,
    bool showName = true,
    String unit,
    Object defaultValue = kNoDefaultValue,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(showName != null),
        assert(level != null),
        assert(style != null),
        super(
          name,
          value,
          ifNull: ifNull,
          showName: showName,
          unit: unit,
          defaultValue: defaultValue,
          level: level,
        );

  @override
  String numberToString() => value.toString();
}

class PercentProperty extends DoubleProperty {
  PercentProperty(
    String name,
    double fraction, {
    String ifNull,
    bool showName = true,
    String tooltip,
    String unit,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(showName != null),
        assert(level != null),
        super(
          name,
          fraction,
          ifNull: ifNull,
          showName: showName,
          tooltip: tooltip,
          unit: unit,
          level: level,
        );

  @override
  String valueToString({TextTreeConfiguration parentConfiguration}) {
    if (value == null) return value.toString();
    return unit != null ? '${numberToString()} $unit' : numberToString();
  }

  @override
  String numberToString() {
    if (value == null) return value.toString();
    return '${(value.clamp(0.0, 1.0) * 100.0).toStringAsFixed(1)}%';
  }
}

class FlagProperty extends DiagnosticsProperty<bool> {
  FlagProperty(
    String name, {
    @required bool value,
    this.ifTrue,
    this.ifFalse,
    bool showName = false,
    Object defaultValue,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(showName != null),
        assert(level != null),
        assert(ifTrue != null || ifFalse != null),
        super(
          name,
          value,
          showName: showName,
          defaultValue: defaultValue,
          level: level,
        );

  @override
  Map<String, Object> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object> json = super.toJsonMap(delegate);
    if (ifTrue != null) json['ifTrue'] = ifTrue;
    if (ifFalse != null) json['ifFalse'] = ifFalse;

    return json;
  }

  final String ifTrue;

  final String ifFalse;

  @override
  String valueToString({TextTreeConfiguration parentConfiguration}) {
    if (value == true) {
      if (ifTrue != null) return ifTrue;
    } else if (value == false) {
      if (ifFalse != null) return ifFalse;
    }
    return super.valueToString(parentConfiguration: parentConfiguration);
  }

  @override
  bool get showName {
    if (value == null ||
        (value == true && ifTrue == null) ||
        (value == false && ifFalse == null)) {
      return true;
    }
    return super.showName;
  }

  @override
  DiagnosticLevel get level {
    if (value == true) {
      if (ifTrue == null) return DiagnosticLevel.hidden;
    }
    if (value == false) {
      if (ifFalse == null) return DiagnosticLevel.hidden;
    }
    return super.level;
  }
}

class IterableProperty<T> extends DiagnosticsProperty<Iterable<T>> {
  IterableProperty(
    String name,
    Iterable<T> value, {
    Object defaultValue = kNoDefaultValue,
    String ifNull,
    String ifEmpty = '[]',
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
    bool showName = true,
    bool showSeparator = true,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(style != null),
        assert(showName != null),
        assert(showSeparator != null),
        assert(level != null),
        super(
          name,
          value,
          defaultValue: defaultValue,
          ifNull: ifNull,
          ifEmpty: ifEmpty,
          style: style,
          showName: showName,
          showSeparator: showSeparator,
          level: level,
        );

  @override
  String valueToString({TextTreeConfiguration parentConfiguration}) {
    if (value == null) return value.toString();

    if (value.isEmpty) return ifEmpty ?? '[]';

    final Iterable<String> formattedValues = value.map((T v) {
      if (T == double && v is double) {
        return debugFormatDouble(v);
      } else {
        return v.toString();
      }
    });

    if (parentConfiguration != null &&
        !parentConfiguration.lineBreakProperties) {
      return '[${formattedValues.join(', ')}]';
    }

    return formattedValues.join(_isSingleLine(style) ? ', ' : '\n');
  }

  @override
  DiagnosticLevel get level {
    if (ifEmpty == null &&
        value != null &&
        value.isEmpty &&
        super.level != DiagnosticLevel.hidden) return DiagnosticLevel.fine;
    return super.level;
  }

  @override
  Map<String, Object> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object> json = super.toJsonMap(delegate);
    if (value != null) {
      json['values'] =
          value.map<String>((T value) => value.toString()).toList();
    }
    return json;
  }
}

class EnumProperty<T> extends DiagnosticsProperty<T> {
  EnumProperty(
    String name,
    T value, {
    Object defaultValue = kNoDefaultValue,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(level != null),
        super(
          name,
          value,
          defaultValue: defaultValue,
          level: level,
        );

  @override
  String valueToString({TextTreeConfiguration parentConfiguration}) {
    if (value == null) return value.toString();
    return describeEnum(value);
  }
}

class ObjectFlagProperty<T> extends DiagnosticsProperty<T> {
  ObjectFlagProperty(
    String name,
    T value, {
    this.ifPresent,
    String ifNull,
    bool showName = false,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(ifPresent != null || ifNull != null),
        assert(showName != null),
        assert(level != null),
        super(
          name,
          value,
          showName: showName,
          ifNull: ifNull,
          level: level,
        );

  ObjectFlagProperty.has(
    String name,
    T value, {
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(name != null),
        assert(level != null),
        ifPresent = 'has $name',
        super(
          name,
          value,
          showName: false,
          level: level,
        );

  final String ifPresent;

  @override
  String valueToString({TextTreeConfiguration parentConfiguration}) {
    if (value != null) {
      if (ifPresent != null) return ifPresent;
    } else {
      if (ifNull != null) return ifNull;
    }
    return super.valueToString(parentConfiguration: parentConfiguration);
  }

  @override
  bool get showName {
    if ((value != null && ifPresent == null) ||
        (value == null && ifNull == null)) {
      return true;
    }
    return super.showName;
  }

  @override
  DiagnosticLevel get level {
    if (value != null) {
      if (ifPresent == null) return DiagnosticLevel.hidden;
    } else {
      if (ifNull == null) return DiagnosticLevel.hidden;
    }

    return super.level;
  }

  @override
  Map<String, Object> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object> json = super.toJsonMap(delegate);
    if (ifPresent != null) json['ifPresent'] = ifPresent;
    return json;
  }
}

typedef ComputePropertyValueCallback<T> = T Function();

class DiagnosticsProperty<T> extends DiagnosticsNode {
  DiagnosticsProperty(
    String name,
    T value, {
    String description,
    String ifNull,
    this.ifEmpty,
    bool showName = true,
    bool showSeparator = true,
    this.defaultValue = kNoDefaultValue,
    this.tooltip,
    this.missingIfNull = false,
    String linePrefix,
    this.expandableValue = false,
    this.allowWrap = true,
    this.allowNameWrap = true,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(showName != null),
        assert(showSeparator != null),
        assert(style != null),
        assert(level != null),
        _description = description,
        _valueComputed = true,
        _value = value,
        _computeValue = null,
        ifNull = ifNull ?? (missingIfNull ? 'MISSING' : null),
        _defaultLevel = level,
        super(
          name: name,
          showName: showName,
          showSeparator: showSeparator,
          style: style,
          linePrefix: linePrefix,
        );

  DiagnosticsProperty.lazy(
    String name,
    ComputePropertyValueCallback<T> computeValue, {
    String description,
    String ifNull,
    this.ifEmpty,
    bool showName = true,
    bool showSeparator = true,
    this.defaultValue = kNoDefaultValue,
    this.tooltip,
    this.missingIfNull = false,
    this.expandableValue = false,
    this.allowWrap = true,
    this.allowNameWrap = true,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(showName != null),
        assert(showSeparator != null),
        assert(defaultValue == kNoDefaultValue || defaultValue is T),
        assert(missingIfNull != null),
        assert(style != null),
        assert(level != null),
        _description = description,
        _valueComputed = false,
        _value = null,
        _computeValue = computeValue,
        _defaultLevel = level,
        ifNull = ifNull ?? (missingIfNull ? 'MISSING' : null),
        super(
          name: name,
          showName: showName,
          showSeparator: showSeparator,
          style: style,
        );

  final String _description;

  final bool expandableValue;

  @override
  final bool allowWrap;

  @override
  final bool allowNameWrap;

  @override
  Map<String, Object> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final T v = value;
    List<Map<String, Object>> properties;
    if (delegate.expandPropertyValues &&
        delegate.includeProperties &&
        v is Diagnosticable &&
        getProperties().isEmpty) {
      delegate = delegate.copyWith(subtreeDepth: 0, includeProperties: false);
      properties = DiagnosticsNode.toJsonList(
        delegate.filterProperties(v.toDiagnosticsNode().getProperties(), this),
        this,
        delegate,
      );
    }
    final Map<String, Object> json = super.toJsonMap(delegate);
    if (properties != null) {
      json['properties'] = properties;
    }
    if (defaultValue != kNoDefaultValue)
      json['defaultValue'] = defaultValue.toString();
    if (ifEmpty != null) json['ifEmpty'] = ifEmpty;
    if (ifNull != null) json['ifNull'] = ifNull;
    if (tooltip != null) json['tooltip'] = tooltip;
    json['missingIfNull'] = missingIfNull;
    if (exception != null) json['exception'] = exception.toString();
    json['propertyType'] = propertyType.toString();
    json['defaultLevel'] = describeEnum(_defaultLevel);
    if (value is Diagnosticable || value is DiagnosticsNode)
      json['isDiagnosticableValue'] = true;
    if (value is num || value is String || value is bool || value == null)
      json['value'] = value;
    return json;
  }

  String valueToString({TextTreeConfiguration parentConfiguration}) {
    final T v = value;

    return (v is DiagnosticableTree ? v.toStringShort() : v.toString()) ?? '';
  }

  @override
  String toDescription({TextTreeConfiguration parentConfiguration}) {
    if (_description != null) return _addTooltip(_description);

    if (exception != null) return 'EXCEPTION (${exception.runtimeType})';

    if (ifNull != null && value == null) return _addTooltip(ifNull);

    String result = valueToString(parentConfiguration: parentConfiguration);
    if (result.isEmpty && ifEmpty != null) result = ifEmpty;
    return _addTooltip(result);
  }

  String _addTooltip(String text) {
    assert(text != null);
    return tooltip == null ? text : '$text ($tooltip)';
  }

  final String ifNull;

  final String ifEmpty;

  final String tooltip;

  final bool missingIfNull;

  Type get propertyType => T;

  @override
  T get value {
    _maybeCacheValue();
    return _value;
  }

  T _value;

  bool _valueComputed;

  Object _exception;

  Object get exception {
    _maybeCacheValue();
    return _exception;
  }

  void _maybeCacheValue() {
    if (_valueComputed) return;

    _valueComputed = true;
    assert(_computeValue != null);
    try {
      _value = _computeValue();
    } catch (exception) {
      _exception = exception;
      _value = null;
    }
  }

  final Object defaultValue;

  final DiagnosticLevel _defaultLevel;

  @override
  DiagnosticLevel get level {
    if (_defaultLevel == DiagnosticLevel.hidden) return _defaultLevel;

    if (exception != null) return DiagnosticLevel.error;

    if (value == null && missingIfNull) return DiagnosticLevel.warning;

    if (defaultValue != kNoDefaultValue && value == defaultValue)
      return DiagnosticLevel.fine;

    return _defaultLevel;
  }

  final ComputePropertyValueCallback<T> _computeValue;

  @override
  List<DiagnosticsNode> getProperties() {
    if (expandableValue) {
      final T object = value;
      if (object is DiagnosticsNode) {
        return object.getProperties();
      }
      if (object is Diagnosticable) {
        return object.toDiagnosticsNode(style: style).getProperties();
      }
    }
    return const <DiagnosticsNode>[];
  }

  @override
  List<DiagnosticsNode> getChildren() {
    if (expandableValue) {
      final T object = value;
      if (object is DiagnosticsNode) {
        return object.getChildren();
      }
      if (object is Diagnosticable) {
        return object.toDiagnosticsNode(style: style).getChildren();
      }
    }
    return const <DiagnosticsNode>[];
  }
}

class DiagnosticableNode<T extends Diagnosticable> extends DiagnosticsNode {
  DiagnosticableNode({
    String name,
    @required this.value,
    @required DiagnosticsTreeStyle style,
  })  : assert(value != null),
        super(
          name: name,
          style: style,
        );

  @override
  final T value;

  DiagnosticPropertiesBuilder _cachedBuilder;

  DiagnosticPropertiesBuilder get builder {
    if (kReleaseMode) return null;
    if (_cachedBuilder == null) {
      _cachedBuilder = DiagnosticPropertiesBuilder();
      value?.debugFillProperties(_cachedBuilder);
    }
    return _cachedBuilder;
  }

  @override
  DiagnosticsTreeStyle get style {
    return kReleaseMode
        ? DiagnosticsTreeStyle.none
        : super.style ?? builder.defaultDiagnosticsTreeStyle;
  }

  @override
  String get emptyBodyDescription =>
      kReleaseMode ? '' : builder.emptyBodyDescription;

  @override
  List<DiagnosticsNode> getProperties() =>
      kReleaseMode ? const <DiagnosticsNode>[] : builder.properties;

  @override
  List<DiagnosticsNode> getChildren() {
    return const <DiagnosticsNode>[];
  }

  @override
  String toDescription({TextTreeConfiguration parentConfiguration}) {
    if (kReleaseMode) {
      return '';
    }
    return value.toStringShort();
  }
}

class DiagnosticableTreeNode extends DiagnosticableNode<DiagnosticableTree> {
  DiagnosticableTreeNode({
    String name,
    @required DiagnosticableTree value,
    @required DiagnosticsTreeStyle style,
  }) : super(
          name: name,
          value: value,
          style: style,
        );

  @override
  List<DiagnosticsNode> getChildren() {
    if (value != null) return value.debugDescribeChildren();
    return const <DiagnosticsNode>[];
  }
}

String shortHash(Object object) {
  return object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
}

String describeIdentity(Object object) =>
    '${object.runtimeType}#${shortHash(object)}';

String describeEnum(Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}

class DiagnosticPropertiesBuilder {
  DiagnosticPropertiesBuilder() : properties = <DiagnosticsNode>[];

  DiagnosticPropertiesBuilder.fromProperties(this.properties);

  void add(DiagnosticsNode property) {
    if (!kReleaseMode) {
      properties.add(property);
    }
  }

  final List<DiagnosticsNode> properties;

  DiagnosticsTreeStyle defaultDiagnosticsTreeStyle =
      DiagnosticsTreeStyle.sparse;

  String emptyBodyDescription;
}

abstract class Diagnosticable with DiagnosticableMixin {
  const Diagnosticable();
}

mixin DiagnosticableMixin {
  String toStringShort() => describeIdentity(this);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    String fullString;
    assert(() {
      fullString = toDiagnosticsNode(style: DiagnosticsTreeStyle.singleLine)
          .toString(minLevel: minLevel);
      return true;
    }());
    return fullString ?? toStringShort();
  }

  DiagnosticsNode toDiagnosticsNode({String name, DiagnosticsTreeStyle style}) {
    return DiagnosticableNode<Diagnosticable>(
      name: name,
      value: this,
      style: style,
    );
  }

  @protected
  @mustCallSuper
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

abstract class DiagnosticableTree extends Diagnosticable {
  const DiagnosticableTree();

  String toStringShallow({
    String joiner = ', ',
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    if (kReleaseMode) {
      return toString();
    }
    final StringBuffer result = StringBuffer();
    result.write(toString());
    result.write(joiner);
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    debugFillProperties(builder);
    result.write(
      builder.properties
          .where((DiagnosticsNode n) => !n.isFiltered(minLevel))
          .join(joiner),
    );
    return result.toString();
  }

  String toStringDeep({
    String prefixLineOne = '',
    String prefixOtherLines,
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    return toDiagnosticsNode().toStringDeep(
        prefixLineOne: prefixLineOne,
        prefixOtherLines: prefixOtherLines,
        minLevel: minLevel);
  }

  @override
  String toStringShort() => describeIdentity(this);

  @override
  DiagnosticsNode toDiagnosticsNode({String name, DiagnosticsTreeStyle style}) {
    return DiagnosticableTreeNode(
      name: name,
      value: this,
      style: style,
    );
  }

  @protected
  List<DiagnosticsNode> debugDescribeChildren() => const <DiagnosticsNode>[];
}

mixin DiagnosticableTreeMixin implements DiagnosticableTree {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return toDiagnosticsNode(style: DiagnosticsTreeStyle.singleLine)
        .toString(minLevel: minLevel);
  }

  @override
  String toStringShallow({
    String joiner = ', ',
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    if (kReleaseMode) {
      return toString();
    }
    final StringBuffer result = StringBuffer();
    result.write(toStringShort());
    result.write(joiner);
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    debugFillProperties(builder);
    result.write(
      builder.properties
          .where((DiagnosticsNode n) => !n.isFiltered(minLevel))
          .join(joiner),
    );
    return result.toString();
  }

  @override
  String toStringDeep({
    String prefixLineOne = '',
    String prefixOtherLines,
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    return toDiagnosticsNode().toStringDeep(
        prefixLineOne: prefixLineOne,
        prefixOtherLines: prefixOtherLines,
        minLevel: minLevel);
  }

  @override
  String toStringShort() => describeIdentity(this);

  @override
  DiagnosticsNode toDiagnosticsNode({String name, DiagnosticsTreeStyle style}) {
    return DiagnosticableTreeNode(
      name: name,
      value: this,
      style: style,
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => const <DiagnosticsNode>[];

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

class DiagnosticsBlock extends DiagnosticsNode {
  DiagnosticsBlock({
    String name,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.whitespace,
    bool showName = true,
    bool showSeparator = true,
    String linePrefix,
    this.value,
    String description,
    this.level = DiagnosticLevel.info,
    this.allowTruncate = false,
    List<DiagnosticsNode> children = const <DiagnosticsNode>[],
    List<DiagnosticsNode> properties = const <DiagnosticsNode>[],
  })  : _description = description,
        _children = children,
        _properties = properties,
        super(
          name: name,
          style: style,
          showName: showName && name != null,
          showSeparator: showSeparator,
          linePrefix: linePrefix,
        );

  final List<DiagnosticsNode> _children;
  final List<DiagnosticsNode> _properties;

  @override
  final DiagnosticLevel level;
  final String _description;
  @override
  final Object value;

  @override
  final bool allowTruncate;

  @override
  List<DiagnosticsNode> getChildren() => _children;

  @override
  List<DiagnosticsNode> getProperties() => _properties;

  @override
  String toDescription({TextTreeConfiguration parentConfiguration}) =>
      _description;
}

abstract class DiagnosticsSerializationDelegate {
  const factory DiagnosticsSerializationDelegate({
    int subtreeDepth,
    bool includeProperties,
  }) = _DefaultDiagnosticsSerializationDelegate;

  Map<String, Object> additionalNodeProperties(DiagnosticsNode node);

  List<DiagnosticsNode> filterChildren(
      List<DiagnosticsNode> nodes, DiagnosticsNode owner);

  List<DiagnosticsNode> filterProperties(
      List<DiagnosticsNode> nodes, DiagnosticsNode owner);

  List<DiagnosticsNode> truncateNodesList(
      List<DiagnosticsNode> nodes, DiagnosticsNode owner);

  DiagnosticsSerializationDelegate delegateForNode(DiagnosticsNode node);

  int get subtreeDepth;

  bool get includeProperties;

  bool get expandPropertyValues;

  DiagnosticsSerializationDelegate copyWith({
    int subtreeDepth,
    bool includeProperties,
  });
}

class _DefaultDiagnosticsSerializationDelegate
    implements DiagnosticsSerializationDelegate {
  const _DefaultDiagnosticsSerializationDelegate({
    this.includeProperties = false,
    this.subtreeDepth = 0,
  });

  @override
  Map<String, Object> additionalNodeProperties(DiagnosticsNode node) {
    return const <String, Object>{};
  }

  @override
  DiagnosticsSerializationDelegate delegateForNode(DiagnosticsNode node) {
    return subtreeDepth > 0 ? copyWith(subtreeDepth: subtreeDepth - 1) : this;
  }

  @override
  bool get expandPropertyValues => false;

  @override
  List<DiagnosticsNode> filterChildren(
      List<DiagnosticsNode> nodes, DiagnosticsNode owner) {
    return nodes;
  }

  @override
  List<DiagnosticsNode> filterProperties(
      List<DiagnosticsNode> nodes, DiagnosticsNode owner) {
    return nodes;
  }

  @override
  final bool includeProperties;

  @override
  final int subtreeDepth;

  @override
  List<DiagnosticsNode> truncateNodesList(
      List<DiagnosticsNode> nodes, DiagnosticsNode owner) {
    return nodes;
  }

  @override
  DiagnosticsSerializationDelegate copyWith(
      {int subtreeDepth, bool includeProperties}) {
    return _DefaultDiagnosticsSerializationDelegate(
      subtreeDepth: subtreeDepth ?? this.subtreeDepth,
      includeProperties: includeProperties ?? this.includeProperties,
    );
  }
}
