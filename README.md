# Plaid Link plugin for Flutter

[![pub](https://img.shields.io/pub/v/plaid_flutter.svg)](https://pub.dev/packages/plaid_flutter)

A Flutter plugin for [Plaid Link](https://github.com/plaid/link).

This plugin integrates the native SDKs:

- [Plaid Link iOS SDK](https://github.com/plaid/plaid-link-ios)
- [Plaid Link Android SDK](https://github.com/plaid/plaid-link-android)

If you like this plugin and find it useful, I would be forever grateful for your support:

<a href="https://www.buymeacoffee.com/jpereira" target="_blank"><img width="140" src="https://bmc-cdn.nyc3.digitaloceanspaces.com/BMC-button-images/custom_images/orange_img.png" alt="Buy Me A Coffee"></a>

Feel free to leave any feedback [here](https://github.com/jorgefspereira/plaid_flutter/issues).

## Installation

Add `plaid_flutter` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

### iOS

1. Add a Run Script build phase *(name it Prepare for Distribution for example)* with the script below. Be sure to run this build phase after the Embed Frameworks build phase (or [CP] Embed Pods Frameworks build phase when integrating using CocoaPods)

``` sh
LINK_ROOT=${PODS_ROOT:+$PODS_ROOT/Plaid}
cp "${LINK_ROOT:-$PROJECT_DIR}"/LinkKit.framework/prepare_for_distribution.sh "${CODESIGNING_FOLDER_PATH}"/Frameworks/LinkKit.framework/prepare_for_distribution.sh
"${CODESIGNING_FOLDER_PATH}"/Frameworks/LinkKit.framework/prepare_for_distribution.sh
```

![](https://raw.githubusercontent.com/jorgefspereira/plaid_flutter/master/doc/images/edit_run_script_build_phase.jpg)

*NOTE: More info at [https://plaid.com/docs/link/ios](https://plaid.com/docs/link/ios).*

### Android

1. Log into your Plaid Dashboard at the API page and add a new Allowed Android package name *(for example com.plaid.example)* and a new Allowed redirect URI.

![](https://raw.githubusercontent.com/jorgefspereira/plaid_flutter/master/doc/images/register-app-id.png)
	
*NOTE: More info at [https://plaid.com/docs/link/android](https://plaid.com/docs/link/android).*

## TODOs

- [ ] [Avoid iOS Prepare for distribution configuration](https://plaid.com/docs/link/ios/#prepare-distribution-script)
- [ ] Implement tests
