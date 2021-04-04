import 'dart:async';

// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';

import 'src/plaid_js_map.dart';

/// A web implementation of the PlaidFlutter plugin.
class PlaidFlutterPlugin {
  final MethodChannel _channel;

  PlaidFlutterPlugin(this._channel) {
    _channel.setMethodCallHandler(handleMethodCall);
  }

  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
        'plugins.flutter.io/plaid_flutter',
        const StandardMethodCodec(),
        registrar);
    PlaidFlutterPlugin(channel);
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'open':
        return open(call.arguments);
      case 'close':
        return close();
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              'plaid_flutter for web doesn\'t implement \'${call.method}\'',
        );
    }
  }

  void open(Map<dynamic, dynamic> arguments) {
    final String? token = arguments['token'];
    final String? publicKey = arguments['publicKey'];
    final String? clientName = arguments['clientName'];
    final String? environment = arguments['environment'];
    final String? linkCustomizationName = arguments['linkCustomizationName'];
    final String? language =
        arguments['language'] == null ? 'en' : arguments['language'];
    final String? webhook = arguments['webhook'];
    final String? userLegalName = arguments['userLegalName'];
    final String? userEmailAddress = arguments['userEmailAddress'];
    final String? userPhoneNumber = arguments['userPhoneNumber'];
    final String? oauthNonce = arguments['oauthNonce'];
    final String? oauthRedirectUri = arguments['oauthRedirectUri'];
    List<String> countryCodes = arguments['countryCodes'] == null
        ? ['']
        : List<String>.from(arguments['countryCodes']);
    List<String> products = arguments['products'] == null
        ? ['']
        : List<String>.from(arguments['products']);

    Configuration options = Configuration(
      clientName: clientName,
      token: token,
      key: publicKey,
      env: environment,
      product: products,
      countryCodes: countryCodes,
      webhook: webhook,
      linkCustomizationName: linkCustomizationName,
      language: language,
      oauthNonce: oauthNonce,
      oauthRedirectUri: oauthRedirectUri,
      userLegalName: userLegalName,
      userEmailAddress: userEmailAddress,
      userPhoneNumber: userPhoneNumber,
      onEvent: allowInterop((event, metadata) {
        Map<String, dynamic> arguments = {
          'event': event,
          'metadata': mapFromEventMetadata(jsToMap(metadata))
        };
        _channel.invokeMethod('onEvent', arguments);
      }),
      onSuccess: allowInterop((publicToken, metadata) {
        Map<String, dynamic> arguments = {
          'publicToken': publicToken,
          'metadata': mapFromSuccessMetadata(jsToMap(metadata))
        };
        _channel.invokeMethod('onSuccess', arguments);
      }),
      onExit: allowInterop((error, metadata) {
        Map<String, dynamic> arguments = {
          'metadata': mapFromExitMetadata(jsToMap(metadata))
        };

        if (error != null) {
          arguments["error"] = mapFromError(jsToMap(error));
        }

        _channel.invokeMethod('onExit', arguments);
      }),
      onLoad: allowInterop(() {}),
    );

    Plaid.create(options).open();
  }

  void close() {}

  Map<String, dynamic> mapFromError(Map<dynamic, dynamic> data) {
    Map<String, dynamic> result = {};

    result["errorType"] = data["error_type"] ?? "";
    result["errorCode"] = data["error_code"] ?? "";
    result["errorMessage"] = data["error_message"] ?? "";
    result["errorType"] = data["error_type"] ?? "";

    return result;
  }

  Map<String, dynamic> mapFromSuccessMetadata(Map<dynamic, dynamic> data) {
    Map<String, dynamic> result = {};

    Map<dynamic, dynamic> institutionMap = jsToMap(data["institution"]);

    result["institution"] = {
      "id": institutionMap["institution_id"] ?? "",
      "name": institutionMap["name"] ?? ""
    };
    result["linkSessionId"] = data["link_session_id"] ?? "";

    List<dynamic> accountsList = [];

    for (dynamic item in data["accounts"]) {
      Map<dynamic, dynamic> accountMap = jsToMap(item);
      Map<String, dynamic> account = {};

      account["id"] = accountMap["id"] ?? "";
      account["mask"] = accountMap["mask"] ?? "";
      account["name"] = accountMap["name"] ?? "";
      account["type"] = accountMap["type"] ?? "";
      account["subtype"] = accountMap["subtype"] ?? "";
      account["verificationStatus"] = accountMap["verification_status"] ?? "";

      accountsList.add(account);
    }

    result["accounts"] = accountsList;

    return result;
  }

  Map<String, dynamic> mapFromExitMetadata(Map<dynamic, dynamic> data) {
    Map<String, dynamic> result = {};

    Map<dynamic, dynamic> institutionMap = jsToMap(data["institution"]);

    result["institution"] = {
      "id": institutionMap["institution_id"] ?? "",
      "name": institutionMap["name"] ?? ""
    };
    result["requestId"] = data["request_id"] ?? "";
    result["linkSessionId"] = data["link_session_id"] ?? "";
    result["status"] = data["status"] ?? "";

    return result;
  }

  Map<String, dynamic> mapFromEventMetadata(Map<dynamic, dynamic> data) {
    Map<String, dynamic> result = {};

    result['errorCode'] = data['error_code'] ?? "";
    result['errorMessage'] = data['error_message'] ?? "";
    result['errorType'] = data['error_type'] ?? "";
    result['exitStatus'] = data['exit_status'] ?? "";
    result['institutionSearchQuery'] = data['institution_search_query'] ?? "";
    result['institutionName'] = data['institution_name'] ?? "";
    result['institutionId'] = data['institution_id'] ?? "";
    result['linkSessionId'] = data['link_session_id'] ?? "";
    result['mfaType'] = data['mfa_type'] ?? "";
    result['viewName'] = data['view_name'] ?? "";
    result['requestId'] = data['request_id'] ?? "";
    result['timestamp'] = data['timestamp'] ?? "";

    return result;
  }
}
