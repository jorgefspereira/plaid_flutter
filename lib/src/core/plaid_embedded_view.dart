import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlaidEmbeddedView extends StatelessWidget {
  const PlaidEmbeddedView({
    super.key,
    this.onPlatformViewCreated,
    required this.token,
  });

  final String token;
  final PlatformViewCreatedCallback? onPlatformViewCreated;

  @override
  Widget build(BuildContext context) {
    const viewType = 'plaid/embedded-view';

    // If you need Android support as well, switch to PlatformViewLink.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: {'token': token},
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: onPlatformViewCreated,
      );
    }
    return Text('$defaultTargetPlatform is not yet supported.');
  }
}
