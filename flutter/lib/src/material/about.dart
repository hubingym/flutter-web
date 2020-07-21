import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/scheduler.dart';
import 'package:flutter_web/widgets.dart' hide Flow;

import 'app_bar.dart';
import 'debug.dart';
import 'dialog.dart';
import 'flat_button.dart';
import 'list_tile.dart';
import 'material_localizations.dart';
import 'page.dart';
import 'progress_indicator.dart';
import 'scaffold.dart';
import 'scrollbar.dart';
import 'theme.dart';

class AboutListTile extends StatelessWidget {
  const AboutListTile(
      {Key key,
      this.icon = const Icon(null),
      this.child,
      this.applicationName,
      this.applicationVersion,
      this.applicationIcon,
      this.applicationLegalese,
      this.aboutBoxChildren})
      : super(key: key);

  final Widget icon;

  final Widget child;

  final String applicationName;

  final String applicationVersion;

  final Widget applicationIcon;

  final String applicationLegalese;

  final List<Widget> aboutBoxChildren;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    return ListTile(
        leading: icon,
        title: child ??
            Text(MaterialLocalizations.of(context).aboutListTileTitle(
                applicationName ?? _defaultApplicationName(context))),
        onTap: () {
          showAboutDialog(
              context: context,
              applicationName: applicationName,
              applicationVersion: applicationVersion,
              applicationIcon: applicationIcon,
              applicationLegalese: applicationLegalese,
              children: aboutBoxChildren);
        });
  }
}

void showAboutDialog({
  @required BuildContext context,
  String applicationName,
  String applicationVersion,
  Widget applicationIcon,
  String applicationLegalese,
  List<Widget> children,
}) {
  assert(context != null);
  showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AboutDialog(
          applicationName: applicationName,
          applicationVersion: applicationVersion,
          applicationIcon: applicationIcon,
          applicationLegalese: applicationLegalese,
          children: children,
        );
      });
}

void showLicensePage(
    {@required BuildContext context,
    String applicationName,
    String applicationVersion,
    Widget applicationIcon,
    String applicationLegalese}) {
  assert(context != null);
  Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (BuildContext context) => LicensePage(
              applicationName: applicationName,
              applicationVersion: applicationVersion,
              applicationLegalese: applicationLegalese)));
}

class AboutDialog extends StatelessWidget {
  const AboutDialog({
    Key key,
    this.applicationName,
    this.applicationVersion,
    this.applicationIcon,
    this.applicationLegalese,
    this.children,
  }) : super(key: key);

  final String applicationName;

  final String applicationVersion;

  final Widget applicationIcon;

  final String applicationLegalese;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final String name = applicationName ?? _defaultApplicationName(context);
    final String version =
        applicationVersion ?? _defaultApplicationVersion(context);
    final Widget icon = applicationIcon ?? _defaultApplicationIcon(context);
    List<Widget> body = <Widget>[];
    if (icon != null)
      body.add(IconTheme(data: const IconThemeData(size: 48.0), child: icon));
    body.add(Expanded(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ListBody(children: <Widget>[
              Text(name, style: Theme.of(context).textTheme.headline),
              Text(version, style: Theme.of(context).textTheme.body1),
              Container(height: 18.0),
              Text(applicationLegalese ?? '',
                  style: Theme.of(context).textTheme.caption)
            ]))));
    body = <Widget>[
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: body),
    ];
    if (children != null) body.addAll(children);
    return AlertDialog(
        content: SingleChildScrollView(
          child: ListBody(children: body),
        ),
        actions: <Widget>[
          FlatButton(
              child: Text(
                  MaterialLocalizations.of(context).viewLicensesButtonLabel),
              onPressed: () {
                showLicensePage(
                    context: context,
                    applicationName: applicationName,
                    applicationVersion: applicationVersion,
                    applicationIcon: applicationIcon,
                    applicationLegalese: applicationLegalese);
              }),
          FlatButton(
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
              onPressed: () {
                Navigator.pop(context);
              }),
        ]);
  }
}

class LicensePage extends StatefulWidget {
  const LicensePage(
      {Key key,
      this.applicationName,
      this.applicationVersion,
      this.applicationLegalese})
      : super(key: key);

  final String applicationName;

  final String applicationVersion;

  final String applicationLegalese;

  @override
  _LicensePageState createState() => _LicensePageState();
}

class _LicensePageState extends State<LicensePage> {
  @override
  void initState() {
    super.initState();
    _initLicenses();
  }

  final List<Widget> _licenses = <Widget>[];
  bool _loaded = false;

  Future<void> _initLicenses() async {
    await for (LicenseEntry license in LicenseRegistry.licenses) {
      if (!mounted) return;
      final List<LicenseParagraph> paragraphs =
          await SchedulerBinding.instance.scheduleTask<List<LicenseParagraph>>(
        () => license.paragraphs.toList(),
        Priority.animation,
        debugLabel: 'License',
      );
      setState(() {
        _licenses.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 18.0),
            child: Text('🍀‬', textAlign: TextAlign.center)));
        _licenses.add(Container(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 0.0))),
            child: Text(license.packages.join(', '),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)));
        for (LicenseParagraph paragraph in paragraphs) {
          if (paragraph.indent == LicenseParagraph.centeredIndent) {
            _licenses.add(Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(paragraph.text,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center)));
          } else {
            assert(paragraph.indent >= 0);
            _licenses.add(Padding(
                padding: EdgeInsetsDirectional.only(
                    top: 8.0, start: 16.0 * paragraph.indent),
                child: Text(paragraph.text)));
          }
        }
      });
    }
    setState(() {
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final String name =
        widget.applicationName ?? _defaultApplicationName(context);
    final String version =
        widget.applicationVersion ?? _defaultApplicationVersion(context);
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final List<Widget> contents = <Widget>[
      Text(name,
          style: Theme.of(context).textTheme.headline,
          textAlign: TextAlign.center),
      Text(version,
          style: Theme.of(context).textTheme.body1,
          textAlign: TextAlign.center),
      Container(height: 18.0),
      Text(widget.applicationLegalese ?? '',
          style: Theme.of(context).textTheme.caption,
          textAlign: TextAlign.center),
      Container(height: 18.0),
      Text('Powered by Flutter',
          style: Theme.of(context).textTheme.body1,
          textAlign: TextAlign.center),
      Container(height: 24.0),
    ];
    contents.addAll(_licenses);
    if (!_loaded) {
      contents.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(child: CircularProgressIndicator())));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.licensesPageTitle),
      ),
      body: Localizations.override(
        locale: const Locale('en', 'US'),
        context: context,
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.caption,
          child: Scrollbar(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              children: contents,
            ),
          ),
        ),
      ),
    );
  }
}

String _defaultApplicationName(BuildContext context) {
  final Title ancestorTitle = context.ancestorWidgetOfExactType(Title);
  return ancestorTitle?.title ?? 'App';
}

String _defaultApplicationVersion(BuildContext context) {
  return '';
}

Widget _defaultApplicationIcon(BuildContext context) {
  return null;
}
