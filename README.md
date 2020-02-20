# Plaid Link plugin for Flutter

[![pub](https://img.shields.io/pub/v/plaid_flutter.svg)](https://pub.dev/packages/plaid_flutter)

A Flutter plugin for [Plaid Link](https://github.com/plaid/link).

This plugin integrates the native SDKs:

- [Plaid Link iOS SDK](https://github.com/plaid/plaid-link-ios)
- [Plaid Link Android SDK](https://github.com/plaid/plaid-link-android)

*Note*: Feedback and Pull Requests are most welcome!

## Installation

Add `plaid_flutter` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

### iOS

1. Add a Run Script build phase *(name it Prepare for Distribution for example)* with the script below. Be sure to run this build phase after the Embed Frameworks build phase (or [CP] Embed Pods Frameworks build phase when integrating using CocoaPods)

``` sh
LINK_ROOT=${PODS_ROOT:+$PODS_ROOT/Plaid}
cp "${LINK_ROOT:-$PROJECT_DIR}"/LinkKit.framework/prepare_for_distribution.sh "${CODESIGNING_FOLDER_PATH}"/Frameworks/LinkKit.framework/prepare_for_distribution.sh
"${CODESIGNING_FOLDER_PATH}"/Frameworks/LinkKit.framework/prepare_for_distribution.sh
```

![](https://raw.githubusercontent.com/jorgefspereira/plaid_flutter/master/doc/images/edit_run_script_build_phase.jpg)

*NOTE: More info at [https://plaid.com/docs/link/ios](https://plaid.com/docs/link/ios).*

### Android

1. Log into your Plaid Dashboard at the API page and add a new Allowed Android package name *(for example com.plaid.example)* and a new Allowed redirect URI.

![](https://raw.githubusercontent.com/jorgefspereira/plaid_flutter/master/doc/images/register-app-id.png)
	
*NOTE: More info at [https://plaid.com/docs/link/android](https://plaid.com/docs/link/android).*

## Usage Example

``` dart
import 'package:plaid_flutter/plaid_flutter.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  PlaidLink _plaidLink;
  
  @override
  void initState() {
    super.initState();
  
    _plaidLink = PlaidLink(
      clientName: "CLIENT_NAME",        //required
      publicKey: "PUBLIC_KEY",          //required
      env: EnvOption.sandbox,           //required
      products: <ProductOption>[        //required
        ProductOption.auth,
      ],
      oauthRedirectUri: "myapp://test",
      oauthNonce: "XXXXXXXXXXXXXXXX",   
      onAccountLinked: (publicToken, metadata) { print("onAccountLinked: $publicToken metadata: $metadata"); },
      onAccountLinkError: (error, metadata) { print("onAccountError: $error metadata: $metadata"); },
      onEvent: (event, metadata) { print("onEvent: $event metadata: $metadata"); },
      onExit: (metadata) { print("onExit: $metadata"); },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: 
        Center( 
            child: 
            RaisedButton(
              onPressed: () {
                _plaidLink.open();
              },
              child: Text("Open Plaid Link"),
          	),
        ),
      ),
    );
  }
}
```

## TODOs

- [ ] RedirectUri on Android. Note: version 1.0.0 removed webviewRedirectUri from the LinkConfiguration.
- [ ] [Avoid iOS Prepare for distribution configuration](https://plaid.com/docs/link/ios/#prepare-distribution-script)
- [ ] Implement tests
