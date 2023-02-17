# Plaid Link for Flutter

[![pub](https://img.shields.io/pub/v/plaid_flutter.svg)](https://pub.dev/packages/plaid_flutter)
[![points](https://img.shields.io/pub/points/plaid_flutter)](https://pub.dev/packages/plaid_flutter)
[![popularity](https://img.shields.io/pub/popularity/plaid_flutter)](https://pub.dev/packages/plaid_flutter)
[![likes](https://img.shields.io/pub/likes/plaid_flutter)](https://pub.dev/packages/plaid_flutter)
[![donate](https://img.shields.io/badge/Buy%20me%20a%20beer-orange.svg)](https://www.buymeacoffee.com/jpereira)

A Flutter plugin for [Plaid Link](https://plaid.com/docs/link).

This plugin integrates the native SDKs:

- [Plaid Link iOS SDK](https://plaid.com/docs/link/ios)
- [Plaid Link Android SDK](https://plaid.com/docs/link/android)
- [Plaid Link JavaScript SDK](https://plaid.com/docs/link/web)

Feel free to leave any feedback [here](https://github.com/jorgefspereira/plaid_flutter/issues).

:warning: All integrations must migrate to version 3.1.0 or later (requires version 4.1.0 or later of the iOS LinkKit SDK) by June 30, 2023, to maintain support for Chase OAuth on iOS

## Requirements

In order to initialize Plaid Link, you will need to create a link_token at [/link/token/create](https://plaid.com/docs/#create-link-token). After generating a link_token, you'll need to pass it into your app and use it to launch Link:

``` dart
...

LinkConfiguration configuration = LinkTokenConfiguration(
    token: "<GENERATED_LINK_TOKEN>",
);

PlaidLink.open(configuration: configuration)

...

```

A link_token can be configured for different Link flows depending on the fields provided during token creation. It is the preferred way of initializing Link going forward. You will need to pass in most of your Link configurations server-side in the [/link/token/create](https://plaid.com/docs/#create-link-token) endpoint rather than client-side where they previously existed.

If your integration is still using a public_key to initialize Plaid Link, the LinkConfiguration class has support for it. Check the [migration guide](https://plaid.com/docs/upgrade-to-link-tokens/) to upgrade your app to the link_token flow.

## Installation

Add `plaid_flutter` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

## iOS

### Requirements

- iOS version >= 11.0
- Xcode 14 or greater
### (Identity Verification only) - Enable camera support 

When using the Identity Verification product, the Link SDK may use the camera if a user needs to take a picture of identity documentation. To support this workflow, add a NSCameraUsageDescription entry to your application's plist with an informative string. 

### (Optional) - Register your redirect URI

Registering a redirect URI is required when working with OAuth, which is used for European integrations as well as integrations with some US financial institutions. To register your redirect app URI:
- Log into your Plaid Dashboard at the API page
- Next to Allowed redirect URIs click Configure then Add New URI
- Enter your redirect URI, for example www.plaid.com/redirect
- Click Save Changes. You may be prompted to re-enter your password.

*More info at [https://plaid.com/docs/link/ios](https://plaid.com/docs/link/ios).*

## Android

### Requirements
#### Gradle Configuration

Go to the project level `android/app/build.gradle` and make sure you are using a minSdk >= 21

### (Identity Verification only) - Enable camera support

If your app uses Identity Verification, a user may need to take a picture of identity documentation or a selfie during the Link flow. To support this workflow, the CAMERA , WRITE_EXTERNAL_STORAGE, RECORD_AUDIO, and MODIFY_AUDIO_SETTINGS permissions need to be added to your application's AndroidManifest.xml.

#### Register your App ID

- Log into your Plaid Dashboard at the API page
- Next to Allowed Android Package Names click Configure then Add New Android Package Name
- Enter your package name, for example com.plaid.example
- Click Save Changes, you may be prompted to re-enter your password

![](https://raw.githubusercontent.com/jorgefspereira/plaid_flutter/master/doc/images/register-app-id.png)


*More info at [https://plaid.com/docs/link/android](https://plaid.com/docs/link/android).*

## Web

### Requirements

Include the Plaid Link initialize script on your main HTML page.

``` html

<script src="https://cdn.plaid.com/link/v2/stable/link-initialize.js"></script>

```

*More info at [https://plaid.com/docs/link/web](https://plaid.com/docs/link/web).*

