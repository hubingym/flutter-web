import 'package:flutter_web/rendering.dart';

import 'framework.dart';

class PerformanceOverlay extends LeafRenderObjectWidget {
  const PerformanceOverlay({
    Key key,
    this.optionsMask = 0,
    this.rasterizerThreshold = 0,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
  }) : super(key: key);

  PerformanceOverlay.allEnabled(
      {Key key,
      this.rasterizerThreshold = 0,
      this.checkerboardRasterCacheImages = false,
      this.checkerboardOffscreenLayers = false})
      : optionsMask = 1 <<
                PerformanceOverlayOption.displayRasterizerStatistics.index |
            1 << PerformanceOverlayOption.visualizeRasterizerStatistics.index |
            1 << PerformanceOverlayOption.displayEngineStatistics.index |
            1 << PerformanceOverlayOption.visualizeEngineStatistics.index,
        super(key: key);

  final int optionsMask;

  final int rasterizerThreshold;

  final bool checkerboardRasterCacheImages;

  final bool checkerboardOffscreenLayers;

  @override
  RenderPerformanceOverlay createRenderObject(BuildContext context) =>
      RenderPerformanceOverlay(
        optionsMask: optionsMask,
        rasterizerThreshold: rasterizerThreshold,
        checkerboardRasterCacheImages: checkerboardRasterCacheImages,
        checkerboardOffscreenLayers: checkerboardOffscreenLayers,
      );

  @override
  void updateRenderObject(
      BuildContext context, RenderPerformanceOverlay renderObject) {
    renderObject
      ..optionsMask = optionsMask
      ..rasterizerThreshold = rasterizerThreshold;
  }
}
