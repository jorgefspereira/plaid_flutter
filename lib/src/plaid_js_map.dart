@JS()
library plaid.js;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
class Plaid {
  external static Plaid create(Configuration options);

  external void open();
  external void exit();
  external void destroy();
}

@JS()
@anonymous
class Configuration {
  external String get clientName;
  external String get env;
  external String get key;
  external List<dynamic> get product;

  external void Function(String publicToken, dynamic metadata) get onSuccess;
  external void Function() get onLoad;
  external void Function(dynamic error, dynamic metadata) get onExit;
  external void Function(String eventName, dynamic metadata) get onEvent;

  external List<dynamic> get countryCodes;
  external String get webhook;
  external String get linkCustomizationName;
  external String get language;
  external String get oauthNonce;
  external String get oauthRedirectUri;
  external String get oauthStateId;
  external String get token;
  external String get paymentToken;

  external String get userLegalName;
  external String get userEmailAddress;
  external String get userPhoneNumber;

  external factory Configuration({
    String clientName,
    String env,
    String key,
    List<dynamic> product,
    List<dynamic> countryCodes,
    String webhook,
    String linkCustomizationName,
    String language,
    String oauthNonce,
    String oauthRedirectUri,
    String oauthStateId,
    String token,
    String paymentToken,
    String userLegalName,
    String userEmailAddress,
    String userPhoneNumber,
    void Function(String publicToken, dynamic metadata) onSuccess,
    void Function() onLoad,
    void Function(dynamic error, dynamic metadata) onExit,
    void Function(String eventName, dynamic metadata) onEvent,
  });
}

/// A workaround to converting an object from JS to a Dart Map.
Map jsToMap(jsObject) {
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
