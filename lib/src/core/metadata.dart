/// The error object
class LinkError {
  /// The error code that the user encountered.
  /// Each errorCode has an associated errorType, which is a broad categorization of the error.
  final String code;

  /// The error type that the user encountered.
  final String type;

  /// A developer-friendly representation of the error code.
  final String message;

  /// A user-friendly representation of the error code or nil if the error is not related to user action.
  /// This may change over time and is not safe for programmatic use.
  final String? displayMessage;

  LinkError({
    required this.code,
    required this.type,
    required this.message,
    this.displayMessage,
  });

  factory LinkError.fromJson(dynamic json) {
    return LinkError(
      code: json["errorCode"],
      type: json["errorType"],
      message: json["errorMessage"],
      displayMessage: json["errorDisplayMessage"],
    );
  }

  String description() {
    return "[code: $code, type: $type, message: $message, displayMessage: $displayMessage]";
  }
}

/// The institution object
class LinkInstitution {
  /// The Plaid institution identifier
  final String id;

  /// The full institution name, such as 'Bank of America'
  final String name;

  LinkInstitution({
    required this.id,
    required this.name,
  });

  factory LinkInstitution.fromJson(dynamic json) {
    return LinkInstitution(
      id: json["id"],
      name: json["name"],
    );
  }

  String description() {
    return "id: $id, name: $name";
  }
}

/// The account object
class LinkAccount {
  /// The id of the selected account
  final String id;

  /// The last 2-4 alphanumeric characters of an account's official account number. Note that the mask may be non-unique between an Item's accounts, it may also not match the mask that the bank displays to the user. This field is nullable.
  final String? mask;

  /// The name of the selected account
  final String name;

  /// The account type
  final String type;

  /// The account subtype
  final String subtype;

  /// When micro-deposit-based verification is being used, the accounts object includes an Item's verification_status. Possible values are:
  /// - pending_automatic_verification: The Item is pending automatic verification.
  /// - pending_manual_verification: The Item is pending manual micro-deposit verification. Items remain in this state until the user successfully verifies the two amounts.
  /// - automatically_verified: The Item has successfully been automatically verified.
  /// - manually_verified: The Item has successfully been manually verified.
  /// - verification_expired: Plaid was unable to automatically verify the deposit within 7 calendar days and will no longer attempt to validate the Item. Users may retry by submitting their information again through Link.
  /// - verification_failed: The Item failed manual micro-deposit verification because the user exhausted all 3 verification attempts. Users may retry by submitting their information again through Link.
  final String? verificationStatus;

  LinkAccount({
    required this.id,
    required this.mask,
    required this.name,
    required this.type,
    required this.subtype,
    required this.verificationStatus,
  });

  factory LinkAccount.fromJson(dynamic json) {
    return LinkAccount(
      id: json["id"],
      name: json["name"],
      mask: json["mask"],
      type: json["type"],
      subtype: json["subtype"],
      verificationStatus: json["verificationStatus"],
    );
  }

  String description() {
    return "[id: $id, mask: $mask, name: $name, type: $type, subtype: $subtype, verification_status: $verificationStatus]";
  }
}

/// The metadata object for the onSuccess callback
class LinkSuccessMetadata {
  /// A unique identifier associated with a user's actions and events through the Link flow. Include this identifier when opening a support ticket for faster turnaround.
  final String linkSessionId;

  /// An institution object. If the Item was created via Same-Day micro-deposit verification, will be null.
  ///   * name: The full institution name, such as 'Bank of America'
  ///   * institution_id: The institution ID, such as ins_100000
  final LinkInstitution? institution;

  /// A list of objects with the following properties:
  ///   * id: the id of the selected account
  ///   * name: the name of the selected account
  ///   * mask: the last 2-4 alphanumeric characters of an account's official account number. Note that the mask may be non-unique between an Item's accounts, it may also not match the mask that the bank displays to the user. This field is nullable.
  ///   * type: the account type
  ///   * subtype: the account subtype
  final List<LinkAccount> accounts;

  LinkSuccessMetadata({
    required this.linkSessionId,
    required this.institution,
    required this.accounts,
  });

  factory LinkSuccessMetadata.fromJson(dynamic json) {
    return LinkSuccessMetadata(
      linkSessionId: json["linkSessionId"],
      institution: json["institution"] != null ? LinkInstitution.fromJson(json["institution"]) : null,
      accounts: (json["accounts"] as List).map((info) => LinkAccount.fromJson(info)).toList(),
    );
  }

  String description() {
    String description =
        "linkSessionId: $linkSessionId, institution.id: ${institution?.id}, institution.name: ${institution?.name}, accounts: ";

    for (LinkAccount a in accounts) {
      description += a.description();
    }

    return description;
  }
}

/// The metadata object for the onExit callback
class LinkExitMetadata {
  /// The value of the status key indicates the point at which the user exited the Link flow. Can be one of the following values:
  /// - requiresQuestions: User prompted to answer security question(s)
  /// - requiresSelections: User prompted to answer multiple choice question(s)
  /// - requiresCode: User prompted to provide a one-time passcode
  /// - chooseDevice: User prompted to select a device on which to receive a one-time passcode
  /// - requiresCredentials:	User prompted to provide credentials for the selected financial institution or has not yet selected a financial institution
  /// - requiresAccountSelection: User prompted to select one or more financial accounts to share.
  /// - institutionNotFound: User exited the Link flow after unsuccessfully (no results returned) searching for a financial institution
  /// - unknown: The exit status has not been defined in the current version of the SDK. The unknown case has an associated value carrying the original exit status as sent by the Plaid API.
  final String? status;

  /// The request ID for the last request made by Link. This can be shared with Plaid Support to expedite investigation.
  final String? requestId;

  /// A unique identifier associated with a user's actions and events through the Link flow. Include this identifier when opening a support ticket for faster turnaround.
  final String? linkSessionId;

  /// An institution object. If the Item was created via Same-Day micro-deposit verification, will be omitted.
  ///   * name: The full institution name, such as 'Bank of America'
  ///   * institution_id: The institution ID, such as ins_100000
  final LinkInstitution? institution;

  LinkExitMetadata({
    required this.status,
    required this.requestId,
    required this.linkSessionId,
    required this.institution,
  });

  factory LinkExitMetadata.fromJson(dynamic json) {
    return LinkExitMetadata(
      status: json["status"],
      requestId: json["requestId"],
      linkSessionId: json["linkSessionId"],
      institution: json["institution"] != null ? LinkInstitution.fromJson(json["institution"]) : null,
    );
  }

  String description() {
    return "status: $status, linkSessionId: $linkSessionId, requestId: $requestId, institution.id: ${institution?.id}, institution.name: ${institution?.name}";
  }
}

/// The metadata object for the onEvent callback
class LinkEventMetadata {
  /// The error code that the user encountered. Emitted by: ERROR, EXIT.
  final String? errorCode;

  /// The error message that the user encountered. Emitted by: ERROR, EXIT.
  final String? errorMesssage;

  /// The error type that the user encountered. Emitted by: ERROR, EXIT.
  final String? errorType;

  /// The status key indicates the point at which the user exited the Link flow. Emitted by: EXIT.
  final String? exitStatus;

  /// The ID of the selected institution. Emitted by: all events.
  final String? institutionId;

  /// The name of the selected institution. Emitted by: all events.
  final String? institutionName;

  /// The query used to search for institutions. Emitted by: SEARCH_INSTITUTION.
  final String? institutionSearchQuery;

  /// The link_session_id is a unique identifier for a single session of Link. It's always available and will stay constant throughout the flow. Emitted by: all events.
  final String linkSessionId;

  /// If set, the user has encountered one of the following MFA types: code, device, questions, selections. Emitted by: SUBMIT_MFA and TRANSITION_VIEW when view_name is MFA.
  final String? mfaType;

  /// The request ID for the last request made by Link. This can be shared with Plaid Support to expedite investigation. Emitted by: all events.
  final String? requestId;

  /// An ISO 8601 representation of when the event occurred. For example 2017-09-14T14:42:19.350Z. Emitted by: all events.
  final String timestamp;

  /// The name of the view that is being transitioned to. Emitted by: TRANSITION_VIEW.
  final String? viewName;

  /// Either the verification method for a matched institution selected by the user or the Auth Type Select flow type selected by the user. If selection is used to describe selected verification method, then possible values are phoneotp or password;  if selection is used to describe the selected Auth Type Select flow, then possible values are flow_type_manual or flow_type_instant. Emitted by: MATCHED_SELECT_VERIFY_METHOD and SELECT_AUTH_TYPE.
  final String? selection;

  /// The routing number submitted by user at the micro-deposits routing number pane. Emitted by SUBMIT_ROUTING_NUMBER.
  final String? routingNumber;

  /// The reason this institution was matched, which will be either returning_user or routing_number. Emitted by: matchedSelectInstitution.
  final String? matchReason;

  /// The account number mask extracted from the user-provided account number. If the user-inputted account number is four digits long, account_number_mask is empty. Emitted by SUBMIT_ACCOUNT_NUMBER
  final String? accountNumberMask;

  LinkEventMetadata({
    required this.viewName,
    required this.exitStatus,
    required this.mfaType,
    required this.requestId,
    required this.timestamp,
    required this.linkSessionId,
    required this.institutionName,
    required this.institutionId,
    required this.institutionSearchQuery,
    required this.errorType,
    required this.errorCode,
    required this.errorMesssage,
    required this.selection,
    required this.routingNumber,
    required this.matchReason,
    required this.accountNumberMask,
  });

  factory LinkEventMetadata.fromJson(dynamic json) {
    return LinkEventMetadata(
      viewName: json["viewName"],
      exitStatus: json["exitStatus"],
      mfaType: json["mfaType"],
      requestId: json["requestId"],
      timestamp: json["timestamp"],
      linkSessionId: json["linkSessionId"],
      institutionName: json["institutionName"],
      institutionId: json["institutionId"],
      institutionSearchQuery: json["institutionSearchQuery"],
      errorType: json["errorType"],
      errorCode: json["errorCode"],
      errorMesssage: json["errorMessage"],
      selection: json["selection"],
      routingNumber: json["routingNumber"],
      matchReason: json["matchReason"],
      accountNumberMask: json["accountNumberMask"],
    );
  }

  String description() {
    return "viewName: $viewName, exitStatus: $exitStatus, mfaType: $mfaType, requestId: $requestId, timestamp: $timestamp, linkSessionId: $linkSessionId, institutionId: $institutionId, institutionName: $institutionName, institutionSearchQuery: $institutionSearchQuery, errorType: $errorType, errorCode: $errorCode, errorMesssage: $errorMesssage, selection: $selection, routingNumber: $routingNumber, matchReason: $matchReason, accountNumberMask: $accountNumberMask";
  }
}
