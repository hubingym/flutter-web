import 'dart:math' as math;

import 'package:flutter_web/scheduler.dart';
import 'package:flutter_web/widgets.dart';

import 'colors.dart';
import 'localizations.dart';
import 'picker.dart';
import 'theme.dart';

const double _kItemExtent = 32.0;
const double _kPickerWidth = 330.0;
const bool _kUseMagnifier = true;
const double _kMagnification = 1.08;
const double _kDatePickerPadSize = 12.0;

const double _kSqueeze = 1.25;

const Color _kBackgroundColor = CupertinoColors.white;

const TextStyle _kDefaultPickerTextStyle = TextStyle(
  letterSpacing: -0.83,
);

TextStyle _themeTextStyle(BuildContext context) {
  return CupertinoTheme.of(context).textTheme.dateTimePickerTextStyle;
}

class _DatePickerLayoutDelegate extends MultiChildLayoutDelegate {
  _DatePickerLayoutDelegate({
    @required this.columnWidths,
    @required this.textDirectionFactor,
  })  : assert(columnWidths != null),
        assert(textDirectionFactor != null);

  final List<double> columnWidths;

  final int textDirectionFactor;

  @override
  void performLayout(Size size) {
    double remainingWidth = size.width;

    for (int i = 0; i < columnWidths.length; i++)
      remainingWidth -= columnWidths[i] + _kDatePickerPadSize * 2;

    double currentHorizontalOffset = 0.0;

    for (int i = 0; i < columnWidths.length; i++) {
      final int index =
          textDirectionFactor == 1 ? i : columnWidths.length - i - 1;

      double childWidth = columnWidths[index] + _kDatePickerPadSize * 2;
      if (index == 0 || index == columnWidths.length - 1)
        childWidth += remainingWidth / 2;

      assert(() {
        if (childWidth < 0) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: FlutterError(
                'Insufficient horizontal space to render the '
                'CupertinoDatePicker because the parent is too narrow at '
                '${size.width}px.\n'
                'An additional ${-remainingWidth}px is needed to avoid '
                'overlapping columns.',
              ),
            ),
          );
        }
        return true;
      }());
      layoutChild(index,
          BoxConstraints.tight(Size(math.max(0.0, childWidth), size.height)));
      positionChild(index, Offset(currentHorizontalOffset, 0.0));

      currentHorizontalOffset += childWidth;
    }
  }

  @override
  bool shouldRelayout(_DatePickerLayoutDelegate oldDelegate) {
    return columnWidths != oldDelegate.columnWidths ||
        textDirectionFactor != oldDelegate.textDirectionFactor;
  }
}

enum CupertinoDatePickerMode {
  time,

  date,

  dateAndTime,
}

enum _PickerColumnType {
  dayOfMonth,

  month,

  year,

  date,

  hour,

  minute,

  dayPeriod,
}

class CupertinoDatePicker extends StatefulWidget {
  CupertinoDatePicker({
    this.mode = CupertinoDatePickerMode.dateAndTime,
    @required this.onDateTimeChanged,
    DateTime initialDateTime,
    this.minimumDate,
    this.maximumDate,
    this.minimumYear = 1,
    this.maximumYear,
    this.minuteInterval = 1,
    this.use24hFormat = false,
  })  : initialDateTime = initialDateTime ?? DateTime.now(),
        assert(mode != null),
        assert(onDateTimeChanged != null),
        assert(minimumYear != null),
        assert(
          minuteInterval > 0 && 60 % minuteInterval == 0,
          'minute interval is not a positive integer factor of 60',
        ) {
    assert(this.initialDateTime != null);
    assert(
      mode != CupertinoDatePickerMode.dateAndTime ||
          minimumDate == null ||
          !this.initialDateTime.isBefore(minimumDate),
      'initial date is before minimum date',
    );
    assert(
      mode != CupertinoDatePickerMode.dateAndTime ||
          maximumDate == null ||
          !this.initialDateTime.isAfter(maximumDate),
      'initial date is after maximum date',
    );
    assert(
      mode != CupertinoDatePickerMode.date ||
          (minimumYear >= 1 && this.initialDateTime.year >= minimumYear),
      'initial year is not greater than minimum year, or mininum year is not positive',
    );
    assert(
      mode != CupertinoDatePickerMode.date ||
          maximumYear == null ||
          this.initialDateTime.year <= maximumYear,
      'initial year is not smaller than maximum year',
    );
    assert(
      this.initialDateTime.minute % minuteInterval == 0,
      'initial minute is not divisible by minute interval',
    );
  }

  final CupertinoDatePickerMode mode;

  final DateTime initialDateTime;

  final DateTime minimumDate;

  final DateTime maximumDate;

  final int minimumYear;

  final int maximumYear;

  final int minuteInterval;

  final bool use24hFormat;

  final ValueChanged<DateTime> onDateTimeChanged;

  @override
  State<StatefulWidget> createState() {
    if (mode == CupertinoDatePickerMode.time ||
        mode == CupertinoDatePickerMode.dateAndTime)
      return _CupertinoDatePickerDateTimeState();
    else
      return _CupertinoDatePickerDateState();
  }

  static double _getColumnWidth(
    _PickerColumnType columnType,
    CupertinoLocalizations localizations,
    BuildContext context,
  ) {
    String longestText = '';

    switch (columnType) {
      case _PickerColumnType.date:
        for (int i = 1; i <= 12; i++) {
          final String date =
              localizations.datePickerMediumDate(DateTime(2018, i, 25));
          if (longestText.length < date.length) longestText = date;
        }
        break;
      case _PickerColumnType.hour:
        for (int i = 0; i < 24; i++) {
          final String hour = localizations.datePickerHour(i);
          if (longestText.length < hour.length) longestText = hour;
        }
        break;
      case _PickerColumnType.minute:
        for (int i = 0; i < 60; i++) {
          final String minute = localizations.datePickerMinute(i);
          if (longestText.length < minute.length) longestText = minute;
        }
        break;
      case _PickerColumnType.dayPeriod:
        longestText = localizations.anteMeridiemAbbreviation.length >
                localizations.postMeridiemAbbreviation.length
            ? localizations.anteMeridiemAbbreviation
            : localizations.postMeridiemAbbreviation;
        break;
      case _PickerColumnType.dayOfMonth:
        for (int i = 1; i <= 31; i++) {
          final String dayOfMonth = localizations.datePickerDayOfMonth(i);
          if (longestText.length < dayOfMonth.length) longestText = dayOfMonth;
        }
        break;
      case _PickerColumnType.month:
        for (int i = 1; i <= 12; i++) {
          final String month = localizations.datePickerMonth(i);
          if (longestText.length < month.length) longestText = month;
        }
        break;
      case _PickerColumnType.year:
        longestText = localizations.datePickerYear(2018);
        break;
    }

    assert(longestText != '', 'column type is not appropriate');

    final TextPainter painter = TextPainter(
      text: TextSpan(
        style: _themeTextStyle(context),
        text: longestText,
      ),
      textDirection: Directionality.of(context),
    );

    painter.layout();

    return painter.maxIntrinsicWidth;
  }
}

typedef _ColumnBuilder = Widget Function(
    double offAxisFraction, TransitionBuilder itemPositioningBuilder);

class _CupertinoDatePickerDateTimeState extends State<CupertinoDatePicker> {
  static const double _kMaximumOffAxisFraction = 0.45;

  int textDirectionFactor;
  CupertinoLocalizations localizations;

  Alignment alignCenterLeft;
  Alignment alignCenterRight;

  DateTime initialDateTime;

  int selectedDayFromInitial;

  int selectedHour;

  int previousHourIndex;

  int selectedMinute;

  int selectedAmPm;

  FixedExtentScrollController amPmController;

  final Map<int, double> estimatedColumnWidths = <int, double>{};

  @override
  void initState() {
    super.initState();
    initialDateTime = widget.initialDateTime;
    selectedDayFromInitial = 0;
    selectedHour = widget.initialDateTime.hour;
    selectedMinute = widget.initialDateTime.minute;
    selectedAmPm = 0;

    if (!widget.use24hFormat) {
      selectedAmPm = selectedHour ~/ 12;
      selectedHour = selectedHour % 12;
      if (selectedHour == 0) selectedHour = 12;

      amPmController = FixedExtentScrollController(initialItem: selectedAmPm);
    }

    previousHourIndex = selectedHour;
  }

  @override
  void didUpdateWidget(CupertinoDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    assert(
      oldWidget.mode == widget.mode,
      "The CupertinoDatePicker's mode cannot change once it's built",
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirectionFactor =
        Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    localizations = CupertinoLocalizations.of(context);

    alignCenterLeft =
        textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    alignCenterRight =
        textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;

    estimatedColumnWidths.clear();
  }

  double _getEstimatedColumnWidth(_PickerColumnType columnType) {
    if (estimatedColumnWidths[columnType.index] == null) {
      estimatedColumnWidths[columnType.index] =
          CupertinoDatePicker._getColumnWidth(
              columnType, localizations, context);
    }

    return estimatedColumnWidths[columnType.index];
  }

  DateTime _getDateTime() {
    final DateTime date = DateTime(
      initialDateTime.year,
      initialDateTime.month,
      initialDateTime.day,
    ).add(Duration(days: selectedDayFromInitial));

    return DateTime(
      date.year,
      date.month,
      date.day,
      widget.use24hFormat
          ? selectedHour
          : selectedHour % 12 + selectedAmPm * 12,
      selectedMinute,
    );
  }

  Widget _buildMediumDatePicker(
      double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker.builder(
      scrollController:
          FixedExtentScrollController(initialItem: selectedDayFromInitial),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        selectedDayFromInitial = index;
        widget.onDateTimeChanged(_getDateTime());
      },
      itemBuilder: (BuildContext context, int index) {
        final DateTime dateTime = DateTime(
          initialDateTime.year,
          initialDateTime.month,
          initialDateTime.day,
        ).add(Duration(days: index));

        if (widget.minimumDate != null && dateTime.isBefore(widget.minimumDate))
          return null;
        if (widget.maximumDate != null && dateTime.isAfter(widget.maximumDate))
          return null;

        final DateTime now = DateTime.now();
        String dateText;

        if (dateTime == DateTime(now.year, now.month, now.day)) {
          dateText = localizations.todayLabel;
        } else {
          dateText = localizations.datePickerMediumDate(dateTime);
        }

        return itemPositioningBuilder(
          context,
          Text(
            dateText,
            style: _themeTextStyle(context),
          ),
        );
      },
    );
  }

  Widget _buildHourPicker(
      double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: selectedHour),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        if (widget.use24hFormat) {
          selectedHour = index;
          widget.onDateTimeChanged(_getDateTime());
        } else {
          selectedHour = index % 12;

          final bool wasAm = previousHourIndex >= 0 && previousHourIndex <= 11;
          final bool isAm = index >= 0 && index <= 11;

          if (wasAm != isAm) {
            amPmController.animateToItem(
              1 - amPmController.selectedItem,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } else {
            widget.onDateTimeChanged(_getDateTime());
          }
        }

        previousHourIndex = index;
      },
      children: List<Widget>.generate(24, (int index) {
        int hour = index;
        if (!widget.use24hFormat) hour = hour % 12 == 0 ? 12 : hour % 12;

        return itemPositioningBuilder(
          context,
          Text(
            localizations.datePickerHour(hour),
            semanticsLabel: localizations.datePickerHourSemanticsLabel(hour),
            style: _themeTextStyle(context),
          ),
        );
      }),
      looping: true,
    );
  }

  Widget _buildMinutePicker(
      double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(
          initialItem: selectedMinute ~/ widget.minuteInterval),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        selectedMinute = index * widget.minuteInterval;
        widget.onDateTimeChanged(_getDateTime());
      },
      children: List<Widget>.generate(60 ~/ widget.minuteInterval, (int index) {
        final int minute = index * widget.minuteInterval;
        return itemPositioningBuilder(
          context,
          Text(
            localizations.datePickerMinute(minute),
            semanticsLabel:
                localizations.datePickerMinuteSemanticsLabel(minute),
            style: _themeTextStyle(context),
          ),
        );
      }),
      looping: true,
    );
  }

  Widget _buildAmPmPicker(
      double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController: amPmController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        selectedAmPm = index;
        widget.onDateTimeChanged(_getDateTime());
      },
      children: List<Widget>.generate(2, (int index) {
        return itemPositioningBuilder(
          context,
          Text(
            index == 0
                ? localizations.anteMeridiemAbbreviation
                : localizations.postMeridiemAbbreviation,
            style: _themeTextStyle(context),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<double> columnWidths = <double>[
      _getEstimatedColumnWidth(_PickerColumnType.hour),
      _getEstimatedColumnWidth(_PickerColumnType.minute),
    ];
    final List<_ColumnBuilder> pickerBuilders = <_ColumnBuilder>[
      _buildHourPicker,
      _buildMinutePicker,
    ];

    if (!widget.use24hFormat) {
      if (localizations.datePickerDateTimeOrder ==
              DatePickerDateTimeOrder.date_time_dayPeriod ||
          localizations.datePickerDateTimeOrder ==
              DatePickerDateTimeOrder.time_dayPeriod_date) {
        pickerBuilders.add(_buildAmPmPicker);
        columnWidths.add(_getEstimatedColumnWidth(_PickerColumnType.dayPeriod));
      } else {
        pickerBuilders.insert(0, _buildAmPmPicker);
        columnWidths.insert(
            0, _getEstimatedColumnWidth(_PickerColumnType.dayPeriod));
      }
    }

    if (widget.mode == CupertinoDatePickerMode.dateAndTime) {
      if (localizations.datePickerDateTimeOrder ==
              DatePickerDateTimeOrder.time_dayPeriod_date ||
          localizations.datePickerDateTimeOrder ==
              DatePickerDateTimeOrder.dayPeriod_time_date) {
        pickerBuilders.add(_buildMediumDatePicker);
        columnWidths.add(_getEstimatedColumnWidth(_PickerColumnType.date));
      } else {
        pickerBuilders.insert(0, _buildMediumDatePicker);
        columnWidths.insert(
            0, _getEstimatedColumnWidth(_PickerColumnType.date));
      }
    }

    final List<Widget> pickers = <Widget>[];

    for (int i = 0; i < columnWidths.length; i++) {
      double offAxisFraction = 0.0;
      if (i == 0)
        offAxisFraction = -_kMaximumOffAxisFraction * textDirectionFactor;
      else if (i >= 2 || columnWidths.length == 2)
        offAxisFraction = _kMaximumOffAxisFraction * textDirectionFactor;

      EdgeInsets padding = const EdgeInsets.only(right: _kDatePickerPadSize);
      if (i == columnWidths.length - 1) padding = padding.flipped;
      if (textDirectionFactor == -1) padding = padding.flipped;

      pickers.add(LayoutId(
        id: i,
        child: pickerBuilders[i](
          offAxisFraction,
          (BuildContext context, Widget child) {
            return Container(
              alignment: i == columnWidths.length - 1
                  ? alignCenterLeft
                  : alignCenterRight,
              padding: padding,
              child: Container(
                alignment: i == columnWidths.length - 1
                    ? alignCenterLeft
                    : alignCenterRight,
                width: i == 0 || i == columnWidths.length - 1
                    ? null
                    : columnWidths[i] + _kDatePickerPadSize,
                child: child,
              ),
            );
          },
        ),
      ));
    }

    return MediaQuery(
      data: const MediaQueryData(textScaleFactor: 1.0),
      child: DefaultTextStyle.merge(
        style: _kDefaultPickerTextStyle,
        child: CustomMultiChildLayout(
          delegate: _DatePickerLayoutDelegate(
            columnWidths: columnWidths,
            textDirectionFactor: textDirectionFactor,
          ),
          children: pickers,
        ),
      ),
    );
  }
}

class _CupertinoDatePickerDateState extends State<CupertinoDatePicker> {
  int textDirectionFactor;
  CupertinoLocalizations localizations;

  Alignment alignCenterLeft;
  Alignment alignCenterRight;

  int selectedDay;
  int selectedMonth;
  int selectedYear;

  FixedExtentScrollController dayController;

  Map<int, double> estimatedColumnWidths = <int, double>{};

  @override
  void initState() {
    super.initState();
    selectedDay = widget.initialDateTime.day;
    selectedMonth = widget.initialDateTime.month;
    selectedYear = widget.initialDateTime.year;

    dayController = FixedExtentScrollController(initialItem: selectedDay - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirectionFactor =
        Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    localizations = CupertinoLocalizations.of(context);

    alignCenterLeft =
        textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    alignCenterRight =
        textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;

    estimatedColumnWidths[_PickerColumnType.dayOfMonth.index] =
        CupertinoDatePicker._getColumnWidth(
            _PickerColumnType.dayOfMonth, localizations, context);
    estimatedColumnWidths[_PickerColumnType.month.index] =
        CupertinoDatePicker._getColumnWidth(
            _PickerColumnType.month, localizations, context);
    estimatedColumnWidths[_PickerColumnType.year.index] =
        CupertinoDatePicker._getColumnWidth(
            _PickerColumnType.year, localizations, context);
  }

  Widget _buildDayPicker(
      double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    final int daysInCurrentMonth =
        DateTime(selectedYear, (selectedMonth + 1) % 12, 0).day;
    return CupertinoPicker(
      scrollController: dayController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        selectedDay = index + 1;
        if (DateTime(selectedYear, selectedMonth, selectedDay).day ==
            selectedDay)
          widget.onDateTimeChanged(
              DateTime(selectedYear, selectedMonth, selectedDay));
      },
      children: List<Widget>.generate(31, (int index) {
        TextStyle textStyle = _themeTextStyle(context);
        if (index >= daysInCurrentMonth) {
          textStyle = textStyle.copyWith(color: CupertinoColors.inactiveGray);
        }
        return itemPositioningBuilder(
          context,
          Text(
            localizations.datePickerDayOfMonth(index + 1),
            style: textStyle,
          ),
        );
      }),
      looping: true,
    );
  }

  Widget _buildMonthPicker(
      double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController:
          FixedExtentScrollController(initialItem: selectedMonth - 1),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        selectedMonth = index + 1;
        if (DateTime(selectedYear, selectedMonth, selectedDay).day ==
            selectedDay)
          widget.onDateTimeChanged(
              DateTime(selectedYear, selectedMonth, selectedDay));
      },
      children: List<Widget>.generate(12, (int index) {
        return itemPositioningBuilder(
          context,
          Text(
            localizations.datePickerMonth(index + 1),
            style: _themeTextStyle(context),
          ),
        );
      }),
      looping: true,
    );
  }

  Widget _buildYearPicker(
      double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker.builder(
      scrollController: FixedExtentScrollController(initialItem: selectedYear),
      itemExtent: _kItemExtent,
      offAxisFraction: offAxisFraction,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        selectedYear = index;
        if (DateTime(selectedYear, selectedMonth, selectedDay).day ==
            selectedDay)
          widget.onDateTimeChanged(
              DateTime(selectedYear, selectedMonth, selectedDay));
      },
      itemBuilder: (BuildContext context, int index) {
        if (index < widget.minimumYear) return null;

        if (widget.maximumYear != null && index > widget.maximumYear)
          return null;

        return itemPositioningBuilder(
          context,
          Text(
            localizations.datePickerYear(index),
            style: _themeTextStyle(context),
          ),
        );
      },
    );
  }

  bool _keepInValidRange(ScrollEndNotification notification) {
    final int desiredDay =
        DateTime(selectedYear, selectedMonth, selectedDay).day;
    if (desiredDay != selectedDay) {
      SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
        dayController.animateToItem(
          dayController.selectedItem - desiredDay,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
    setState(() {});
    return false;
  }

  @override
  Widget build(BuildContext context) {
    List<_ColumnBuilder> pickerBuilders = <_ColumnBuilder>[];
    List<double> columnWidths = <double>[];

    switch (localizations.datePickerDateOrder) {
      case DatePickerDateOrder.mdy:
        pickerBuilders = <_ColumnBuilder>[
          _buildMonthPicker,
          _buildDayPicker,
          _buildYearPicker
        ];
        columnWidths = <double>[
          estimatedColumnWidths[_PickerColumnType.month.index],
          estimatedColumnWidths[_PickerColumnType.dayOfMonth.index],
          estimatedColumnWidths[_PickerColumnType.year.index]
        ];
        break;
      case DatePickerDateOrder.dmy:
        pickerBuilders = <_ColumnBuilder>[
          _buildDayPicker,
          _buildMonthPicker,
          _buildYearPicker
        ];
        columnWidths = <double>[
          estimatedColumnWidths[_PickerColumnType.dayOfMonth.index],
          estimatedColumnWidths[_PickerColumnType.month.index],
          estimatedColumnWidths[_PickerColumnType.year.index]
        ];
        break;
      case DatePickerDateOrder.ymd:
        pickerBuilders = <_ColumnBuilder>[
          _buildYearPicker,
          _buildMonthPicker,
          _buildDayPicker
        ];
        columnWidths = <double>[
          estimatedColumnWidths[_PickerColumnType.year.index],
          estimatedColumnWidths[_PickerColumnType.month.index],
          estimatedColumnWidths[_PickerColumnType.dayOfMonth.index]
        ];
        break;
      case DatePickerDateOrder.ydm:
        pickerBuilders = <_ColumnBuilder>[
          _buildYearPicker,
          _buildDayPicker,
          _buildMonthPicker
        ];
        columnWidths = <double>[
          estimatedColumnWidths[_PickerColumnType.year.index],
          estimatedColumnWidths[_PickerColumnType.dayOfMonth.index],
          estimatedColumnWidths[_PickerColumnType.month.index]
        ];
        break;
      default:
        assert(false, 'date order is not specified');
    }

    final List<Widget> pickers = <Widget>[];

    for (int i = 0; i < columnWidths.length; i++) {
      final double offAxisFraction = (i - 1) * 0.3 * textDirectionFactor;

      EdgeInsets padding = const EdgeInsets.only(right: _kDatePickerPadSize);
      if (textDirectionFactor == -1)
        padding = const EdgeInsets.only(left: _kDatePickerPadSize);

      pickers.add(LayoutId(
        id: i,
        child: pickerBuilders[i](
          offAxisFraction,
          (BuildContext context, Widget child) {
            return Container(
              alignment: i == columnWidths.length - 1
                  ? alignCenterLeft
                  : alignCenterRight,
              padding: i == 0 ? null : padding,
              child: Container(
                alignment: i == 0 ? alignCenterLeft : alignCenterRight,
                width: columnWidths[i] + _kDatePickerPadSize,
                child: child,
              ),
            );
          },
        ),
      ));
    }

    return MediaQuery(
      data: const MediaQueryData(textScaleFactor: 1.0),
      child: NotificationListener<ScrollEndNotification>(
        onNotification: _keepInValidRange,
        child: DefaultTextStyle.merge(
          style: _kDefaultPickerTextStyle,
          child: CustomMultiChildLayout(
            delegate: _DatePickerLayoutDelegate(
              columnWidths: columnWidths,
              textDirectionFactor: textDirectionFactor,
            ),
            children: pickers,
          ),
        ),
      ),
    );
  }
}

enum CupertinoTimerPickerMode {
  hm,

  ms,

  hms,
}

class CupertinoTimerPicker extends StatefulWidget {
  CupertinoTimerPicker({
    this.mode = CupertinoTimerPickerMode.hms,
    this.initialTimerDuration = Duration.zero,
    this.minuteInterval = 1,
    this.secondInterval = 1,
    @required this.onTimerDurationChanged,
  })  : assert(mode != null),
        assert(onTimerDurationChanged != null),
        assert(initialTimerDuration >= Duration.zero),
        assert(initialTimerDuration < const Duration(days: 1)),
        assert(minuteInterval > 0 && 60 % minuteInterval == 0),
        assert(secondInterval > 0 && 60 % secondInterval == 0),
        assert(initialTimerDuration.inMinutes % minuteInterval == 0),
        assert(initialTimerDuration.inSeconds % secondInterval == 0);

  final CupertinoTimerPickerMode mode;

  final Duration initialTimerDuration;

  final int minuteInterval;

  final int secondInterval;

  final ValueChanged<Duration> onTimerDurationChanged;

  @override
  State<StatefulWidget> createState() => _CupertinoTimerPickerState();
}

class _CupertinoTimerPickerState extends State<CupertinoTimerPicker> {
  int textDirectionFactor;
  CupertinoLocalizations localizations;

  Alignment alignCenterLeft;
  Alignment alignCenterRight;

  int selectedHour;
  int selectedMinute;
  int selectedSecond;

  @override
  void initState() {
    super.initState();

    selectedMinute = widget.initialTimerDuration.inMinutes % 60;

    if (widget.mode != CupertinoTimerPickerMode.ms)
      selectedHour = widget.initialTimerDuration.inHours;

    if (widget.mode != CupertinoTimerPickerMode.hm)
      selectedSecond = widget.initialTimerDuration.inSeconds % 60;
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      textScaleFactor: 0.9,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirectionFactor =
        Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    localizations = CupertinoLocalizations.of(context);

    alignCenterLeft =
        textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    alignCenterRight =
        textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;
  }

  Widget _buildHourPicker() {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: selectedHour),
      offAxisFraction: -0.5 * textDirectionFactor,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedHour = index;
          widget.onTimerDurationChanged(Duration(
              hours: selectedHour,
              minutes: selectedMinute,
              seconds: selectedSecond ?? 0));
        });
      },
      children: List<Widget>.generate(24, (int index) {
        final double hourLabelWidth = widget.mode == CupertinoTimerPickerMode.hm
            ? _kPickerWidth / 4
            : _kPickerWidth / 6;

        final String semanticsLabel = textDirectionFactor == 1
            ? localizations.timerPickerHour(index) +
                localizations.timerPickerHourLabel(index)
            : localizations.timerPickerHourLabel(index) +
                localizations.timerPickerHour(index);

        return Semantics(
          label: semanticsLabel,
          excludeSemantics: true,
          child: Container(
            alignment: alignCenterRight,
            padding: textDirectionFactor == 1
                ? EdgeInsets.only(right: hourLabelWidth)
                : EdgeInsets.only(left: hourLabelWidth),
            child: Container(
              alignment: alignCenterRight,
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(localizations.timerPickerHour(index)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHourColumn() {
    final Widget hourLabel = IgnorePointer(
      child: Container(
        alignment: alignCenterRight,
        child: Container(
          alignment: alignCenterLeft,
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          width: widget.mode == CupertinoTimerPickerMode.hm
              ? _kPickerWidth / 4
              : _kPickerWidth / 6,
          child: _buildLabel(localizations.timerPickerHourLabel(selectedHour)),
        ),
      ),
    );

    return Stack(
      children: <Widget>[
        _buildHourPicker(),
        hourLabel,
      ],
    );
  }

  Widget _buildMinutePicker() {
    double offAxisFraction;
    if (widget.mode == CupertinoTimerPickerMode.hm)
      offAxisFraction = 0.5 * textDirectionFactor;
    else if (widget.mode == CupertinoTimerPickerMode.hms)
      offAxisFraction = 0.0;
    else
      offAxisFraction = -0.5 * textDirectionFactor;

    return CupertinoPicker(
      scrollController: FixedExtentScrollController(
        initialItem: selectedMinute ~/ widget.minuteInterval,
      ),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedMinute = index * widget.minuteInterval;
          widget.onTimerDurationChanged(Duration(
              hours: selectedHour ?? 0,
              minutes: selectedMinute,
              seconds: selectedSecond ?? 0));
        });
      },
      children: List<Widget>.generate(60 ~/ widget.minuteInterval, (int index) {
        final int minute = index * widget.minuteInterval;

        final String semanticsLabel = textDirectionFactor == 1
            ? localizations.timerPickerMinute(minute) +
                localizations.timerPickerMinuteLabel(minute)
            : localizations.timerPickerMinuteLabel(minute) +
                localizations.timerPickerMinute(minute);

        if (widget.mode == CupertinoTimerPickerMode.ms) {
          return Semantics(
            label: semanticsLabel,
            excludeSemantics: true,
            child: Container(
              alignment: alignCenterRight,
              padding: textDirectionFactor == 1
                  ? const EdgeInsets.only(right: _kPickerWidth / 4)
                  : const EdgeInsets.only(left: _kPickerWidth / 4),
              child: Container(
                alignment: alignCenterRight,
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(localizations.timerPickerMinute(minute)),
              ),
            ),
          );
        } else {
          return Semantics(
            label: semanticsLabel,
            excludeSemantics: true,
            child: Container(
              alignment: alignCenterLeft,
              child: Container(
                alignment: alignCenterRight,
                width: widget.mode == CupertinoTimerPickerMode.hm
                    ? _kPickerWidth / 10
                    : _kPickerWidth / 6,
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(localizations.timerPickerMinute(minute)),
              ),
            ),
          );
        }
      }),
    );
  }

  Widget _buildMinuteColumn() {
    Widget minuteLabel;

    if (widget.mode == CupertinoTimerPickerMode.hm) {
      minuteLabel = IgnorePointer(
        child: Container(
          alignment: alignCenterLeft,
          padding: textDirectionFactor == 1
              ? const EdgeInsets.only(left: _kPickerWidth / 10)
              : const EdgeInsets.only(right: _kPickerWidth / 10),
          child: Container(
            alignment: alignCenterLeft,
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildLabel(
                localizations.timerPickerMinuteLabel(selectedMinute)),
          ),
        ),
      );
    } else {
      minuteLabel = IgnorePointer(
        child: Container(
          alignment: alignCenterRight,
          child: Container(
            alignment: alignCenterLeft,
            width: widget.mode == CupertinoTimerPickerMode.ms
                ? _kPickerWidth / 4
                : _kPickerWidth / 6,
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildLabel(
                localizations.timerPickerMinuteLabel(selectedMinute)),
          ),
        ),
      );
    }

    return Stack(
      children: <Widget>[
        _buildMinutePicker(),
        minuteLabel,
      ],
    );
  }

  Widget _buildSecondPicker() {
    final double offAxisFraction = 0.5 * textDirectionFactor;

    final double secondPickerWidth = widget.mode == CupertinoTimerPickerMode.ms
        ? _kPickerWidth / 10
        : _kPickerWidth / 6;

    return CupertinoPicker(
      scrollController: FixedExtentScrollController(
        initialItem: selectedSecond ~/ widget.secondInterval,
      ),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedSecond = index * widget.secondInterval;
          widget.onTimerDurationChanged(Duration(
              hours: selectedHour ?? 0,
              minutes: selectedMinute,
              seconds: selectedSecond));
        });
      },
      children: List<Widget>.generate(60 ~/ widget.secondInterval, (int index) {
        final int second = index * widget.secondInterval;

        final String semanticsLabel = textDirectionFactor == 1
            ? localizations.timerPickerSecond(second) +
                localizations.timerPickerSecondLabel(second)
            : localizations.timerPickerSecondLabel(second) +
                localizations.timerPickerSecond(second);

        return Semantics(
          label: semanticsLabel,
          excludeSemantics: true,
          child: Container(
            alignment: alignCenterLeft,
            child: Container(
              alignment: alignCenterRight,
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              width: secondPickerWidth,
              child: Text(localizations.timerPickerSecond(second)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSecondColumn() {
    final double secondPickerWidth = widget.mode == CupertinoTimerPickerMode.ms
        ? _kPickerWidth / 10
        : _kPickerWidth / 6;

    final Widget secondLabel = IgnorePointer(
      child: Container(
        alignment: alignCenterLeft,
        padding: textDirectionFactor == 1
            ? EdgeInsets.only(left: secondPickerWidth)
            : EdgeInsets.only(right: secondPickerWidth),
        child: Container(
          alignment: alignCenterLeft,
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child:
              _buildLabel(localizations.timerPickerSecondLabel(selectedSecond)),
        ),
      ),
    );
    return Stack(
      children: <Widget>[
        _buildSecondPicker(),
        secondLabel,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget picker;

    if (widget.mode == CupertinoTimerPickerMode.hm) {
      picker = Row(
        children: <Widget>[
          Expanded(child: _buildHourColumn()),
          Expanded(child: _buildMinuteColumn()),
        ],
      );
    } else if (widget.mode == CupertinoTimerPickerMode.ms) {
      picker = Row(
        children: <Widget>[
          Expanded(child: _buildMinuteColumn()),
          Expanded(child: _buildSecondColumn()),
        ],
      );
    } else {
      picker = Row(
        children: <Widget>[
          Expanded(child: _buildHourColumn()),
          Container(
            width: _kPickerWidth / 3,
            child: _buildMinuteColumn(),
          ),
          Expanded(child: _buildSecondColumn()),
        ],
      );
    }

    return MediaQuery(
      data: const MediaQueryData(
        textScaleFactor: 1.0,
      ),
      child: picker,
    );
  }
}
