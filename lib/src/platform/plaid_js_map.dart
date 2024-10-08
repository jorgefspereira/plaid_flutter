@JS()
library plaid.js;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
class Plaid {
  external static Future<Plaid> create(WebConfiguration options);

  external void open();
  external void exit();
  external void destroy();
  external void submit(SubmitConfiguration options);
}

@JS()
@anonymous
class WebConfiguration {
  external String? token;
  external String? receivedRedirectUri;
  external String? key;

  external void Function(String publicToken, dynamic metadata) onSuccess;
  external void Function() onLoad;
  external void Function(dynamic error, dynamic metadata) onExit;
  external void Function(String eventName, dynamic metadata) onEvent;
}

@JS()
@anonymous
class SubmitConfiguration {
  external String? phone_number;
}

/// A workaround to converting an object from JS to a Dart Map.
Map jsToMap(jsObject) {
  if (jsObject == null) {
    return {};
  }

  return Map.fromIterable(
    _getKeysOfObject(jsObject),
    value: (key) => getProperty(jsObject, key),
  );
}

// Both of these interfaces exist to call `Object.keys` from Dart.
//
// But you don't use them directly. Just see `jsToMap`.
@JS('Object.keys')
external List<String> _getKeysOfObject(jsObject);
