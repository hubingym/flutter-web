import 'package:flutter_web/ui.dart' show Color, Offset;

import 'package:flutter_web/painting.dart';

const Map<int, List<BoxShadow>> kElevationToShadow = _elevationToShadow;

const Color _kKeyUmbraOpacity = const Color(0x33000000);
const Color _kKeyPenumbraOpacity = const Color(0x24000000);
const Color _kAmbientShadowOpacity = const Color(0x1F000000);
const Map<int, List<BoxShadow>> _elevationToShadow =
    const <int, List<BoxShadow>>{
  1: const <BoxShadow>[
    const BoxShadow(
        offset: const Offset(0.0, 2.0),
        blurRadius: 1.0,
        spreadRadius: -1.0,
        color: _kKeyUmbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 1.0),
        blurRadius: 1.0,
        spreadRadius: 0.0,
        color: _kKeyPenumbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 1.0),
        blurRadius: 3.0,
        spreadRadius: 0.0,
        color: _kAmbientShadowOpacity),
  ],
  2: const <BoxShadow>[
    const BoxShadow(
        offset: const Offset(0.0, 3.0),
        blurRadius: 1.0,
        spreadRadius: -2.0,
        color: _kKeyUmbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 2.0),
        blurRadius: 2.0,
        spreadRadius: 0.0,
        color: _kKeyPenumbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 1.0),
        blurRadius: 5.0,
        spreadRadius: 0.0,
        color: _kAmbientShadowOpacity),
  ],
  3: const <BoxShadow>[
    const BoxShadow(
        offset: const Offset(0.0, 3.0),
        blurRadius: 3.0,
        spreadRadius: -2.0,
        color: _kKeyUmbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 3.0),
        blurRadius: 4.0,
        spreadRadius: 0.0,
        color: _kKeyPenumbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 1.0),
        blurRadius: 8.0,
        spreadRadius: 0.0,
        color: _kAmbientShadowOpacity),
  ],
  4: const <BoxShadow>[
    const BoxShadow(
        offset: const Offset(0.0, 2.0),
        blurRadius: 4.0,
        spreadRadius: -1.0,
        color: _kKeyUmbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 4.0),
        blurRadius: 5.0,
        spreadRadius: 0.0,
        color: _kKeyPenumbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 1.0),
        blurRadius: 10.0,
        spreadRadius: 0.0,
        color: _kAmbientShadowOpacity),
  ],
  6: const <BoxShadow>[
    const BoxShadow(
        offset: const Offset(0.0, 3.0),
        blurRadius: 5.0,
        spreadRadius: -1.0,
        color: _kKeyUmbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 6.0),
        blurRadius: 10.0,
        spreadRadius: 0.0,
        color: _kKeyPenumbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 1.0),
        blurRadius: 18.0,
        spreadRadius: 0.0,
        color: _kAmbientShadowOpacity),
  ],
  8: const <BoxShadow>[
    const BoxShadow(
        offset: const Offset(0.0, 5.0),
        blurRadius: 5.0,
        spreadRadius: -3.0,
        color: _kKeyUmbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 8.0),
        blurRadius: 10.0,
        spreadRadius: 1.0,
        color: _kKeyPenumbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 3.0),
        blurRadius: 14.0,
        spreadRadius: 2.0,
        color: _kAmbientShadowOpacity),
  ],
  9: const <BoxShadow>[
    const BoxShadow(
        offset: const Offset(0.0, 5.0),
        blurRadius: 6.0,
        spreadRadius: -3.0,
        color: _kKeyUmbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 9.0),
        blurRadius: 12.0,
        spreadRadius: 1.0,
        color: _kKeyPenumbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 3.0),
        blurRadius: 16.0,
        spreadRadius: 2.0,
        color: _kAmbientShadowOpacity),
  ],
  12: const <BoxShadow>[
    const BoxShadow(
        offset: const Offset(0.0, 7.0),
        blurRadius: 8.0,
        spreadRadius: -4.0,
        color: _kKeyUmbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 12.0),
        blurRadius: 17.0,
        spreadRadius: 2.0,
        color: _kKeyPenumbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 5.0),
        blurRadius: 22.0,
        spreadRadius: 4.0,
        color: _kAmbientShadowOpacity),
  ],
  16: const <BoxShadow>[
    const BoxShadow(
        offset: const Offset(0.0, 8.0),
        blurRadius: 10.0,
        spreadRadius: -5.0,
        color: _kKeyUmbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 16.0),
        blurRadius: 24.0,
        spreadRadius: 2.0,
        color: _kKeyPenumbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 6.0),
        blurRadius: 30.0,
        spreadRadius: 5.0,
        color: _kAmbientShadowOpacity),
  ],
  24: const <BoxShadow>[
    const BoxShadow(
        offset: const Offset(0.0, 11.0),
        blurRadius: 15.0,
        spreadRadius: -7.0,
        color: _kKeyUmbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 24.0),
        blurRadius: 38.0,
        spreadRadius: 3.0,
        color: _kKeyPenumbraOpacity),
    const BoxShadow(
        offset: const Offset(0.0, 9.0),
        blurRadius: 46.0,
        spreadRadius: 8.0,
        color: _kAmbientShadowOpacity),
  ],
};
