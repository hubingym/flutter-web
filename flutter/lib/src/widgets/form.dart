import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'framework.dart';

class Form extends StatefulWidget {
  const Form({
    Key key,
    @required this.child,
    this.autovalidate = false,
    this.onWillPop,
    this.onChanged,
  })  : assert(child != null),
        super(key: key);

  static FormState of(BuildContext context) {
    final _FormScope scope = context.inheritFromWidgetOfExactType(_FormScope);
    return scope?._formState;
  }

  final Widget child;

  final bool autovalidate;

  final WillPopCallback onWillPop;

  final VoidCallback onChanged;

  @override
  FormState createState() => FormState();
}

class FormState extends State<Form> {
  int _generation = 0;
  final Set<FormFieldState<dynamic>> _fields = Set<FormFieldState<dynamic>>();

  void _fieldDidChange() {
    if (widget.onChanged != null) widget.onChanged();
    _forceRebuild();
  }

  void _forceRebuild() {
    setState(() {
      ++_generation;
    });
  }

  void _register(FormFieldState<dynamic> field) {
    _fields.add(field);
  }

  void _unregister(FormFieldState<dynamic> field) {
    _fields.remove(field);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.autovalidate) _validate();
    return WillPopScope(
      onWillPop: widget.onWillPop,
      child: _FormScope(
        formState: this,
        generation: _generation,
        child: widget.child,
      ),
    );
  }

  void save() {
    for (FormFieldState<dynamic> field in _fields) field.save();
  }

  void reset() {
    for (FormFieldState<dynamic> field in _fields) field.reset();
    _fieldDidChange();
  }

  bool validate() {
    _forceRebuild();
    return _validate();
  }

  bool _validate() {
    bool hasError = false;
    for (FormFieldState<dynamic> field in _fields)
      hasError = !field.validate() || hasError;
    return !hasError;
  }
}

class _FormScope extends InheritedWidget {
  const _FormScope({Key key, Widget child, FormState formState, int generation})
      : _formState = formState,
        _generation = generation,
        super(key: key, child: child);

  final FormState _formState;

  final int _generation;

  Form get form => _formState.widget;

  @override
  bool updateShouldNotify(_FormScope old) => _generation != old._generation;
}

typedef FormFieldValidator<T> = String Function(T value);

typedef FormFieldSetter<T> = void Function(T newValue);

typedef FormFieldBuilder<T> = Widget Function(FormFieldState<T> field);

class FormField<T> extends StatefulWidget {
  const FormField({
    Key key,
    @required this.builder,
    this.onSaved,
    this.validator,
    this.initialValue,
    this.autovalidate = false,
    this.enabled = true,
  })  : assert(builder != null),
        super(key: key);

  final FormFieldSetter<T> onSaved;

  final FormFieldValidator<T> validator;

  final FormFieldBuilder<T> builder;

  final T initialValue;

  final bool autovalidate;

  final bool enabled;

  @override
  FormFieldState<T> createState() => FormFieldState<T>();
}

class FormFieldState<T> extends State<FormField<T>> {
  T _value;
  String _errorText;

  T get value => _value;

  String get errorText => _errorText;

  bool get hasError => _errorText != null;

  void save() {
    if (widget.onSaved != null) widget.onSaved(value);
  }

  void reset() {
    setState(() {
      _value = widget.initialValue;
      _errorText = null;
    });
  }

  bool validate() {
    setState(() {
      _validate();
    });
    return !hasError;
  }

  bool _validate() {
    if (widget.validator != null) _errorText = widget.validator(_value);
    return !hasError;
  }

  void didChange(T value) {
    setState(() {
      _value = value;
    });
    Form.of(context)?._fieldDidChange();
  }

  @protected
  void setValue(T value) {
    _value = value;
  }

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  void deactivate() {
    Form.of(context)?._unregister(this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.autovalidate && widget.enabled) _validate();
    Form.of(context)?._register(this);
    return widget.builder(this);
  }
}
