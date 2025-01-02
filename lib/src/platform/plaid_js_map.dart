@JS()
library plaid.js;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

extension type Plaid._(JSObject _) implements JSObject {
  external static Plaid create(WebConfiguration options);
  external void open();
  external void exit();
  external void destroy();
  external void submit(SubmitConfiguration options);
}

@JS()
@anonymous
@staticInterop
class WebConfiguration {
  external factory WebConfiguration({
    String? token,
    String? receivedRedirectUri,
    String? key,
    required JSFunction onSuccess,
    required JSFunction onLoad,
    required JSFunction onExit,
    required JSFunction onEvent,
  });
}

@JS()
@anonymous
@staticInterop
class SubmitConfiguration {
  external factory SubmitConfiguration({
    @JS('phone_number') String? phoneNumber,
  });
}

/// A workaround to converting an object from JS to a Dart Map.
Map jsToMap(JSAny? jsObject) {
  if (jsObject == null || !jsObject.isA<JSObject>()) {
    return {};
  }
  final o = jsObject as JSObject;

  return Map.fromIterable(_getKeysOfObject(jsObject).toDart,
      value: (key) => o[key] // js. getProperty(jsObject, key),
      );
}

// Both of these interfaces exist to call `Object.keys` from Dart.
//
// But you don't use them directly. Just see `jsToMap`.
@JS('Object.keys')
external JSArray<JSString> _getKeysOfObject(JSAny jsObject);
