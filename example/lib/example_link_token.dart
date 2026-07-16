import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';

class ExampleLinkToken extends StatefulWidget {
  const ExampleLinkToken({super.key, required this.linkToken});

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
  bool _isLinkReady = false;
  LinkSessionType _sessionType = LinkSessionType.standard;

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
      await PlaidLink.open();
      if (mounted) {
        setState(() {
          _configuration = null;
          _isLinkReady = false;
        });
      }
    } catch (e) {
      debugPrint("Error opening Link: $e");
    }
  }

  void _createLinkTokenConfiguration() async {
    final configuration = LinkTokenConfiguration(
      token: widget.linkToken,
      sessionType: _sessionType,
    );
    setState(() {
      _isLoadingConfiguration = true;
      _isLinkReady = false;
    });

    try {
      await PlaidLink.create(configuration: configuration);
      if (mounted) {
        setState(() => _configuration = configuration);
      }
    } catch (error) {
      debugPrint("Error creating Link: $error");
    } finally {
      if (mounted) {
        setState(() => _isLoadingConfiguration = false);
      }
    }
  }

  void _onLoad(_) {
    debugPrint("LinkTokenConfiguration Loaded");
    if (mounted) {
      setState(() => _isLinkReady = true);
    }
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
          DropdownButtonFormField<LinkSessionType>(
            initialValue: _sessionType,
            decoration: const InputDecoration(labelText: "Session type"),
            items: LinkSessionType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.name)),
                )
                .toList(),
            onChanged: _isLoadingConfiguration
                ? null
                : (type) {
                    if (type == null) return;
                    setState(() {
                      _sessionType = type;
                      _configuration = null;
                      _isLinkReady = false;
                    });
                  },
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _createLinkTokenConfiguration,
            child: _isLoadingConfiguration
                ? const SizedBox(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(),
                  )
                : const Text("Create Link Token Configuration"),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _configuration != null && _isLinkReady
                ? _openLink
                : null,
            child: const Text("Open"),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed:
                _configuration != null && _sessionType == LinkSessionType.layer
                ? () {
                    PlaidLink.submit(
                      SubmissionData(
                        phoneNumber: "14155550015",
                        dateOfBirth: "1975-01-18",
                        params: {"client_user_id": "optional-user-id"},
                      ),
                    );
                  }
                : null,
            child: const Text("Submit Phone and Date of Birth"),
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
