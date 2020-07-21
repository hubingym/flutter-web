import 'package:flutter_web/widgets.dart';
import 'package:meta/meta.dart';
import 'material_localizations.dart';

enum DayPeriod {
  am,

  pm,
}

@immutable
class TimeOfDay {
  static const int hoursPerDay = 24;

  static const int hoursPerPeriod = 12;

  static const int minutesPerHour = 60;

  const TimeOfDay({@required this.hour, @required this.minute});

  TimeOfDay.fromDateTime(DateTime time)
      : hour = time.hour,
        minute = time.minute;

  factory TimeOfDay.now() {
    return new TimeOfDay.fromDateTime(new DateTime.now());
  }

  TimeOfDay replacing({int hour, int minute}) {
    assert(hour == null || (hour >= 0 && hour < hoursPerDay));
    assert(minute == null || (minute >= 0 && minute < minutesPerHour));
    return new TimeOfDay(
        hour: hour ?? this.hour, minute: minute ?? this.minute);
  }

  final int hour;

  final int minute;

  DayPeriod get period => hour < hoursPerPeriod ? DayPeriod.am : DayPeriod.pm;

  int get hourOfPeriod => hour - periodOffset;

  int get periodOffset => period == DayPeriod.am ? 0 : hoursPerPeriod;

  String format(BuildContext context) {
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      this,
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! TimeOfDay) return false;
    final TimeOfDay typedOther = other;
    return typedOther.hour == hour && typedOther.minute == minute;
  }

  @override
  int get hashCode => hashValues(hour, minute);

  @override
  String toString() {
    String _addLeadingZeroIfNeeded(int value) {
      if (value < 10) return '0$value';
      return value.toString();
    }

    final String hourLabel = _addLeadingZeroIfNeeded(hour);
    final String minuteLabel = _addLeadingZeroIfNeeded(minute);

    return '$TimeOfDay($hourLabel:$minuteLabel)';
  }
}

enum TimeOfDayFormat {
  HH_colon_mm,

  HH_dot_mm,

  frenchCanadian,

  H_colon_mm,

  h_colon_mm_space_a,

  a_space_h_colon_mm,
}

enum HourFormat {
  HH,

  H,

  h,
}

HourFormat hourFormat({@required TimeOfDayFormat of}) {
  switch (of) {
    case TimeOfDayFormat.h_colon_mm_space_a:
    case TimeOfDayFormat.a_space_h_colon_mm:
      return HourFormat.h;
    case TimeOfDayFormat.H_colon_mm:
      return HourFormat.H;
    case TimeOfDayFormat.HH_dot_mm:
    case TimeOfDayFormat.HH_colon_mm:
    case TimeOfDayFormat.frenchCanadian:
      return HourFormat.HH;
  }

  return null;
}
