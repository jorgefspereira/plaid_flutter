import 'metadata.dart';

/// Base for link events
abstract class LinkObject {
  Map<String, dynamic> toJson();
}

/// Success event object
class LinkSuccess extends LinkObject {
  /// The public token for the linked item. It is a string.
  final String publicToken;

  /// The additional data related to the link session and account. It is an [LinkSuccessMetadata] object.
  final LinkSuccessMetadata metadata;

  LinkSuccess({
    required this.publicToken,
    required this.metadata,
  });

  factory LinkSuccess.fromJson(dynamic json) {
    return LinkSuccess(
      publicToken: json["publicToken"],
      metadata: LinkSuccessMetadata.fromJson(json["metadata"]),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'publicToken': publicToken,
      'metadata': metadata.description(),
    };
  }
}

/// Exit event object
class LinkExit extends LinkObject {
  /// The error code. (can be null)
  final LinkError? error;

  ///  An [LinkExitMetadata] object containing information about the last error encountered by the user (if any), institution selected by the user, and the most recent API request ID, and the Link session ID.
  final LinkExitMetadata metadata;

  LinkExit({
    this.error,
    required this.metadata,
  });

  factory LinkExit.fromJson(dynamic json) {
    return LinkExit(
      error: json["error"] != null ? LinkError.fromJson(json["error"]) : null,
      metadata: LinkExitMetadata.fromJson(json["metadata"]),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'error': error,
      'metadata': metadata.description(),
    };
  }
}

/// Event object
class LinkEvent extends LinkObject {
  /// A string representing the event that has just occurred in the Link flow.
  final String name;

  /// An [LinkEventMetadata] object containing information about the event.
  final LinkEventMetadata metadata;

  LinkEvent({
    required this.name,
    required this.metadata,
  });

  factory LinkEvent.fromJson(dynamic json) {
    return LinkEvent(
      name: json["name"],
      metadata: LinkEventMetadata.fromJson(json["metadata"]),
    );
  }
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'metadata': metadata.description(),
    };
  }
}
