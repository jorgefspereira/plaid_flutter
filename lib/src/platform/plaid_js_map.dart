@JS()
library plaid.js;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
class Plaid {
  external static Plaid create(WebConfiguration options);

  external void open();
  external void exit();
  external void destroy();
}

@JS()
@anonymous
class WebConfiguration {
  external String? clientName;
  external String? env;
  external String? key;
  external List<dynamic>? product;
  external List<dynamic>? countryCodes;
  external String? webhook;
  external String? linkCustomizationName;
  external String? language;
  external String? oauthNonce;
  external String? oauthRedirectUri;
  external String? oauthStateId;
  external String? token;
  external String? paymentToken;
  external String? userLegalName;
  external String? userEmailAddress;
  external String? userPhoneNumber;
  external String? receivedRedirectUri;

  external void Function(String publicToken, dynamic metadata) onSuccess;
  external void Function() onLoad;
  external void Function(dynamic error, dynamic metadata) onExit;
  external void Function(String eventName, dynamic metadata) onEvent;
}

/// A workaround to converting an object from JS to a Dart Map.
Map jsToMap(jsObject) {
  if (jsObject == null) {
    return Map(); 
  }
  
  return new Map.fromIterable(
    _getKeysOfObject(jsObject),
    value: (key) => getProperty(jsObject, key),
  );
}

// Both of these interfaces exist to call `Object.keys` from Dart.
//
// But you don't use them directly. Just see `jsToMap`.
@JS('Object.keys')
external List<String> _getKeysOfObject(jsObject);
