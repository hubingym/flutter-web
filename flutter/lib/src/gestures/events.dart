import 'package:flutter_web/ui.dart' show Offset, PointerDeviceKind;

import 'package:flutter_web/foundation.dart';

import 'package:vector_math/vector_math_64.dart';

export 'package:flutter_web/ui.dart' show Offset, PointerDeviceKind;

const int kPrimaryButton = 0x01;

const int kSecondaryButton = 0x02;

const int kPrimaryMouseButton = kPrimaryButton;

const int kSecondaryMouseButton = kSecondaryButton;

const int kStylusContact = kPrimaryButton;

const int kPrimaryStylusButton = kSecondaryButton;

const int kMiddleMouseButton = 0x04;

const int kSecondaryStylusButton = 0x04;

const int kBackMouseButton = 0x08;

const int kForwardMouseButton = 0x10;

const int kTouchContact = kPrimaryButton;

int nthMouseButton(int number) =>
    (kPrimaryMouseButton << (number - 1)) & kMaxUnsignedSMI;

int nthStylusButton(int number) =>
    (kPrimaryStylusButton << (number - 1)) & kMaxUnsignedSMI;

int smallestButton(int buttons) => buttons & (-buttons);

bool isSingleButton(int buttons) =>
    buttons != 0 && (smallestButton(buttons) == buttons);

@immutable
abstract class PointerEvent extends Diagnosticable {
  const PointerEvent({
    this.timeStamp = Duration.zero,
    this.pointer = 0,
    this.kind = PointerDeviceKind.touch,
    this.device = 0,
    this.position = Offset.zero,
    Offset localPosition,
    this.delta = Offset.zero,
    Offset localDelta,
    this.buttons = 0,
    this.down = false,
    this.obscured = false,
    this.pressure = 1.0,
    this.pressureMin = 1.0,
    this.pressureMax = 1.0,
    this.distance = 0.0,
    this.distanceMax = 0.0,
    this.size = 0.0,
    this.radiusMajor = 0.0,
    this.radiusMinor = 0.0,
    this.radiusMin = 0.0,
    this.radiusMax = 0.0,
    this.orientation = 0.0,
    this.tilt = 0.0,
    this.platformData = 0,
    this.synthesized = false,
    this.transform,
    this.original,
  })  : localPosition = localPosition ?? position,
        localDelta = localDelta ?? delta;

  final Duration timeStamp;

  final int pointer;

  final PointerDeviceKind kind;

  final int device;

  final Offset position;

  final Offset localPosition;

  final Offset delta;

  final Offset localDelta;

  final int buttons;

  final bool down;

  final bool obscured;

  final double pressure;

  final double pressureMin;

  final double pressureMax;

  final double distance;

  double get distanceMin => 0.0;

  final double distanceMax;

  final double size;

  final double radiusMajor;

  final double radiusMinor;

  final double radiusMin;

  final double radiusMax;

  final double orientation;

  final double tilt;

  final int platformData;

  final bool synthesized;

  final Matrix4 transform;

  final PointerEvent original;

  PointerEvent transformed(Matrix4 transform);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('position', position));
    properties.add(DiagnosticsProperty<Offset>('localPosition', localPosition,
        defaultValue: position, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<Offset>('delta', delta,
        defaultValue: Offset.zero, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<Offset>('localDelta', localDelta,
        defaultValue: delta, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<Duration>('timeStamp', timeStamp,
        defaultValue: Duration.zero, level: DiagnosticLevel.debug));
    properties
        .add(IntProperty('pointer', pointer, level: DiagnosticLevel.debug));
    properties.add(EnumProperty<PointerDeviceKind>('kind', kind,
        level: DiagnosticLevel.debug));
    properties.add(IntProperty('device', device,
        defaultValue: 0, level: DiagnosticLevel.debug));
    properties.add(IntProperty('buttons', buttons,
        defaultValue: 0, level: DiagnosticLevel.debug));
    properties.add(
        DiagnosticsProperty<bool>('down', down, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('pressure', pressure,
        defaultValue: 1.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('pressureMin', pressureMin,
        defaultValue: 1.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('pressureMax', pressureMax,
        defaultValue: 1.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('distance', distance,
        defaultValue: 0.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('distanceMin', distanceMin,
        defaultValue: 0.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('distanceMax', distanceMax,
        defaultValue: 0.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('size', size,
        defaultValue: 0.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('radiusMajor', radiusMajor,
        defaultValue: 0.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('radiusMinor', radiusMinor,
        defaultValue: 0.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('radiusMin', radiusMin,
        defaultValue: 0.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('radiusMax', radiusMax,
        defaultValue: 0.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('orientation', orientation,
        defaultValue: 0.0, level: DiagnosticLevel.debug));
    properties.add(DoubleProperty('tilt', tilt,
        defaultValue: 0.0, level: DiagnosticLevel.debug));
    properties.add(IntProperty('platformData', platformData,
        defaultValue: 0, level: DiagnosticLevel.debug));
    properties.add(FlagProperty('obscured',
        value: obscured, ifTrue: 'obscured', level: DiagnosticLevel.debug));
    properties.add(FlagProperty('synthesized',
        value: synthesized,
        ifTrue: 'synthesized',
        level: DiagnosticLevel.debug));
  }

  String toStringFull() {
    return toString(minLevel: DiagnosticLevel.fine);
  }

  static Offset transformPosition(Matrix4 transform, Offset position) {
    if (transform == null) {
      return position;
    }
    final Vector3 position3 = Vector3(position.dx, position.dy, 0.0);
    final Vector3 transformed3 = transform.perspectiveTransform(position3);
    return Offset(transformed3.x, transformed3.y);
  }

  static Offset transformDeltaViaPositions({
    @required Offset untransformedEndPosition,
    Offset transformedEndPosition,
    @required Offset untransformedDelta,
    @required Matrix4 transform,
  }) {
    if (transform == null) {
      return untransformedDelta;
    }

    transformedEndPosition ??=
        transformPosition(transform, untransformedEndPosition);
    final Offset transformedStartPosition = transformPosition(
        transform, untransformedEndPosition - untransformedDelta);
    return transformedEndPosition - transformedStartPosition;
  }

  static Matrix4 removePerspectiveTransform(Matrix4 transform) {
    final Vector4 vector = Vector4(0, 0, 1, 0);
    return transform.clone()
      ..setColumn(2, vector)
      ..setRow(2, vector);
  }
}

class PointerAddedEvent extends PointerEvent {
  const PointerAddedEvent({
    Duration timeStamp = Duration.zero,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int device = 0,
    Offset position = Offset.zero,
    Offset localPosition,
    bool obscured = false,
    double pressureMin = 1.0,
    double pressureMax = 1.0,
    double distance = 0.0,
    double distanceMax = 0.0,
    double radiusMin = 0.0,
    double radiusMax = 0.0,
    double orientation = 0.0,
    double tilt = 0.0,
    Matrix4 transform,
    PointerAddedEvent original,
  }) : super(
          timeStamp: timeStamp,
          kind: kind,
          device: device,
          position: position,
          localPosition: localPosition,
          obscured: obscured,
          pressure: 0.0,
          pressureMin: pressureMin,
          pressureMax: pressureMax,
          distance: distance,
          distanceMax: distanceMax,
          radiusMin: radiusMin,
          radiusMax: radiusMax,
          orientation: orientation,
          tilt: tilt,
          transform: transform,
          original: original,
        );

  @override
  PointerAddedEvent transformed(Matrix4 transform) {
    if (transform == null || transform == this.transform) {
      return this;
    }
    return PointerAddedEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: device,
      position: position,
      localPosition: PointerEvent.transformPosition(transform, position),
      obscured: obscured,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
      distance: distance,
      distanceMax: distanceMax,
      radiusMin: radiusMin,
      radiusMax: radiusMax,
      orientation: orientation,
      tilt: tilt,
      transform: transform,
      original: original ?? this,
    );
  }
}

class PointerRemovedEvent extends PointerEvent {
  const PointerRemovedEvent({
    Duration timeStamp = Duration.zero,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int device = 0,
    Offset position = Offset.zero,
    Offset localPosition,
    bool obscured = false,
    double pressureMin = 1.0,
    double pressureMax = 1.0,
    double distanceMax = 0.0,
    double radiusMin = 0.0,
    double radiusMax = 0.0,
    Matrix4 transform,
    PointerRemovedEvent original,
  }) : super(
          timeStamp: timeStamp,
          kind: kind,
          device: device,
          position: position,
          localPosition: localPosition,
          obscured: obscured,
          pressure: 0.0,
          pressureMin: pressureMin,
          pressureMax: pressureMax,
          distanceMax: distanceMax,
          radiusMin: radiusMin,
          radiusMax: radiusMax,
          transform: transform,
          original: original,
        );

  @override
  PointerRemovedEvent transformed(Matrix4 transform) {
    if (transform == null || transform == this.transform) {
      return this;
    }
    return PointerRemovedEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: device,
      position: position,
      localPosition: PointerEvent.transformPosition(transform, position),
      obscured: obscured,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
      distanceMax: distanceMax,
      radiusMin: radiusMin,
      radiusMax: radiusMax,
      transform: transform,
      original: original ?? this,
    );
  }
}

class PointerHoverEvent extends PointerEvent {
  const PointerHoverEvent({
    Duration timeStamp = Duration.zero,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int device = 0,
    Offset position = Offset.zero,
    Offset localPosition,
    Offset delta = Offset.zero,
    Offset localDelta,
    int buttons = 0,
    bool obscured = false,
    double pressureMin = 1.0,
    double pressureMax = 1.0,
    double distance = 0.0,
    double distanceMax = 0.0,
    double size = 0.0,
    double radiusMajor = 0.0,
    double radiusMinor = 0.0,
    double radiusMin = 0.0,
    double radiusMax = 0.0,
    double orientation = 0.0,
    double tilt = 0.0,
    bool synthesized = false,
    Matrix4 transform,
    PointerHoverEvent original,
  }) : super(
          timeStamp: timeStamp,
          kind: kind,
          device: device,
          position: position,
          localPosition: localPosition,
          delta: delta,
          localDelta: localDelta,
          buttons: buttons,
          down: false,
          obscured: obscured,
          pressure: 0.0,
          pressureMin: pressureMin,
          pressureMax: pressureMax,
          distance: distance,
          distanceMax: distanceMax,
          size: size,
          radiusMajor: radiusMajor,
          radiusMinor: radiusMinor,
          radiusMin: radiusMin,
          radiusMax: radiusMax,
          orientation: orientation,
          tilt: tilt,
          synthesized: synthesized,
          transform: transform,
          original: original,
        );

  @override
  PointerHoverEvent transformed(Matrix4 transform) {
    if (transform == null || transform == this.transform) {
      return this;
    }
    final Offset transformedPosition =
        PointerEvent.transformPosition(transform, position);
    return PointerHoverEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: device,
      position: position,
      localPosition: transformedPosition,
      delta: delta,
      localDelta: PointerEvent.transformDeltaViaPositions(
        transform: transform,
        untransformedDelta: delta,
        untransformedEndPosition: position,
        transformedEndPosition: transformedPosition,
      ),
      buttons: buttons,
      obscured: obscured,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
      distance: distance,
      distanceMax: distanceMax,
      size: size,
      radiusMajor: radiusMajor,
      radiusMinor: radiusMinor,
      radiusMin: radiusMin,
      radiusMax: radiusMax,
      orientation: orientation,
      tilt: tilt,
      synthesized: synthesized,
      transform: transform,
      original: original ?? this,
    );
  }
}

class PointerEnterEvent extends PointerEvent {
  const PointerEnterEvent({
    Duration timeStamp = Duration.zero,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int device = 0,
    Offset position = Offset.zero,
    Offset localPosition,
    Offset delta = Offset.zero,
    Offset localDelta,
    int buttons = 0,
    bool obscured = false,
    double pressureMin = 1.0,
    double pressureMax = 1.0,
    double distance = 0.0,
    double distanceMax = 0.0,
    double size = 0.0,
    double radiusMajor = 0.0,
    double radiusMinor = 0.0,
    double radiusMin = 0.0,
    double radiusMax = 0.0,
    double orientation = 0.0,
    double tilt = 0.0,
    bool synthesized = false,
    Matrix4 transform,
    PointerEnterEvent original,
  }) : super(
          timeStamp: timeStamp,
          kind: kind,
          device: device,
          position: position,
          localPosition: localPosition,
          delta: delta,
          localDelta: localDelta,
          buttons: buttons,
          down: false,
          obscured: obscured,
          pressure: 0.0,
          pressureMin: pressureMin,
          pressureMax: pressureMax,
          distance: distance,
          distanceMax: distanceMax,
          size: size,
          radiusMajor: radiusMajor,
          radiusMinor: radiusMinor,
          radiusMin: radiusMin,
          radiusMax: radiusMax,
          orientation: orientation,
          tilt: tilt,
          synthesized: synthesized,
          transform: transform,
          original: original,
        );

  @Deprecated('use PointerEnterEvent.fromMouseEvent instead')
  PointerEnterEvent.fromHoverEvent(PointerHoverEvent event)
      : this.fromMouseEvent(event);

  PointerEnterEvent.fromMouseEvent(PointerEvent event)
      : this(
          timeStamp: event?.timeStamp,
          kind: event?.kind,
          device: event?.device,
          position: event?.position,
          localPosition: event?.localPosition,
          delta: event?.delta,
          localDelta: event?.localDelta,
          buttons: event?.buttons,
          obscured: event?.obscured,
          pressureMin: event?.pressureMin,
          pressureMax: event?.pressureMax,
          distance: event?.distance,
          distanceMax: event?.distanceMax,
          size: event?.size,
          radiusMajor: event?.radiusMajor,
          radiusMinor: event?.radiusMinor,
          radiusMin: event?.radiusMin,
          radiusMax: event?.radiusMax,
          orientation: event?.orientation,
          tilt: event?.tilt,
          synthesized: event?.synthesized,
          transform: event?.transform,
          original: event?.original,
        );

  @override
  PointerEnterEvent transformed(Matrix4 transform) {
    if (transform == null || transform == this.transform) {
      return this;
    }
    final Offset transformedPosition =
        PointerEvent.transformPosition(transform, position);
    return PointerEnterEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: device,
      position: position,
      localPosition: transformedPosition,
      delta: delta,
      localDelta: PointerEvent.transformDeltaViaPositions(
        transform: transform,
        untransformedDelta: delta,
        untransformedEndPosition: position,
        transformedEndPosition: transformedPosition,
      ),
      buttons: buttons,
      obscured: obscured,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
      distance: distance,
      distanceMax: distanceMax,
      size: size,
      radiusMajor: radiusMajor,
      radiusMinor: radiusMinor,
      radiusMin: radiusMin,
      radiusMax: radiusMax,
      orientation: orientation,
      tilt: tilt,
      synthesized: synthesized,
      transform: transform,
      original: original ?? this,
    );
  }
}

class PointerExitEvent extends PointerEvent {
  const PointerExitEvent({
    Duration timeStamp = Duration.zero,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int device = 0,
    Offset position = Offset.zero,
    Offset localPosition,
    Offset delta = Offset.zero,
    Offset localDelta,
    int buttons = 0,
    bool obscured = false,
    double pressureMin = 1.0,
    double pressureMax = 1.0,
    double distance = 0.0,
    double distanceMax = 0.0,
    double size = 0.0,
    double radiusMajor = 0.0,
    double radiusMinor = 0.0,
    double radiusMin = 0.0,
    double radiusMax = 0.0,
    double orientation = 0.0,
    double tilt = 0.0,
    bool synthesized = false,
    Matrix4 transform,
    PointerExitEvent original,
  }) : super(
          timeStamp: timeStamp,
          kind: kind,
          device: device,
          position: position,
          localPosition: localPosition,
          delta: delta,
          localDelta: localDelta,
          buttons: buttons,
          down: false,
          obscured: obscured,
          pressure: 0.0,
          pressureMin: pressureMin,
          pressureMax: pressureMax,
          distance: distance,
          distanceMax: distanceMax,
          size: size,
          radiusMajor: radiusMajor,
          radiusMinor: radiusMinor,
          radiusMin: radiusMin,
          radiusMax: radiusMax,
          orientation: orientation,
          tilt: tilt,
          synthesized: synthesized,
          transform: transform,
          original: original,
        );

  @Deprecated('use PointerExitEvent.fromMouseEvent instead')
  PointerExitEvent.fromHoverEvent(PointerHoverEvent event)
      : this.fromMouseEvent(event);

  PointerExitEvent.fromMouseEvent(PointerEvent event)
      : this(
          timeStamp: event?.timeStamp,
          kind: event?.kind,
          device: event?.device,
          position: event?.position,
          localPosition: event?.localPosition,
          delta: event?.delta,
          localDelta: event?.localDelta,
          buttons: event?.buttons,
          obscured: event?.obscured,
          pressureMin: event?.pressureMin,
          pressureMax: event?.pressureMax,
          distance: event?.distance,
          distanceMax: event?.distanceMax,
          size: event?.size,
          radiusMajor: event?.radiusMajor,
          radiusMinor: event?.radiusMinor,
          radiusMin: event?.radiusMin,
          radiusMax: event?.radiusMax,
          orientation: event?.orientation,
          tilt: event?.tilt,
          synthesized: event?.synthesized,
          transform: event?.transform,
          original: event?.original,
        );

  @override
  PointerExitEvent transformed(Matrix4 transform) {
    if (transform == null || transform == this.transform) {
      return this;
    }
    final Offset transformedPosition =
        PointerEvent.transformPosition(transform, position);
    return PointerExitEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: device,
      position: position,
      localPosition: transformedPosition,
      delta: delta,
      localDelta: PointerEvent.transformDeltaViaPositions(
        transform: transform,
        untransformedDelta: delta,
        untransformedEndPosition: position,
        transformedEndPosition: transformedPosition,
      ),
      buttons: buttons,
      obscured: obscured,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
      distance: distance,
      distanceMax: distanceMax,
      size: size,
      radiusMajor: radiusMajor,
      radiusMinor: radiusMinor,
      radiusMin: radiusMin,
      radiusMax: radiusMax,
      orientation: orientation,
      tilt: tilt,
      synthesized: synthesized,
      transform: transform,
      original: original ?? this,
    );
  }
}

class PointerDownEvent extends PointerEvent {
  const PointerDownEvent({
    Duration timeStamp = Duration.zero,
    int pointer = 0,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int device = 0,
    Offset position = Offset.zero,
    Offset localPosition,
    int buttons = kPrimaryButton,
    bool obscured = false,
    double pressure = 1.0,
    double pressureMin = 1.0,
    double pressureMax = 1.0,
    double distanceMax = 0.0,
    double size = 0.0,
    double radiusMajor = 0.0,
    double radiusMinor = 0.0,
    double radiusMin = 0.0,
    double radiusMax = 0.0,
    double orientation = 0.0,
    double tilt = 0.0,
    Matrix4 transform,
    PointerDownEvent original,
  }) : super(
          timeStamp: timeStamp,
          pointer: pointer,
          kind: kind,
          device: device,
          position: position,
          localPosition: localPosition,
          buttons: buttons,
          down: true,
          obscured: obscured,
          pressure: pressure,
          pressureMin: pressureMin,
          pressureMax: pressureMax,
          distance: 0.0,
          distanceMax: distanceMax,
          size: size,
          radiusMajor: radiusMajor,
          radiusMinor: radiusMinor,
          radiusMin: radiusMin,
          radiusMax: radiusMax,
          orientation: orientation,
          tilt: tilt,
          transform: transform,
          original: original,
        );

  @override
  PointerDownEvent transformed(Matrix4 transform) {
    if (transform == null || transform == this.transform) {
      return this;
    }
    return PointerDownEvent(
      timeStamp: timeStamp,
      pointer: pointer,
      kind: kind,
      device: device,
      position: position,
      localPosition: PointerEvent.transformPosition(transform, position),
      buttons: buttons,
      obscured: obscured,
      pressure: pressure,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
      distanceMax: distanceMax,
      size: size,
      radiusMajor: radiusMajor,
      radiusMinor: radiusMinor,
      radiusMin: radiusMin,
      radiusMax: radiusMax,
      orientation: orientation,
      tilt: tilt,
      transform: transform,
      original: original ?? this,
    );
  }
}

class PointerMoveEvent extends PointerEvent {
  const PointerMoveEvent({
    Duration timeStamp = Duration.zero,
    int pointer = 0,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int device = 0,
    Offset position = Offset.zero,
    Offset localPosition,
    Offset delta = Offset.zero,
    Offset localDelta,
    int buttons = kPrimaryButton,
    bool obscured = false,
    double pressure = 1.0,
    double pressureMin = 1.0,
    double pressureMax = 1.0,
    double distanceMax = 0.0,
    double size = 0.0,
    double radiusMajor = 0.0,
    double radiusMinor = 0.0,
    double radiusMin = 0.0,
    double radiusMax = 0.0,
    double orientation = 0.0,
    double tilt = 0.0,
    int platformData = 0,
    bool synthesized = false,
    Matrix4 transform,
    PointerMoveEvent original,
  }) : super(
          timeStamp: timeStamp,
          pointer: pointer,
          kind: kind,
          device: device,
          position: position,
          localPosition: localPosition,
          delta: delta,
          localDelta: localDelta,
          buttons: buttons,
          down: true,
          obscured: obscured,
          pressure: pressure,
          pressureMin: pressureMin,
          pressureMax: pressureMax,
          distance: 0.0,
          distanceMax: distanceMax,
          size: size,
          radiusMajor: radiusMajor,
          radiusMinor: radiusMinor,
          radiusMin: radiusMin,
          radiusMax: radiusMax,
          orientation: orientation,
          tilt: tilt,
          platformData: platformData,
          synthesized: synthesized,
          transform: transform,
          original: original,
        );

  @override
  PointerMoveEvent transformed(Matrix4 transform) {
    if (transform == null || transform == this.transform) {
      return this;
    }
    final Offset transformedPosition =
        PointerEvent.transformPosition(transform, position);

    return PointerMoveEvent(
      timeStamp: timeStamp,
      pointer: pointer,
      kind: kind,
      device: device,
      position: position,
      localPosition: transformedPosition,
      delta: delta,
      localDelta: PointerEvent.transformDeltaViaPositions(
        transform: transform,
        untransformedDelta: delta,
        untransformedEndPosition: position,
        transformedEndPosition: transformedPosition,
      ),
      buttons: buttons,
      obscured: obscured,
      pressure: pressure,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
      distanceMax: distanceMax,
      size: size,
      radiusMajor: radiusMajor,
      radiusMinor: radiusMinor,
      radiusMin: radiusMin,
      radiusMax: radiusMax,
      orientation: orientation,
      tilt: tilt,
      platformData: platformData,
      synthesized: synthesized,
      transform: transform,
      original: original ?? this,
    );
  }
}

class PointerUpEvent extends PointerEvent {
  const PointerUpEvent({
    Duration timeStamp = Duration.zero,
    int pointer = 0,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int device = 0,
    Offset position = Offset.zero,
    Offset localPosition,
    int buttons = 0,
    bool obscured = false,
    double pressure = 0.0,
    double pressureMin = 1.0,
    double pressureMax = 1.0,
    double distance = 0.0,
    double distanceMax = 0.0,
    double size = 0.0,
    double radiusMajor = 0.0,
    double radiusMinor = 0.0,
    double radiusMin = 0.0,
    double radiusMax = 0.0,
    double orientation = 0.0,
    double tilt = 0.0,
    Matrix4 transform,
    PointerUpEvent original,
  }) : super(
          timeStamp: timeStamp,
          pointer: pointer,
          kind: kind,
          device: device,
          position: position,
          localPosition: localPosition,
          buttons: buttons,
          down: false,
          obscured: obscured,
          pressure: pressure,
          pressureMin: pressureMin,
          pressureMax: pressureMax,
          distance: distance,
          distanceMax: distanceMax,
          size: size,
          radiusMajor: radiusMajor,
          radiusMinor: radiusMinor,
          radiusMin: radiusMin,
          radiusMax: radiusMax,
          orientation: orientation,
          tilt: tilt,
          transform: transform,
          original: original,
        );

  @override
  PointerUpEvent transformed(Matrix4 transform) {
    if (transform == null || transform == this.transform) {
      return this;
    }
    return PointerUpEvent(
      timeStamp: timeStamp,
      pointer: pointer,
      kind: kind,
      device: device,
      position: position,
      localPosition: PointerEvent.transformPosition(transform, position),
      buttons: buttons,
      obscured: obscured,
      pressure: pressure,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
      distance: distance,
      distanceMax: distanceMax,
      size: size,
      radiusMajor: radiusMajor,
      radiusMinor: radiusMinor,
      radiusMin: radiusMin,
      radiusMax: radiusMax,
      orientation: orientation,
      tilt: tilt,
      transform: transform,
      original: original ?? this,
    );
  }
}

abstract class PointerSignalEvent extends PointerEvent {
  const PointerSignalEvent({
    Duration timeStamp = Duration.zero,
    int pointer = 0,
    PointerDeviceKind kind = PointerDeviceKind.mouse,
    int device = 0,
    Offset position = Offset.zero,
    Offset localPosition,
    Matrix4 transform,
    PointerSignalEvent original,
  }) : super(
          timeStamp: timeStamp,
          pointer: pointer,
          kind: kind,
          device: device,
          position: position,
          localPosition: localPosition,
          transform: transform,
          original: original,
        );
}

class PointerScrollEvent extends PointerSignalEvent {
  const PointerScrollEvent({
    Duration timeStamp = Duration.zero,
    PointerDeviceKind kind = PointerDeviceKind.mouse,
    int device = 0,
    Offset position = Offset.zero,
    Offset localPosition,
    this.scrollDelta = Offset.zero,
    Matrix4 transform,
    PointerScrollEvent original,
  })  : assert(timeStamp != null),
        assert(kind != null),
        assert(device != null),
        assert(position != null),
        assert(scrollDelta != null),
        super(
          timeStamp: timeStamp,
          kind: kind,
          device: device,
          position: position,
          localPosition: localPosition,
          transform: transform,
          original: original,
        );

  final Offset scrollDelta;

  @override
  PointerScrollEvent transformed(Matrix4 transform) {
    if (transform == null || transform == this.transform) {
      return this;
    }
    return PointerScrollEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: device,
      position: position,
      localPosition: PointerEvent.transformPosition(transform, position),
      scrollDelta: scrollDelta,
      transform: transform,
      original: original ?? this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('scrollDelta', scrollDelta));
  }
}

class PointerCancelEvent extends PointerEvent {
  const PointerCancelEvent({
    Duration timeStamp = Duration.zero,
    int pointer = 0,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int device = 0,
    Offset position = Offset.zero,
    Offset localPosition,
    int buttons = 0,
    bool obscured = false,
    double pressureMin = 1.0,
    double pressureMax = 1.0,
    double distance = 0.0,
    double distanceMax = 0.0,
    double size = 0.0,
    double radiusMajor = 0.0,
    double radiusMinor = 0.0,
    double radiusMin = 0.0,
    double radiusMax = 0.0,
    double orientation = 0.0,
    double tilt = 0.0,
    Matrix4 transform,
    PointerCancelEvent original,
  }) : super(
          timeStamp: timeStamp,
          pointer: pointer,
          kind: kind,
          device: device,
          position: position,
          localPosition: localPosition,
          buttons: buttons,
          down: false,
          obscured: obscured,
          pressure: 0.0,
          pressureMin: pressureMin,
          pressureMax: pressureMax,
          distance: distance,
          distanceMax: distanceMax,
          size: size,
          radiusMajor: radiusMajor,
          radiusMinor: radiusMinor,
          radiusMin: radiusMin,
          radiusMax: radiusMax,
          orientation: orientation,
          tilt: tilt,
          transform: transform,
          original: original,
        );

  @override
  PointerCancelEvent transformed(Matrix4 transform) {
    if (transform == null || transform == this.transform) {
      return this;
    }
    return PointerCancelEvent(
      timeStamp: timeStamp,
      pointer: pointer,
      kind: kind,
      device: device,
      position: position,
      localPosition: PointerEvent.transformPosition(transform, position),
      buttons: buttons,
      obscured: obscured,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
      distance: distance,
      distanceMax: distanceMax,
      size: size,
      radiusMajor: radiusMajor,
      radiusMinor: radiusMinor,
      radiusMin: radiusMin,
      radiusMax: radiusMax,
      orientation: orientation,
      tilt: tilt,
      transform: transform,
      original: original ?? this,
    );
  }
}
