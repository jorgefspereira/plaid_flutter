import 'package:flutter/material.dart';

import 'example_embedded_link.dart';
import 'example_link_token.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  LinkTokenConfiguration? _configuration;
  StreamSubscription<LinkEvent>? _streamEvent;
  StreamSubscription<LinkExit>? _streamExit;
  StreamSubscription<LinkSuccess>? _streamSuccess;
  StreamSubscription<LinkOnLoad>? _streamOnLoad;

  LinkObject? _successObject;
  bool _isLoadingConfiguration = false;

  @override
  void initState() {
    super.initState();

    _streamEvent = PlaidLink.onEvent.listen(_onEvent);
    _streamExit = PlaidLink.onExit.listen(_onExit);
    _streamSuccess = PlaidLink.onSuccess.listen(_onSuccess);
    _streamOnLoad = PlaidLink.onLoad.listen(_onLoad);
  }

  @override
  void dispose() {
    _streamEvent?.cancel();
    _streamExit?.cancel();
    _streamSuccess?.cancel();
    _streamOnLoad?.cancel();
    super.dispose();
  }

  void _openLink() async {
    if (_configuration == null) {
      print("Configuration is null, please create it first.");
      return;
    }

    try {
      setState(() => _configuration = null);
      await PlaidLink.open();
    } catch (e) {
      print("Error opening Link: $e");
    }
  }

  void _createLinkTokenConfiguration() async {
    LinkTokenConfiguration configuration = const LinkTokenConfiguration(
      token: "GENERATED_LINK_TOKEN", // Replace with your actual link token
    );
    setState(() => _isLoadingConfiguration = true);

    await PlaidLink.create(configuration: configuration);

    setState(() {
      _isLoadingConfiguration = false;
      _configuration = configuration;
    });
  }

  void _onLoad(_) {
    print("LinkTokenConfiguration Loaded");
  }

  void _onEvent(LinkEvent event) {
    final name = event.name;
    final metadata = event.metadata.description();
    print("onEvent: $name, metadata: $metadata");
  }

  void _onSuccess(LinkSuccess event) {
    final token = event.publicToken;
    final metadata = event.metadata.description();
    print("onSuccess: $token, metadata: $metadata");
    setState(() => _successObject = event);
  }

  void _onExit(LinkExit event) {
    final metadata = event.metadata.description();
    final error = event.error?.description();
    print("onExit metadata: $metadata, error: $error");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          width: double.infinity,
          color: Colors.grey[200],
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                onPressed: _createLinkTokenConfiguration,
                child: _isLoadingConfiguration
                    ? const SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator())
                    : const Text("Create Link Token Configuration"),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _openLink,
                child: const Text("Open"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _configuration != null
                    ? () {
                        PlaidLink.submit(
                          SubmissionData(
                            phoneNumber: "14155550015",
                          ),
                        );
                      }
                    : null,
                child: const Text("Submit Phone Number"),
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
