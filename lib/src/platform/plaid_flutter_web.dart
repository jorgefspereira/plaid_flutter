import 'dart:async';
import 'dart:js';

// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '../core/events.dart';
import '../core/link_configuration.dart';
import 'plaid_js_map.dart';
import 'plaid_platform_interface.dart';

/// A web implementation of the PlaidFlutter plugin.
class PlaidFlutterPlugin extends PlaidPlatformInterface {
  /// Event stream controller
  StreamController<LinkObject>? _onObjectsController;

  /// Event stream
  late Stream<LinkObject> _onObjects;

  /// Factory method that initializes the Plaid plugin platform with an instance
  /// of the plugin for the web.
  static void registerWith(Registrar registrar) {
    PlaidPlatformInterface.instance = PlaidFlutterPlugin();
  }

  /// Initializes the Plaid Link flow on the device.
  Future<void> open({required LinkConfiguration configuration}) async {
    WebConfiguration options = WebConfiguration();

    /// onSuccess handler
    options.onSuccess = allowInterop((publicToken, metadata) {
      Map<String, dynamic> data = {
        'publicToken': publicToken,
        'metadata': mapFromSuccessMetadata(jsToMap(metadata)),
      };

      _sendEvent(LinkSuccess.fromJson(data));
    });

    /// onEvent handler
    options.onEvent = allowInterop((event, metadata) {
      Map<String, dynamic> data = {
        'name': event,
        'metadata': mapFromEventMetadata(jsToMap(metadata)),
      };

      _sendEvent(LinkEvent.fromJson(data));
    });

    /// onExit handler
    options.onExit = allowInterop((error, metadata) {
      Map<String, dynamic> data = {'metadata': mapFromExitMetadata(jsToMap(metadata))};

      if (error != null) {
        data["error"] = mapFromError(jsToMap(error));
      }

      _sendEvent(LinkExit.fromJson(data));
    });

    /// onLoad handler
    options.onLoad = allowInterop(() {});

    if (configuration is LinkTokenConfiguration) {
      options.token = configuration.token;
      options.receivedRedirectUri = configuration.receivedRedirectUri;
    } else if (configuration is LegacyLinkConfiguration) {
      options.token = configuration.token;
      options.key = configuration.publicKey;
      options.clientName = configuration.clientName;
      options.env = configuration.environment?.toString().split('.').last;
      options.linkCustomizationName = configuration.linkCustomizationName;
      options.language = configuration.language;
      options.webhook = configuration.webhook;
      options.userEmailAddress = configuration.userEmailAddress;
      options.userPhoneNumber = configuration.userPhoneNumber;
      options.oauthNonce = configuration.oauthConfiguration?.nonce;
      options.oauthRedirectUri = configuration.oauthConfiguration?.redirectUri;
      options.countryCodes = configuration.countryCodes ?? [''];
      options.product = configuration.products?.map((p) => p.toString().split('.').last).toList() ?? [''];
    }

    Plaid.create(options).open();
  }

  /// Closes Plaid Link View
  Future<void> close() async {}

  /// Send [LinkObject] event to stream
  void _sendEvent(LinkObject obj) {
    if (_onObjectsController != null) {
      _onObjectsController!.add(obj);
    }
  }

  /// A broadcast stream for plaid events
  @override
  Stream<LinkObject> get onObject {
    if (_onObjectsController == null) {
      _onObjectsController = StreamController<LinkObject>();
      _onObjects = _onObjectsController!.stream.asBroadcastStream();
    }

    return _onObjects;
  }

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

    result["institution"] = {"id": institutionMap["institution_id"] ?? "", "name": institutionMap["name"] ?? ""};
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

    result["institution"] = {"id": "", "name": ""};
    result["requestId"] = data["request_id"] ?? "";
    result["linkSessionId"] = data["link_session_id"] ?? "";
    result["status"] = data["status"] ?? "";

    if (data["institution"] != null) {
      Map<dynamic, dynamic> institutionMap = jsToMap(data["institution"]);
      result["institution"] = {"id": institutionMap["institution_id"] ?? "", "name": institutionMap["name"] ?? ""};
    }

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
