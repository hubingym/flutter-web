library flutter_web.io;

import 'dart:async';
import 'dart:convert' show Encoding;

class Platform {
  static final _operatingSystem = 'android';

  static String get operatingSystem => _operatingSystem;

  static final bool isLinux = (_operatingSystem == "linux");

  static final bool isMacOS = (_operatingSystem == "macos");

  static final bool isWindows = (_operatingSystem == "windows");

  static final bool isAndroid = (_operatingSystem == "android");

  static final bool isIOS = (_operatingSystem == "ios");

  static final bool isFuchsia = (_operatingSystem == "fuchsia");

  static const Map<String, String> environment = <String, String>{
    'FLUTTER_TEST': 'true',
  };
}

void exit(int exitCode) {
  throw _ProgramExitedError();
}

class _ProgramExitedError extends Error {
  @override
  String toString() => 'Program exited';
}

class HttpOverrides {
  static HttpOverrides global;

  HttpClient createHttpClient(SecurityContext _) {
    return null;
  }
}

class HttpClient {
  bool autoUncompress;
  Duration connectionTimeout;
  Duration idleTimeout;
  int maxConnectionsPerHost;
  String userAgent;
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {}
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String realm) f) {}
  set authenticateProxy(
      Future<bool> Function(String host, int port, String scheme, String realm)
          f) {}
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port) callback) {}
  void close({bool force = false}) {}
  Future<HttpClientRequest> delete(String host, int port, String path) {
    return null;
  }

  Future<HttpClientRequest> deleteUrl(Uri url) {
    return null;
  }

  set findProxy(String Function(Uri url) f) {}
  Future<HttpClientRequest> get(String host, int port, String path) {
    return null;
  }

  Future<HttpClientRequest> getUrl(Uri url) {
    return null;
  }

  Future<HttpClientRequest> head(String host, int port, String path) {
    return null;
  }

  Future<HttpClientRequest> headUrl(Uri url) {
    return null;
  }

  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    return null;
  }

  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return null;
  }

  Future<HttpClientRequest> patch(String host, int port, String path) {
    return null;
  }

  Future<HttpClientRequest> patchUrl(Uri url) {
    return null;
  }

  Future<HttpClientRequest> post(String host, int port, String path) {
    return null;
  }

  Future<HttpClientRequest> postUrl(Uri url) {
    return null;
  }

  Future<HttpClientRequest> put(String host, int port, String path) {
    return null;
  }

  Future<HttpClientRequest> putUrl(Uri url) {
    return null;
  }
}

class HttpClientCredentials {}

abstract class HttpClientRequest {
  Encoding encoding;
  HttpHeaders get headers;
  void add(List<int> data);
  void addError(Object error, [StackTrace stackTrace]);
  Future<void> addStream(Stream<List<int>> stream);
  Future<HttpClientResponse> close();
  HttpConnectionInfo get connectionInfo;
  List<Cookie> get cookies;
  Future<HttpClientResponse> get done;
  Future<void> flush();
  String get method;
  Uri get uri;
  void write(Object obj);
  void writeAll(Iterable<Object> objects, [String separator = '']);
  void writeCharCode(int charCode);
  void writeln([Object obj = '']);
}

class HttpHeaders {
  List<String> operator [](String name) => <String>[];
  void add(String name, Object value) {}
  void clear() {}
  void forEach(void Function(String name, List<String> values) f) {}
  void noFolding(String name) {}
  void remove(String name, Object value) {}
  void removeAll(String name) {}
  void set(String name, Object value) {}
  String value(String name) => null;
}

abstract class HttpClientResponse {
  HttpHeaders get headers;
  X509Certificate get certificate;
  HttpConnectionInfo get connectionInfo;
  int get contentLength;
  List<Cookie> get cookies;
  Future<Socket> detachSocket();
  bool get isRedirect;
  StreamSubscription<List<int>> listen(void Function(List<int> event) onData,
      {Function onError, void Function() onDone, bool cancelOnError});
  bool get persistentConnection;
  String get reasonPhrase;
  Future<HttpClientResponse> redirect(
      [String method, Uri url, bool followLoops]);
  List<RedirectInfo> get redirects;
  int get statusCode;
}

class HttpConnectionInfo {}

class Socket {}

class Cookie {}

class RedirectionInfo {}

class RedirectInfo {}

class X509Certificate {}

class SecurityContext {}
