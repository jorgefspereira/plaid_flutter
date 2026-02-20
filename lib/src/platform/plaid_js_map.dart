@JS()
library plaid.js;

import 'dart:js_interop';

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
    @JS('date_of_birth') String? dateOfBirth,
  });
}

/// A workaround to converting an object from JS to a Dart Map.
Map jsToMap(Object? jsObject) {
  if (jsObject is Map) {
    return jsObject;
  }
  if (jsObject is! JSAny) {
    return {};
  }
  final dartified = jsObject.dartify();
  if (dartified is Map) {
    return dartified;
  }
  return {};
}
