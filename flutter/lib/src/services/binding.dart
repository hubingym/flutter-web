import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_web/ui.dart' as ui;

import 'package:flutter_web/foundation.dart';

import 'asset_bundle.dart';
import 'binary_messenger.dart';

mixin ServicesBinding on BindingBase {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _defaultBinaryMessenger = createBinaryMessenger();
    window..onPlatformMessage = defaultBinaryMessenger.handlePlatformMessage;
    initLicenses();
  }

  static ServicesBinding get instance => _instance;
  static ServicesBinding _instance;

  BinaryMessenger get defaultBinaryMessenger => _defaultBinaryMessenger;
  BinaryMessenger _defaultBinaryMessenger;

  @protected
  BinaryMessenger createBinaryMessenger() {
    return const _DefaultBinaryMessenger._();
  }

  @protected
  @mustCallSuper
  void initLicenses() {
    LicenseRegistry.addLicense(_addLicenses);
  }

  Stream<LicenseEntry> _addLicenses() async* {
    final Completer<String> rawLicenses = Completer<String>();
    Timer.run(() async {
      rawLicenses.complete(rootBundle.loadString('LICENSE', cache: false));
    });
    await rawLicenses.future;
    final Completer<List<LicenseEntry>> parsedLicenses =
        Completer<List<LicenseEntry>>();
    Timer.run(() async {
      parsedLicenses.complete(compute(_parseLicenses, await rawLicenses.future,
          debugLabel: 'parseLicenses'));
    });
    await parsedLicenses.future;
    yield* Stream<LicenseEntry>.fromIterable(await parsedLicenses.future);
  }

  static List<LicenseEntry> _parseLicenses(String rawLicenses) {
    final String _licenseSeparator = '\n' + ('-' * 80) + '\n';
    final List<LicenseEntry> result = <LicenseEntry>[];
    final List<String> licenses = rawLicenses.split(_licenseSeparator);
    for (String license in licenses) {
      final int split = license.indexOf('\n\n');
      if (split >= 0) {
        result.add(LicenseEntryWithLineBreaks(
          license.substring(0, split).split('\n'),
          license.substring(split + 2),
        ));
      } else {
        result.add(LicenseEntryWithLineBreaks(const <String>[], license));
      }
    }
    return result;
  }

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    assert(() {
      registerStringServiceExtension(
        name: 'evict',
        getter: () async => '',
        setter: (String value) async {
          evict(value);
        },
      );
      return true;
    }());
  }

  @protected
  @mustCallSuper
  void evict(String asset) {
    rootBundle.evict(asset);
  }
}

class _DefaultBinaryMessenger extends BinaryMessenger {
  const _DefaultBinaryMessenger._();

  static final Map<String, MessageHandler> _handlers =
      <String, MessageHandler>{};

  static final Map<String, MessageHandler> _mockHandlers =
      <String, MessageHandler>{};

  Future<ByteData> _sendPlatformMessage(String channel, ByteData message) {
    final Completer<ByteData> completer = Completer<ByteData>();

    ui.window.sendPlatformMessage(channel, message, (ByteData reply) {
      try {
        completer.complete(reply);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context:
              ErrorDescription('during a platform message response callback'),
        ));
      }
    });
    return completer.future;
  }

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData data,
    ui.PlatformMessageResponseCallback callback,
  ) async {
    ByteData response;
    try {
      final MessageHandler handler = _handlers[channel];
      if (handler != null) response = await handler(data);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'services library',
        context: ErrorDescription('during a platform message callback'),
      ));
    } finally {
      callback(response);
    }
  }

  @override
  Future<ByteData> send(String channel, ByteData message) {
    final MessageHandler handler = _mockHandlers[channel];
    if (handler != null) return handler(message);
    return _sendPlatformMessage(channel, message);
  }

  @override
  void setMessageHandler(String channel, MessageHandler handler) {
    if (handler == null)
      _handlers.remove(channel);
    else
      _handlers[channel] = handler;
  }

  @override
  void setMockMessageHandler(String channel, MessageHandler handler) {
    if (handler == null)
      _mockHandlers.remove(channel);
    else
      _mockHandlers[channel] = handler;
  }
}
