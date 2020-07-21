import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'date_picker.dart';

enum DatePickerDateTimeOrder {
  date_time_dayPeriod,

  date_dayPeriod_time,

  time_dayPeriod_date,

  dayPeriod_time_date,
}

enum DatePickerDateOrder {
  dmy,

  mdy,

  ymd,

  ydm,
}

abstract class CupertinoLocalizations {
  String datePickerYear(int yearIndex);

  String datePickerMonth(int monthIndex);

  String datePickerDayOfMonth(int dayIndex);

  String datePickerMediumDate(DateTime date);

  String datePickerHour(int hour);

  String datePickerHourSemanticsLabel(int hour);

  String datePickerMinute(int minute);

  String datePickerMinuteSemanticsLabel(int minute);

  DatePickerDateOrder get datePickerDateOrder;

  DatePickerDateTimeOrder get datePickerDateTimeOrder;

  String get anteMeridiemAbbreviation;

  String get postMeridiemAbbreviation;

  String get todayLabel;

  String get alertDialogLabel;

  String timerPickerHour(int hour);

  String timerPickerMinute(int minute);

  String timerPickerSecond(int second);

  String timerPickerHourLabel(int hour);

  String timerPickerMinuteLabel(int minute);

  String timerPickerSecondLabel(int second);

  String get cutButtonLabel;

  String get copyButtonLabel;

  String get pasteButtonLabel;

  String get selectAllButtonLabel;

  static CupertinoLocalizations of(BuildContext context) {
    return Localizations.of<CupertinoLocalizations>(
        context, CupertinoLocalizations);
  }
}

class _CupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_CupertinoLocalizationsDelegate old) => false;

  @override
  String toString() => 'DefaultCupertinoLocalizations.delegate(en_US)';
}

class DefaultCupertinoLocalizations implements CupertinoLocalizations {
  const DefaultCupertinoLocalizations();

  static const List<String> _shortWeekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
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
  String datePickerYear(int yearIndex) => yearIndex.toString();

  @override
  String datePickerMonth(int monthIndex) => _months[monthIndex - 1];

  @override
  String datePickerDayOfMonth(int dayIndex) => dayIndex.toString();

  @override
  String datePickerHour(int hour) => hour.toString();

  @override
  String datePickerHourSemanticsLabel(int hour) => hour.toString() + " o'clock";

  @override
  String datePickerMinute(int minute) => minute.toString().padLeft(2, '0');

  @override
  String datePickerMinuteSemanticsLabel(int minute) {
    if (minute == 1) return '1 minute';
    return minute.toString() + ' minutes';
  }

  @override
  String datePickerMediumDate(DateTime date) {
    return '${_shortWeekdays[date.weekday - DateTime.monday]} '
        '${_shortMonths[date.month - DateTime.january]} '
        '${date.day.toString().padRight(2)}';
  }

  @override
  DatePickerDateOrder get datePickerDateOrder => DatePickerDateOrder.mdy;

  @override
  DatePickerDateTimeOrder get datePickerDateTimeOrder =>
      DatePickerDateTimeOrder.date_time_dayPeriod;

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get todayLabel => 'Today';

  @override
  String get alertDialogLabel => 'Alert';

  @override
  String timerPickerHour(int hour) => hour.toString();

  @override
  String timerPickerMinute(int minute) => minute.toString();

  @override
  String timerPickerSecond(int second) => second.toString();

  @override
  String timerPickerHourLabel(int hour) => hour == 1 ? 'hour' : 'hours';

  @override
  String timerPickerMinuteLabel(int minute) => 'min.';

  @override
  String timerPickerSecondLabel(int second) => 'sec.';

  @override
  String get cutButtonLabel => 'Cut';

  @override
  String get copyButtonLabel => 'Copy';

  @override
  String get pasteButtonLabel => 'Paste';

  @override
  String get selectAllButtonLabel => 'Select All';

  static Future<CupertinoLocalizations> load(Locale locale) {
    return SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations());
  }

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _CupertinoLocalizationsDelegate();
}
