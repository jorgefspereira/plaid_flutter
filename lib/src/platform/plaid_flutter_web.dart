import 'dart:async';
import 'dart:js_interop';

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

  /// Plaid JS object
  Plaid? _plaid;

  /// Factory method that initializes the Plaid plugin platform with an instance
  /// of the plugin for the web.
  static void registerWith(Registrar registrar) {
    PlaidPlatformInterface.instance = PlaidFlutterPlugin();
  }

  /// Creates a handler for Plaid Link. A one-time use object used to open a Link session.
  @override
  Future<void> create({required LinkTokenConfiguration configuration}) async {
    final webConfiguration = WebConfiguration(
      token: configuration.token,
      receivedRedirectUri: configuration.receivedRedirectUri,
      onSuccess: ((JSAny publicToken, JSAny metadata) {
        Map<String, dynamic> data = {
          'publicToken': asString(publicToken.dartify()),
          'metadata': mapFromSuccessMetadata(jsToMap(metadata)),
        };

        _sendEvent(LinkSuccess.fromJson(data));
      }).toJS,
      onEvent: ((JSString event, JSAny metadata) {
        Map<String, dynamic> data = {
          'name': event.toDart,
          'metadata': mapFromEventMetadata(jsToMap(metadata)),
        };

        _sendEvent(LinkEvent.fromJson(data));
      }).toJS,
      onExit: ((JSAny? error, JSAny metadata) {
        Map<String, dynamic> data = {
          'metadata': mapFromExitMetadata(jsToMap(metadata)),
        };

        if (error != null) {
          data["error"] = mapFromError(jsToMap(error));
        }

        _sendEvent(LinkExit.fromJson(data));
        _dispose();
      }).toJS,
      onLoad: () {}.toJS,
    );
    _plaid = Plaid.create(webConfiguration);
  }

  /// Open Plaid Link by calling open on the Handler object.
  @override
  Future<void> open() async {
    _plaid?.open();
  }

  /// Closes Plaid Link View
  @override
  Future<void> close() async {
    _plaid?.destroy();
  }

  /// It allows the client application to submit additional user-collected data to the Link flow (e.g. a user phone number) for the Layer product.
  @override
  Future<void> submit(SubmissionData data) async {
    SubmitConfiguration options = SubmitConfiguration(
      phoneNumber: data.phoneNumber,
      dateOfBirth: data.dateOfBirth,
    );
    _plaid?.submit(options);
  }

  /// Dispose objects
  void _dispose() {
    _onObjectsController?.close();
    _onObjectsController = null;
  }

  /// Send [LinkObject] event to stream
  void _sendEvent(LinkObject obj) {
    _onObjectsController?.add(obj);
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

    result["errorType"] = asString(data["error_type"] ?? data["errorType"]);
    result["errorCode"] = asString(data["error_code"] ?? data["errorCode"]);
    result["errorMessage"] = asString(
      data["error_message"] ?? data["errorMessage"],
    );
    result["errorDisplayMessage"] = asNullableString(
      data["error_display_message"] ?? data["errorDisplayMessage"],
    );

    return result;
  }

  Map<String, dynamic> mapFromSuccessMetadata(Map<dynamic, dynamic> data) {
    Map<String, dynamic> result = {};

    Map<dynamic, dynamic> institutionMap = jsToMap(data["institution"]);

    result["institution"] = {
      "id": asString(institutionMap["institution_id"] ?? institutionMap["id"]),
      "name": asString(institutionMap["name"]),
    };
    result["linkSessionId"] = asString(
      data["link_session_id"] ?? data["linkSessionId"],
    );

    List<dynamic> accountsList = [];

    for (dynamic item in asList(data["accounts"])) {
      Map<dynamic, dynamic> accountMap = jsToMap(item);
      Map<String, dynamic> account = {};

      account["id"] = asString(accountMap["id"]);
      account["name"] = asString(accountMap["name"]);
      account["type"] = asString(accountMap["type"]);
      account["subtype"] = asString(accountMap["subtype"]);
      account["mask"] = asNullableString(accountMap["mask"]);
      account["verificationStatus"] = asNullableString(
        accountMap["verification_status"] ?? accountMap["verificationStatus"],
      );

      accountsList.add(account);
    }

    result["accounts"] = accountsList;

    return result;
  }

  Map<String, dynamic> mapFromExitMetadata(Map<dynamic, dynamic> data) {
    Map<String, dynamic> result = {};

    result["institution"] = {"id": "", "name": ""};
    result["requestId"] = asString(data["request_id"] ?? data["requestId"]);
    result["linkSessionId"] = asString(
      data["link_session_id"] ?? data["linkSessionId"],
    );
    result["status"] = asString(data["status"]);

    if (data["institution"] != null) {
      Map<dynamic, dynamic> institutionMap = jsToMap(data["institution"]);
      result["institution"] = {
        "id": asString(
          institutionMap["institution_id"] ?? institutionMap["id"],
        ),
        "name": asString(institutionMap["name"]),
      };
    }

    return result;
  }

  Map<String, dynamic> mapFromEventMetadata(Map<dynamic, dynamic> data) {
    Map<String, dynamic> result = {};

    result['errorCode'] = asString(data['error_code'] ?? data['errorCode']);
    result['errorMessage'] = asString(
      data['error_message'] ?? data['errorMessage'],
    );
    result['errorType'] = asString(data['error_type'] ?? data['errorType']);
    result['exitStatus'] = asString(data['exit_status'] ?? data['exitStatus']);
    result['institutionSearchQuery'] = asString(
      data['institution_search_query'] ?? data['institutionSearchQuery'],
    );
    result['institutionName'] = asString(
      data['institution_name'] ?? data['institutionName'],
    );
    result['institutionId'] = asString(
      data['institution_id'] ?? data['institutionId'],
    );
    result['linkSessionId'] = asString(
      data['link_session_id'] ?? data['linkSessionId'],
    );
    result['mfaType'] = asString(data['mfa_type'] ?? data['mfaType']);
    result['viewName'] = asString(data['view_name'] ?? data['viewName']);
    result['requestId'] = asString(data['request_id'] ?? data['requestId']);
    result['timestamp'] = asString(data['timestamp']);
    result['accountNumberMask'] = asString(
      data['account_number_mask'] ?? data['accountNumberMask'],
    );
    result['isUpdateMode'] = asString(
      data['is_update_mode'] ?? data['isUpdateMode'],
    );
    result['matchReason'] = asString(
      data['match_reason'] ?? data['matchReason'],
    );
    result['routingNumber'] = asString(
      data['routing_number'] ?? data['routingNumber'],
    );
    result['selection'] = asString(data['selection']);

    return result;
  }

  String asString(Object? value) {
    if (value == null) {
      return "";
    }
    return value.toString();
  }

  String? asNullableString(Object? value) {
    return value?.toString();
  }

  List<dynamic> asList(Object? value) {
    if (value is List) {
      return value;
    }
    return const [];
  }
}
