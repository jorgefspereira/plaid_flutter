import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';

class ExampleEmbeddedLink extends StatefulWidget {
  const ExampleEmbeddedLink({
    super.key,
    required this.linkToken,
  });

  final String linkToken;

  @override
  _ExampleEmbeddedLinkState createState() => _ExampleEmbeddedLinkState();
}

class _ExampleEmbeddedLinkState extends State<ExampleEmbeddedLink> {
  StreamSubscription<LinkEvent>? _streamEvent;
  StreamSubscription<LinkExit>? _streamExit;
  StreamSubscription<LinkSuccess>? _streamSuccess;

  @override
  void initState() {
    super.initState();

    _streamEvent = PlaidLink.onEvent.listen(_onEvent);
    _streamExit = PlaidLink.onExit.listen(_onExit);
    _streamSuccess = PlaidLink.onSuccess.listen(_onSuccess);
  }

  @override
  void dispose() {
    _streamEvent?.cancel();
    _streamExit?.cancel();
    _streamSuccess?.cancel();
    super.dispose();
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
  }

  void _onExit(LinkExit event) {
    final metadata = event.metadata.description();
    final error = event.error?.description();
    print("onExit metadata: $metadata, error: $error");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 350,
            height: 450,
            child: PlaidEmbeddedView(
              token: widget.linkToken,
            ),
          ),
        ],
      ),
    );
  }
}
