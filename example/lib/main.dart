import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  LinkConfiguration? _configuration;
  StreamSubscription<LinkObject>? _stream;
  LinkObject? _successObject;

  @override
  void initState() {
    super.initState();
    _stream = PlaidLink.onEvent.listen(_onEvent);
  }

  @override
  void dispose() {
    _stream?.cancel();
    super.dispose();
  }

  void _createLegacyTokenConfiguration() {
    setState(() {
      _configuration = LegacyLinkConfiguration(
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
    });
  }

  void _createLinkTokenConfiguration() {
    setState(() {
      _configuration = LinkTokenConfiguration(
        token: "GENERATED_LINK_TOKEN",
      );
    });
  }

  void _onEvent(LinkObject event) {
    if (event is LinkEvent) {
      print("onEvent: ${event.name}, metadata: ${event.metadata.description()}");
    } else if (event is LinkSuccess) {
      print("onSuccess: ${event.publicToken}, metadata: ${event.metadata.description()}");
      setState(() => _successObject = event);
    } else if (event is LinkExit) {
      print("onExit metadata: ${event.metadata.description()}, error: ${event.error?.description()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          width: double.infinity,
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Text(
                    _configuration?.toJson().toString() ?? "",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _createLegacyTokenConfiguration,
                child: Text("Create Legacy Token Configuration"),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: _createLinkTokenConfiguration,
                child: Text("Create Link Token Configuration"),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: _configuration != null ? () => PlaidLink.open(configuration: _configuration!) : null,
                child: Text("Open"),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _successObject?.toJson().toString() ?? "",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
