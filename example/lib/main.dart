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
  int currentPageIndex = 0;
  final String linkToken =
      'link-sandbox-9af0f80f-22c7-4050-9158-c87d4e4f34f4'; // Replace with your actual link token

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() => currentPageIndex = index);
          },
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.looks_one),
              label: 'LinkToken',
            ),
            NavigationDestination(
              icon: Icon(Icons.looks_two),
              label: 'EmbeddedLink',
            ),
          ],
        ),
        body: <Widget>[
          /// Link Token page
          ExampleLinkToken(linkToken: linkToken),

          /// Embedded Link page
          ExampleEmbeddedLink(linkToken: linkToken),
        ][currentPageIndex],
      ),
    );
  }
}
