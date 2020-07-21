import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_web/ui.dart' as ui show Codec, FrameInfo, Image;

import 'binding.dart';

Future<ui.Image> decodeImageFromList(Uint8List bytes) async {
  final ui.Codec codec =
      await PaintingBinding.instance.instantiateImageCodec(bytes);
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}
