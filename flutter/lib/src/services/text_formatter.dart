import 'dart:math' as math;

import 'text_editing.dart';
import 'text_input.dart';

abstract class TextInputFormatter {
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  );

  static TextInputFormatter withFunction(
    TextInputFormatFunction formatFunction,
  ) {
    return _SimpleTextInputFormatter(formatFunction);
  }
}

typedef TextInputFormatFunction = TextEditingValue Function(
  TextEditingValue oldValue,
  TextEditingValue newValue,
);

class _SimpleTextInputFormatter extends TextInputFormatter {
  _SimpleTextInputFormatter(this.formatFunction)
      : assert(formatFunction != null);

  final TextInputFormatFunction formatFunction;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return formatFunction(oldValue, newValue);
  }
}

class BlacklistingTextInputFormatter extends TextInputFormatter {
  BlacklistingTextInputFormatter(
    this.blacklistedPattern, {
    this.replacementString = '',
  }) : assert(blacklistedPattern != null);

  final Pattern blacklistedPattern;

  final String replacementString;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _selectionAwareTextManipulation(
      newValue,
      (String substring) {
        return substring.replaceAll(blacklistedPattern, replacementString);
      },
    );
  }

  static final BlacklistingTextInputFormatter singleLineFormatter =
      BlacklistingTextInputFormatter(RegExp(r'\n'));
}

class LengthLimitingTextInputFormatter extends TextInputFormatter {
  LengthLimitingTextInputFormatter(this.maxLength)
      : assert(maxLength == null || maxLength == -1 || maxLength > 0);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (maxLength != null &&
        maxLength > 0 &&
        newValue.text.runes.length > maxLength) {
      final TextSelection newSelection = newValue.selection.copyWith(
        baseOffset: math.min(newValue.selection.start, maxLength),
        extentOffset: math.min(newValue.selection.end, maxLength),
      );

      final RuneIterator iterator = RuneIterator(newValue.text);
      if (iterator.moveNext())
        for (int count = 0; count < maxLength; ++count)
          if (!iterator.moveNext()) break;
      final String truncated = newValue.text.substring(0, iterator.rawIndex);
      return TextEditingValue(
        text: truncated,
        selection: newSelection,
        composing: TextRange.empty,
      );
    }
    return newValue;
  }
}

class WhitelistingTextInputFormatter extends TextInputFormatter {
  WhitelistingTextInputFormatter(this.whitelistedPattern)
      : assert(whitelistedPattern != null);

  final Pattern whitelistedPattern;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _selectionAwareTextManipulation(
      newValue,
      (String substring) {
        return whitelistedPattern
            .allMatches(substring)
            .map<String>((Match match) => match.group(0))
            .join();
      },
    );
  }

  static final WhitelistingTextInputFormatter digitsOnly =
      WhitelistingTextInputFormatter(RegExp(r'\d+'));
}

TextEditingValue _selectionAwareTextManipulation(
  TextEditingValue value,
  String substringManipulation(String substring),
) {
  final int selectionStartIndex = value.selection.start;
  final int selectionEndIndex = value.selection.end;
  String manipulatedText;
  TextSelection manipulatedSelection;
  if (selectionStartIndex < 0 || selectionEndIndex < 0) {
    manipulatedText = substringManipulation(value.text);
  } else {
    final String beforeSelection =
        substringManipulation(value.text.substring(0, selectionStartIndex));
    final String inSelection = substringManipulation(
        value.text.substring(selectionStartIndex, selectionEndIndex));
    final String afterSelection =
        substringManipulation(value.text.substring(selectionEndIndex));
    manipulatedText = beforeSelection + inSelection + afterSelection;
    if (value.selection.baseOffset > value.selection.extentOffset) {
      manipulatedSelection = value.selection.copyWith(
        baseOffset: beforeSelection.length + inSelection.length,
        extentOffset: beforeSelection.length,
      );
    } else {
      manipulatedSelection = value.selection.copyWith(
        baseOffset: beforeSelection.length,
        extentOffset: beforeSelection.length + inSelection.length,
      );
    }
  }
  return TextEditingValue(
    text: manipulatedText,
    selection:
        manipulatedSelection ?? const TextSelection.collapsed(offset: -1),
    composing:
        manipulatedText == value.text ? value.composing : TextRange.empty,
  );
}
