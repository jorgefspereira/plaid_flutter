import Foundation
import LinkKit

extension Institution {
  var plaidDictionary: [String: Any] {
    [
      "name": name,
      "id": id,
    ]
  }

  static var plaidEmptyDictionary: [String: Any] {
    [
      "name": "",
      "id": "",
    ]
  }
}

extension Account {
  var plaidDictionary: [String: Any] {
    [
      "id": id,
      "name": name,
      "mask": mask ?? "",
      "subtype": subtype.description,
      "type": subtype.type,
      "verificationStatus": verificationStatus?.description ?? "",
    ]
  }
}

extension LinkSuccess {
  var plaidDictionary: [String: Any] {
    [
      "publicToken": publicToken,
      "metadata": [
        "linkSessionId": metadata.linkSessionID,
        "institution": metadata.institution.plaidDictionary,
        "accounts": metadata.accounts.map(\.plaidDictionary),
        "metadataJson": metadata.metadataJSON ?? "",
      ],
    ]
  }
}

extension LinkExit {
  var plaidDictionary: [String: Any] {
    var dictionary: [String: Any] = [
      "metadata": [
        "status": metadata.status?.description ?? "",
        "institution": metadata.institution?.plaidDictionary
          ?? Institution.plaidEmptyDictionary,
        "requestId": metadata.requestID ?? "",
        "linkSessionId": metadata.linkSessionID ?? "",
        "metadataJson": metadata.metadataJSON ?? "",
      ]
    ]

    if let error {
      dictionary["error"] = error.plaidDictionary
    }

    return dictionary
  }
}

extension LinkEvent {
  var plaidDictionary: [String: Any] {
    [
      "name": eventName.description,
      "metadata": metadata.plaidDictionary,
    ]
  }
}

extension EventMetadata {
  var plaidDictionary: [String: Any] {
    [
      "errorType": errorCode?.plaidErrorType ?? "",
      "errorCode": errorCode?.plaidErrorCode ?? "",
      "errorMessage": errorMessage ?? "",
      "exitStatus": exitStatus?.description ?? "",
      "institutionId": institutionID ?? "",
      "institutionName": institutionName ?? "",
      "institutionSearchQuery": institutionSearchQuery ?? "",
      "linkSessionId": linkSessionID,
      "mfaType": mfaType?.description ?? "",
      "requestId": requestID ?? "",
      "issueId": issueID ?? "",
      "issueDescription": issueDescription ?? "",
      "issueDetectedAt": issueDetectedAt.map(plaidISO8601String) ?? "",
      "timestamp": plaidISO8601String(timestamp),
      "viewName": viewName?.description ?? "",
      "metadataJson": metadataJSON ?? "",
      "accountNumberMask": accountNumberMask ?? "",
      "isUpdateMode": isUpdateMode ?? "",
      "matchReason": matchReason ?? "",
      "routingNumber": routingNumber ?? "",
      "selection": selection ?? "",
    ]
  }
}

extension ExitError {
  var plaidDictionary: [String: Any] {
    [
      "errorType": errorCode.plaidErrorType,
      "errorCode": errorCode.plaidErrorCode,
      "errorMessage": errorMessage,
      "errorDisplayMessage": displayMessage ?? "",
      "errorJson": errorJSON ?? "",
    ]
  }
}

extension ExitErrorCode {
  var plaidErrorType: String {
    switch self {
    case .apiError:
      return "API_ERROR"
    case .authError:
      return "AUTH_ERROR"
    case .assetReportError:
      return "ASSET_REPORT_ERROR"
    case .internal:
      return "INTERNAL"
    case .institutionError:
      return "INSTITUTION_ERROR"
    case .itemError:
      return "ITEM_ERROR"
    case .invalidInput:
      return "INVALID_INPUT"
    case .invalidRequest:
      return "INVALID_REQUEST"
    case .rateLimitExceeded:
      return "RATE_LIMIT_EXCEEDED"
    case .unknown(let type, _):
      return type
    @unknown default:
      return "UNKNOWN"
    }
  }

  var plaidErrorCode: String {
    switch self {
    case .apiError(let code):
      return code.description
    case .authError(let code):
      return code.description
    case .assetReportError(let code):
      return code.description
    case .internal(let code):
      return code
    case .institutionError(let code):
      return code.description
    case .itemError(let code):
      return code.description
    case .invalidInput(let code):
      return code.description
    case .invalidRequest(let code):
      return code.description
    case .rateLimitExceeded(let code):
      return code.description
    case .unknown(_, let code):
      return code
    @unknown default:
      return "UNKNOWN"
    }
  }
}

@available(iOS 17.4, *)
extension FinanceKitError {
  var plaidFlutterErrorCode: String {
    switch self {
    case .invalidToken:
      return "INVALID_TOKEN"
    case .permissionError:
      return "PERMISSION_ERROR"
    case .linkApiError:
      return "LINK_API_ERROR"
    case .permissionAccessError:
      return "PERMISSION_ACCESS_ERROR"
    case .unknown:
      return "UNKNOWN"
    @unknown default:
      return "UNKNOWN"
    }
  }
}

private func plaidISO8601String(_ date: Date) -> String {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime]
  return formatter.string(from: date)
}
