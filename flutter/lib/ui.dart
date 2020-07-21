// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This library defines the web equivalent of the native dart:ui.
///
/// All types in this library are public.
library ui;

import 'dart:async';
import 'dart:collection';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import 'ui_src/engine.dart' as engine;
export 'ui_src/engine.dart'
    show persistedPictureFactory, houdiniPictureFactory, platformViewRegistry;

part 'ui_src/ui/canvas.dart';
part 'ui_src/ui/compositing.dart';
part 'ui_src/ui/geometry.dart';
part 'ui_src/ui/hash_codes.dart';
part 'ui_src/ui/initialization.dart';
part 'ui_src/ui/lerp.dart';
part 'ui_src/ui/natives.dart';
part 'ui_src/ui/painting.dart';
part 'ui_src/ui/pointer.dart';
part 'ui_src/ui/semantics.dart';
part 'ui_src/ui/test_embedding.dart';
part 'ui_src/ui/text.dart';
part 'ui_src/ui/tile_mode.dart';
part 'ui_src/ui/window.dart';

/// Provides a compile time constant to customize flutter framework and other
/// users of ui engine for web runtime.
const bool isWeb = true;

/// Web specific SMI. Used by bitfield. The 0x3FFFFFFFFFFFFFFF used on VM
/// is not supported on Web platform.
const int kMaxUnsignedSMI = -1;
