import 'dart:collection';

import 'package:flutter_web/foundation.dart';

import 'framework.dart';

abstract class InheritedModel<T> extends InheritedWidget {
  const InheritedModel({Key key, Widget child}) : super(key: key, child: child);

  @override
  InheritedModelElement<T> createElement() => InheritedModelElement<T>(this);

  @protected
  bool updateShouldNotifyDependent(
      covariant InheritedModel<T> oldWidget, Set<T> dependencies);

  @protected
  bool isSupportedAspect(Object aspect) => true;

  static Iterable<InheritedElement>
      _findModels<T extends InheritedModel<Object>>(
          BuildContext context, Object aspect) sync* {
    final InheritedElement model =
        context.ancestorInheritedElementForWidgetOfExactType(T);
    if (model == null) return;

    yield model;

    assert(model.widget is T);
    final T modelWidget = model.widget;
    if (modelWidget.isSupportedAspect(aspect)) return;

    Element modelParent;
    model.visitAncestorElements((Element ancestor) {
      modelParent = ancestor;
      return false;
    });
    if (modelParent == null) return;

    yield* _findModels<T>(modelParent, aspect);
  }

  static T inheritFrom<T extends InheritedModel<Object>>(BuildContext context,
      {Object aspect}) {
    if (aspect == null) return context.inheritFromWidgetOfExactType(T);

    final List<InheritedElement> models =
        _findModels<T>(context, aspect).toList();
    if (models.isEmpty) {
      return null;
    }

    final InheritedElement lastModel = models.last;
    for (InheritedElement model in models) {
      final T value = context.inheritFromElement(model, aspect: aspect);
      if (model == lastModel) return value;
    }

    assert(false);
    return null;
  }
}

class InheritedModelElement<T> extends InheritedElement {
  InheritedModelElement(InheritedModel<T> widget) : super(widget);

  @override
  InheritedModel<T> get widget => super.widget;

  @override
  void updateDependencies(Element dependent, Object aspect) {
    final Set<T> dependencies = getDependencies(dependent);
    if (dependencies != null && dependencies.isEmpty) return;

    if (aspect == null) {
      setDependencies(dependent, HashSet<T>());
    } else {
      assert(aspect is T);
      setDependencies(dependent, (dependencies ?? HashSet<T>())..add(aspect));
    }
  }

  @override
  void notifyDependent(InheritedModel<T> oldWidget, Element dependent) {
    final Set<T> dependencies = getDependencies(dependent);
    if (dependencies == null) return;
    if (dependencies.isEmpty ||
        widget.updateShouldNotifyDependent(oldWidget, dependencies))
      dependent.didChangeDependencies();
  }
}
