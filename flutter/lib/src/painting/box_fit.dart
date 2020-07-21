import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';

import 'basic_types.dart';

enum BoxFit {
  fill,

  contain,

  cover,

  fitWidth,

  fitHeight,

  none,

  scaleDown,
}

@immutable
class FittedSizes {
  const FittedSizes(this.source, this.destination);

  final Size source;

  final Size destination;
}

FittedSizes applyBoxFit(BoxFit fit, Size inputSize, Size outputSize) {
  if (inputSize.height <= 0.0 ||
      inputSize.width <= 0.0 ||
      outputSize.height <= 0.0 ||
      outputSize.width <= 0.0) return const FittedSizes(Size.zero, Size.zero);

  Size sourceSize, destinationSize;
  switch (fit) {
    case BoxFit.fill:
      sourceSize = inputSize;
      destinationSize = outputSize;
      break;
    case BoxFit.contain:
      sourceSize = inputSize;
      if (outputSize.width / outputSize.height >
          sourceSize.width / sourceSize.height)
        destinationSize = new Size(
            sourceSize.width * outputSize.height / sourceSize.height,
            outputSize.height);
      else
        destinationSize = new Size(outputSize.width,
            sourceSize.height * outputSize.width / sourceSize.width);
      break;
    case BoxFit.cover:
      if (outputSize.width / outputSize.height >
          inputSize.width / inputSize.height) {
        sourceSize = new Size(inputSize.width,
            inputSize.width * outputSize.height / outputSize.width);
      } else {
        sourceSize = new Size(
            inputSize.height * outputSize.width / outputSize.height,
            inputSize.height);
      }
      destinationSize = outputSize;
      break;
    case BoxFit.fitWidth:
      sourceSize = new Size(inputSize.width,
          inputSize.width * outputSize.height / outputSize.width);
      destinationSize = new Size(outputSize.width,
          sourceSize.height * outputSize.width / sourceSize.width);
      break;
    case BoxFit.fitHeight:
      sourceSize = new Size(
          inputSize.height * outputSize.width / outputSize.height,
          inputSize.height);
      destinationSize = new Size(
          sourceSize.width * outputSize.height / sourceSize.height,
          outputSize.height);
      break;
    case BoxFit.none:
      sourceSize = new Size(math.min(inputSize.width, outputSize.width),
          math.min(inputSize.height, outputSize.height));
      destinationSize = sourceSize;
      break;
    case BoxFit.scaleDown:
      sourceSize = inputSize;
      destinationSize = inputSize;
      final double aspectRatio = inputSize.width / inputSize.height;
      if (destinationSize.height > outputSize.height)
        destinationSize =
            new Size(outputSize.height * aspectRatio, outputSize.height);
      if (destinationSize.width > outputSize.width)
        destinationSize =
            new Size(outputSize.width, outputSize.width / aspectRatio);
      break;
  }
  return new FittedSizes(sourceSize, destinationSize);
}
