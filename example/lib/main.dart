import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PlaidLink _plaidPublicKey, _plaidLinkToken;

  @override
  void initState() {
    super.initState();

    LegacyLinkConfiguration publicKeyConfiguration = LegacyLinkConfiguration(
      clientName: "CLIENT_NAME",
      publicKey: "PUBLIC_KEY",
      environment: LinkEnvironment.sandbox,
      products: <LinkProduct>[
        LinkProduct.auth,
      ],
      language: "en",
      countryCodes: ['US'],
      userLegalName: "John Appleseed",
      userEmailAddress: "jappleseed@youapp.com",
      userPhoneNumber: "+1 (512) 555-1234",
    );
    
    LinkConfiguration linkTokenConfiguration = LinkConfiguration(
      token: "GENERATED_LINK_TOKEN",
    );

    _plaidPublicKey = PlaidLink(
      configuration: publicKeyConfiguration,
      onSuccess: _onSuccessCallback,
      onEvent: _onEventCallback,
      onExit: _onExitCallback,
    );

    _plaidLinkToken = PlaidLink(
      configuration: linkTokenConfiguration,
      onSuccess: _onSuccessCallback,
      onEvent: _onEventCallback,
      onExit: _onExitCallback,
    );
  }

  void _onSuccessCallback(String publicToken, LinkSuccessMetadata metadata) {
    print("onSuccess: $publicToken, metadata: ${metadata.description()}");
  }

  void _onEventCallback(String event, LinkEventMetadata metadata) {
    print("onEvent: $event, metadata: ${metadata.description()}");
  }

  void _onExitCallback(LinkError error, LinkExitMetadata metadata) {
    print("onExit: ${error.description()}, metadata: ${metadata.description()}");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          width: double.infinity,
          color: Colors.lightBlue,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                onPressed: () => _plaidPublicKey.open(),
                child: Text("Open Plaid Link (Public Key)"),
              ),
              RaisedButton(
                onPressed: () => _plaidLinkToken.open(),
                child: Text("Open Plaid Link (Link Token)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
