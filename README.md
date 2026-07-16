# Plaid Link for Flutter

[![pub](https://img.shields.io/pub/v/plaid_flutter.svg)](https://pub.dev/packages/plaid_flutter)
[![likes](https://img.shields.io/pub/likes/plaid_flutter)](https://pub.dev/packages/plaid_flutter)
[![downloads](https://img.shields.io/pub/dm/plaid_flutter)](https://pub.dev/packages/plaid_flutter)
[![donate](https://img.shields.io/badge/Buy%20me%20a%20beer-orange.svg)](https://www.buymeacoffee.com/jpereira)

A Flutter plugin for [Plaid Link](https://plaid.com/docs/link).

This plugin integrates the native SDKs:

- [Plaid Link iOS SDK 7.x.x](https://plaid.com/docs/link/ios)
- [Plaid Link Android SDK 5.x.x](https://plaid.com/docs/link/android)
- [Plaid Link JavaScript SDK](https://plaid.com/docs/link/web)

Feel free to leave any feedback [here](https://github.com/jorgefspereira/plaid_flutter/issues).

## Requirements

In order to initialize Plaid Link, you will need to create a link_token at [/link/token/create](https://plaid.com/docs/#create-link-token). After generating a link_token, you'll need to pass it into your app and use it to open Link:

``` dart
...

LinkTokenConfiguration _configuration = LinkTokenConfiguration(
    token: "<GENERATED_LINK_TOKEN>",
);

// Create the native Plaid Link session.
// This is a one-time-use session.
// Must be called before `open()`.
// Completes when Plaid is ready to open, or throws an error if setup fails.
await PlaidLink.create(configuration: _configuration);

// Present standard or Layer Link, or start a headless session.
await PlaidLink.open();

...

```

Note that each time you open Link, you will need to get a new link_token from your server and create a new LinkTokenConfiguration with it.

A link_token can be configured for different Link flows depending on the fields provided during token creation. It is the preferred way of initializing Link going forward. You will need to pass in most of your Link configurations server-side in the [/link/token/create](https://plaid.com/docs/#create-link-token) endpoint rather than client-side where they previously existed.

## Installation

Add `plaid_flutter` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

## iOS

### Requirements

| Name | Version |
|------|---------|
| Flutter | >= 3.44.0 |
| Xcode | >= 16.1.0 |
| Swift | >= 5.10 |
| iOS | >= 15.0 |

Plaid Link iOS 7 is distributed only through Swift Package Manager. This
plugin has no CocoaPods specification. Flutter 3.44 enables Swift Package
Manager by default; if it was disabled locally, re-enable it with:

```shell
flutter config --enable-swift-package-manager
```

### LinkKit 7 session types

Standard Link remains the default and requires no code changes:

```dart
const configuration = LinkTokenConfiguration(
  token: '<GENERATED_LINK_TOKEN>',
);
```

Layer and headless tokens must opt into their matching native LinkKit 7
session API:

```dart
const layerConfiguration = LinkTokenConfiguration(
  token: '<LAYER_LINK_TOKEN>',
  sessionType: LinkSessionType.layer,
);

const headlessConfiguration = LinkTokenConfiguration(
  token: '<HEADLESS_LINK_TOKEN>',
  sessionType: LinkSessionType.headless,
);
```

For standard and headless sessions, `create` completes when LinkKit calls
`onLoad`; `open` then presents Link or calls `start()`. A Layer `create`
completes as soon as its native session exists. Wait for a `LAYER_READY` event
before calling `open`.

`LAYER_NOT_AVAILABLE` is recoverable for Extended Autofill: call
`PlaidLink.submit` on that same active Layer session with the requested phone
number or date of birth, then wait for `LAYER_READY` or
`LAYER_AUTOFILL_NOT_AVAILABLE`. Tokens are specific to their session type and
cannot be interchanged.

Embedded Link continues to use `PlaidEmbeddedView` and its dedicated embedded
token configuration. The `noLoadingState` option is Android-only with LinkKit
7; `showGradientBackground` applies only to standard Link on iOS.

### FinanceKit

FinanceKit sync requires iOS 17.4 or later and a link token associated with an
access token for a previously linked Apple Card Item:

```dart
await PlaidLink.syncFinanceKit(
  token: '<FINANCEKIT_LINK_TOKEN>',
  requestAuthorizationIfNeeded: true,
  behavior: FinanceKitSyncBehavior.simulated,
);
```

`FinanceKitSyncBehavior.live` requires Apple's FinanceKit entitlement. The
native FinanceKit API will terminate an app that calls live sync without that
entitlement.

### (Identity Verification only) - Enable camera support 

When using the Identity Verification product, the Link SDK may use the camera if a user needs to take a picture of identity documentation. To support this workflow, add a `NSCameraUsageDescription` entry to your `ios/Runner/Info.plist` with an informative string. 

### OAuth configuration

If your integration uses only Identity Verification or Monitor, this steps can be skipped; they are mandatory otherwise.

Registering your redirect URI:

- Sign in to the Plaid Dashboard and go to the Team Settings -> API page.
- Next to Allowed redirect URIs click Configure then Add New URI.
- Enter your redirect URI, which you must also set up as a Universal Link for your application, for example: https://app.example.com/plaid/.
- Click Save Changes

These redirect URIs must be set up as [Universal Links](https://developer.apple.com/ios/universal-links/) in your application.

*More info at [https://plaid.com/docs/link/ios](https://plaid.com/docs/link/ios).*

## Android

### Requirements
#### Gradle Configuration

Go to the project level `android/app/build.gradle` and make sure you are using a minSdk >= 21

### (Identity Verification only) - Enable camera support

If your app uses Identity Verification, a user may need to take a picture of identity documentation or a selfie during the Link flow. To support this workflow, the CAMERA, WRITE_EXTERNAL_STORAGE, RECORD_AUDIO, and MODIFY_AUDIO_SETTINGS permissions need to be added to your application's `AndroidManifest.xml`.

#### Register your App ID

- Sign in to the Plaid Dashboard and go to the Team Settings -> API page.
- Next to Allowed Android Package Names click Configure then Add New Android Package Name.
- Enter your package name, for example com.plaid.example.
- Click Save Changes.

![](https://raw.githubusercontent.com/jorgefspereira/plaid_flutter/master/doc/images/register-app-id.png)

*More info at [https://plaid.com/docs/link/android](https://plaid.com/docs/link/android).*

## Web

### Requirements

Include the Plaid Link initialize script on your main HTML page.

``` html

<script src="https://cdn.plaid.com/link/v2/stable/link-initialize.js"></script>

```

*More info at [https://plaid.com/docs/link/web](https://plaid.com/docs/link/web).*
