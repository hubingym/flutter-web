part of material_animated_icons;

abstract class AnimatedIcons {
  static const AnimatedIconData add_event = _$add_event;

  static const AnimatedIconData arrow_menu = _$arrow_menu;

  static const AnimatedIconData close_menu = _$close_menu;

  static const AnimatedIconData ellipsis_search = _$ellipsis_search;

  static const AnimatedIconData event_add = _$event_add;

  static const AnimatedIconData home_menu = _$home_menu;

  static const AnimatedIconData list_view = _$list_view;

  static const AnimatedIconData menu_arrow = _$menu_arrow;

  static const AnimatedIconData menu_close = _$menu_close;

  static const AnimatedIconData menu_home = _$menu_home;

  static const AnimatedIconData pause_play = _$pause_play;

  static const AnimatedIconData play_pause = _$play_pause;

  static const AnimatedIconData search_ellipsis = _$search_ellipsis;

  static const AnimatedIconData view_list = _$view_list;
}

abstract class AnimatedIconData {
  const AnimatedIconData();

  bool get matchTextDirection;
}

class _AnimatedIconData extends AnimatedIconData {
  const _AnimatedIconData(this.size, this.paths,
      {this.matchTextDirection = false});

  final Size size;
  final List<_PathFrames> paths;

  @override
  final bool matchTextDirection;
}
