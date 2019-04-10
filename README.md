# Plaid Link plugin for Flutter

A Flutter plugin for [Plaid Link](https://github.com/plaid/link).

*Note*: This plugin is still under development, and some APIs might not be available yet. Feedback and Pull Requests are most welcome!

## Installation

The plugin is not published yet. Download a local copy and add as [dependency in your pubspec.yaml](https://flutter.io/platform-plugins/):

``` yaml
	plaid_flutter:
		path: PATH_TO_PLAID_FLUTTER_PLUGIN_FOLDER
``` 

### Android

Not supported yet.
	
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
      clientName: "CLIENT_NAME",
      publicKey: "PUBLIC_KEY",
      env: EnvOption.sandbox,
      products: <ProductOption>[
        ProductOption.auth,
      ],
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

- [ ] Android support
- [ ] [iOS Prepare for distribution](https://plaid.com/docs/link/ios/#prepare-distribution-script)
- [ ] Implement tests
