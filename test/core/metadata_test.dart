import 'package:flutter_test/flutter_test.dart';
import 'package:plaid_flutter/plaid_flutter.dart';

void main() {
  test('LinkError parses LinkKit 7 raw error metadata', () {
    final error = LinkError.fromJson({
      'errorCode': 'INVALID_LINK_TOKEN',
      'errorType': 'INVALID_INPUT',
      'errorMessage': 'The link token is invalid.',
      'errorDisplayMessage': 'Please try again.',
      'errorJson': '{"request_id":"request-id"}',
    });

    expect(error.errorJson, '{"request_id":"request-id"}');
  });

  group('LinkEventMetadata', () {
    test('parses LinkKit 7 issue metadata', () {
      final metadata = LinkEventMetadata.fromJson({
        'linkSessionId': 'session-id',
        'timestamp': '2026-07-15T17:00:00Z',
        'issueId': 'issue-id',
        'issueDescription': 'Institution connectivity issue',
        'issueDetectedAt': '2026-07-15T16:59:00Z',
      });

      expect(metadata.issueId, 'issue-id');
      expect(metadata.issueDescription, 'Institution connectivity issue');
      expect(metadata.issueDetectedAt, '2026-07-15T16:59:00Z');
    });

    test('keeps issue metadata optional for other platforms', () {
      final metadata = LinkEventMetadata.fromJson({
        'linkSessionId': 'session-id',
        'timestamp': '2026-07-15T17:00:00Z',
      });

      expect(metadata.issueId, isNull);
      expect(metadata.issueDescription, isNull);
      expect(metadata.issueDetectedAt, isNull);
    });
  });
}
