import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';

class ExampleLinkToken extends StatefulWidget {
  const ExampleLinkToken({
    super.key,
    required this.linkToken,
  });

  final String linkToken;

  @override
  State<ExampleLinkToken> createState() => _ExampleLinkTokenState();
}

class _ExampleLinkTokenState extends State<ExampleLinkToken> {
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
    try {
      setState(() => _configuration = null);
      await PlaidLink.open();
    } catch (e) {
      debugPrint("Error opening Link: $e");
    }
  }

  void _createLinkTokenConfiguration() async {
    LinkTokenConfiguration configuration = LinkTokenConfiguration(token: widget.linkToken);
    setState(() => _isLoadingConfiguration = true);

    await PlaidLink.create(configuration: configuration);

    setState(() {
      _isLoadingConfiguration = false;
      _configuration = configuration;
    });
  }

  void _onLoad(_) {
    debugPrint("LinkTokenConfiguration Loaded");
  }

  void _onEvent(LinkEvent event) {
    final name = event.name;
    final metadata = event.metadata.description();
    debugPrint("onEvent: $name, metadata: $metadata");
  }

  void _onSuccess(LinkSuccess event) {
    final token = event.publicToken;
    final metadata = event.metadata.description();
    debugPrint("onSuccess: $token, metadata: $metadata");
    setState(() => _successObject = event);
  }

  void _onExit(LinkExit event) {
    final metadata = event.metadata.description();
    final error = event.error?.description();
    debugPrint("onExit metadata: $metadata, error: $error");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator())
                : const Text("Create Link Token Configuration"),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _configuration != null ? _openLink : null,
            child: const Text("Open"),
          ),
          const SizedBox(height: 15),
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
    );
  }
}
