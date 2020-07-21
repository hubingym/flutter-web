import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'time.dart';
import 'text_theme.dart';
import 'typography.dart';

abstract class MaterialLocalizations {
  String get openAppDrawerTooltip;

  String get backButtonTooltip;

  String get closeButtonTooltip;

  String get deleteButtonTooltip;

  String get nextMonthTooltip;

  String get previousMonthTooltip;

  String get nextPageTooltip;

  String get previousPageTooltip;

  String get showMenuTooltip;

  String aboutListTileTitle(String applicationName);

  String get licensesPageTitle;

  String pageRowsInfoTitle(
      int firstRow, int lastRow, int rowCount, bool rowCountIsApproximate);

  String get rowsPerPageTitle;

  String tabLabel({int tabIndex, int tabCount});

  String selectedRowCountTitle(int selectedRowCount);

  String get cancelButtonLabel;

  String get closeButtonLabel;

  String get continueButtonLabel;

  String get copyButtonLabel;

  String get cutButtonLabel;

  String get okButtonLabel;

  String get pasteButtonLabel;

  String get selectAllButtonLabel;

  String get viewLicensesButtonLabel;

  String get anteMeridiemAbbreviation;

  String get postMeridiemAbbreviation;

  String get timePickerHourModeAnnouncement;

  String get timePickerMinuteModeAnnouncement;

  String get modalBarrierDismissLabel;

  String get drawerLabel;

  String get popupMenuLabel;

  String get dialogLabel;

  String get alertDialogLabel;

  String get searchFieldLabel;

  TimeOfDayFormat timeOfDayFormat({bool alwaysUse24HourFormat = false});

  ScriptCategory get scriptCategory;

  String formatDecimal(int number);

  String formatHour(TimeOfDay timeOfDay, {bool alwaysUse24HourFormat = false});

  String formatMinute(TimeOfDay timeOfDay);

  String formatTimeOfDay(TimeOfDay timeOfDay,
      {bool alwaysUse24HourFormat = false});

  String formatYear(DateTime date);

  String formatMediumDate(DateTime date);

  String formatFullDate(DateTime date);

  String formatMonthYear(DateTime date);

  List<String> get narrowWeekdays;

  int get firstDayOfWeekIndex;

  String get signedInLabel;

  String get hideAccountsLabel;

  String get showAccountsLabel;

  String get reorderItemToStart;

  String get reorderItemToEnd;

  String get reorderItemUp;

  String get reorderItemDown;

  String get reorderItemLeft;

  String get reorderItemRight;

  String get expandedIconTapHint => 'Collapse';

  String get collapsedIconTapHint => 'Expand';

  String remainingTextFieldCharacterCount(int remaining);

  String get refreshIndicatorSemanticLabel;

  static MaterialLocalizations of(BuildContext context) {
    return Localizations.of<MaterialLocalizations>(
        context, MaterialLocalizations);
  }
}

class _MaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_MaterialLocalizationsDelegate old) => false;

  @override
  String toString() => 'DefaultMaterialLocalizations.delegate(en_US)';
}

class DefaultMaterialLocalizations implements MaterialLocalizations {
  const DefaultMaterialLocalizations();

  static const List<String> _shortWeekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _narrowWeekdays = <String>[
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  static const List<String> _shortMonths = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  String formatHour(TimeOfDay timeOfDay, {bool alwaysUse24HourFormat = false}) {
    final TimeOfDayFormat format =
        timeOfDayFormat(alwaysUse24HourFormat: alwaysUse24HourFormat);
    switch (format) {
      case TimeOfDayFormat.h_colon_mm_space_a:
        return formatDecimal(
            timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod);
      case TimeOfDayFormat.HH_colon_mm:
        return _formatTwoDigitZeroPad(timeOfDay.hour);
      default:
        throw AssertionError('$runtimeType does not support $format.');
    }
  }

  String _formatTwoDigitZeroPad(int number) {
    assert(0 <= number && number < 100);

    if (number < 10) return '0$number';

    return '$number';
  }

  @override
  String formatMinute(TimeOfDay timeOfDay) {
    final int minute = timeOfDay.minute;
    return minute < 10 ? '0$minute' : minute.toString();
  }

  @override
  String formatYear(DateTime date) => date.year.toString();

  @override
  String formatMediumDate(DateTime date) {
    final String day = _shortWeekdays[date.weekday - DateTime.monday];
    final String month = _shortMonths[date.month - DateTime.january];
    return '$day, $month ${date.day}';
  }

  @override
  String formatFullDate(DateTime date) {
    final String month = _months[date.month - DateTime.january];
    return '${_weekdays[date.weekday - DateTime.monday]}, $month ${date.day}, ${date.year}';
  }

  @override
  String formatMonthYear(DateTime date) {
    final String year = formatYear(date);
    final String month = _months[date.month - DateTime.january];
    return '$month $year';
  }

  @override
  List<String> get narrowWeekdays => _narrowWeekdays;

  @override
  int get firstDayOfWeekIndex => 0;

  String _formatDayPeriod(TimeOfDay timeOfDay) {
    switch (timeOfDay.period) {
      case DayPeriod.am:
        return anteMeridiemAbbreviation;
      case DayPeriod.pm:
        return postMeridiemAbbreviation;
    }
    return null;
  }

  @override
  String formatDecimal(int number) {
    if (number > -1000 && number < 1000) return number.toString();

    final String digits = number.abs().toString();
    final StringBuffer result = StringBuffer(number < 0 ? '-' : '');
    final int maxDigitIndex = digits.length - 1;
    for (int i = 0; i <= maxDigitIndex; i += 1) {
      result.write(digits[i]);
      if (i < maxDigitIndex && (maxDigitIndex - i) % 3 == 0) result.write(',');
    }
    return result.toString();
  }

  @override
  String formatTimeOfDay(TimeOfDay timeOfDay,
      {bool alwaysUse24HourFormat = false}) {
    final StringBuffer buffer = StringBuffer();

    buffer
      ..write(
          formatHour(timeOfDay, alwaysUse24HourFormat: alwaysUse24HourFormat))
      ..write(':')
      ..write(formatMinute(timeOfDay));

    if (alwaysUse24HourFormat) {
      return '$buffer';
    }

    buffer..write(' ')..write(_formatDayPeriod(timeOfDay));
    return '$buffer';
  }

  @override
  String get openAppDrawerTooltip => 'Open navigation menu';

  @override
  String get backButtonTooltip => 'Back';

  @override
  String get closeButtonTooltip => 'Close';

  @override
  String get deleteButtonTooltip => 'Delete';

  @override
  String get nextMonthTooltip => 'Next month';

  @override
  String get previousMonthTooltip => 'Previous month';

  @override
  String get nextPageTooltip => 'Next page';

  @override
  String get previousPageTooltip => 'Previous page';

  @override
  String get showMenuTooltip => 'Show menu';

  @override
  String get drawerLabel => 'Navigation menu';

  @override
  String get popupMenuLabel => 'Popup menu';

  @override
  String get dialogLabel => 'Dialog';

  @override
  String get alertDialogLabel => 'Alert';

  @override
  String get searchFieldLabel => 'Search';

  @override
  String aboutListTileTitle(String applicationName) => 'About $applicationName';

  @override
  String get licensesPageTitle => 'Licenses';

  @override
  String pageRowsInfoTitle(
      int firstRow, int lastRow, int rowCount, bool rowCountIsApproximate) {
    return rowCountIsApproximate
        ? '$firstRow–$lastRow of about $rowCount'
        : '$firstRow–$lastRow of $rowCount';
  }

  @override
  String get rowsPerPageTitle => 'Rows per page:';

  @override
  String tabLabel({int tabIndex, int tabCount}) {
    assert(tabIndex >= 1);
    assert(tabCount >= 1);
    return 'Tab $tabIndex of $tabCount';
  }

  @override
  String selectedRowCountTitle(int selectedRowCount) {
    switch (selectedRowCount) {
      case 0:
        return 'No items selected';
      case 1:
        return '1 item selected';
      default:
        return '$selectedRowCount items selected';
    }
  }

  @override
  String get cancelButtonLabel => 'CANCEL';

  @override
  String get closeButtonLabel => 'CLOSE';

  @override
  String get continueButtonLabel => 'CONTINUE';

  @override
  String get copyButtonLabel => 'COPY';

  @override
  String get cutButtonLabel => 'CUT';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get pasteButtonLabel => 'PASTE';

  @override
  String get selectAllButtonLabel => 'SELECT ALL';

  @override
  String get viewLicensesButtonLabel => 'VIEW LICENSES';

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get timePickerHourModeAnnouncement => 'Select hours';

  @override
  String get timePickerMinuteModeAnnouncement => 'Select minutes';

  @override
  String get modalBarrierDismissLabel => 'Dismiss';

  @override
  ScriptCategory get scriptCategory => ScriptCategory.englishLike;

  @override
  TimeOfDayFormat timeOfDayFormat({bool alwaysUse24HourFormat = false}) {
    return alwaysUse24HourFormat
        ? TimeOfDayFormat.HH_colon_mm
        : TimeOfDayFormat.h_colon_mm_space_a;
  }

  @override
  String get signedInLabel => 'Signed in';

  @override
  String get hideAccountsLabel => 'Hide accounts';

  @override
  String get showAccountsLabel => 'Show accounts';

  @override
  String get reorderItemUp => 'Move up';

  @override
  String get reorderItemDown => 'Move down';

  @override
  String get reorderItemLeft => 'Move left';

  @override
  String get reorderItemRight => 'Move right';

  @override
  String get reorderItemToEnd => 'Move to the end';

  @override
  String get reorderItemToStart => 'Move to the start';

  @override
  String get expandedIconTapHint => 'Collapse';

  @override
  String get collapsedIconTapHint => 'Expand';

  @override
  String get refreshIndicatorSemanticLabel => 'Refresh';

  static Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations());
  }

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _MaterialLocalizationsDelegate();

  @override
  String remainingTextFieldCharacterCount(int remaining) {
    switch (remaining) {
      case 0:
        return 'No characters remaining';
      case 1:
        return '1 character remaining';
      default:
        return '$remaining characters remaining';
    }
  }
}
