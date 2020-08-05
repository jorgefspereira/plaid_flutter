import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PlaidLink _plaidLink;

  @override
  void initState() {
    super.initState();

    LinkConfiguration configuration = LinkConfiguration(
      clientName: "CLIENT_NAME",
      publicKey: "PUBLIC_KEY",
      env: LinkEnv.sandbox,
      products: <LinkProduct>[
        LinkProduct.auth,
      ],
      accountSubtypes: {
        "depository": ["checking", "savings"],
      },
      language: "en",
      countryCodes: ['US'],
      userLegalName: "John Appleseed",
      userEmailAddress: "jappleseed@youapp.com",
      userPhoneNumber: "+1 (512) 555-1234",
    );

    _plaidLink = PlaidLink(
      configuration: configuration,
      onSuccess: (publicToken, metadata) {
        print("onSuccess: $publicToken, metadata: ${metadata.description()}");
      },
      onEvent: (event, metadata) {
        print("onEvent: $event, metadata: ${metadata.description()}");
      },
      onExit: (error, metadata) {
        print("onExit: $error, metadata: ${metadata.description()}");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          color: Colors.lightBlue,
          child: Center(
            child: RaisedButton(
              onPressed: () => _plaidLink.open(),
              child: Text("Open Plaid Link"),
            ),
          ),
        ),
      ),
    );
  }
}
