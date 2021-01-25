## 2.0.0

* iOS: migration 1.x SDK to the 2.0.9 SDK.

## 1.1.6

* Added support for payment initiation product type. Thank you @teerryn
* Updated LinkKit to 1.1.38: Fix issue with null account_id in returned metadata

## 1.1.5

* Bug fix: verification status always null on android.

## 1.1.4

* Added verification_status to onSuccess callback.
* Support for legacy update mode (which uses a token). Thank you @jaredanderton.

## 1.1.3

* Updated Plaid iOS SDK to version 1.1.36
* Updated Plaid Android SDK to version 2.2.0

## 1.1.2

* Added a close method to allow Link re-initialization.

## 1.1.1

* Institution metadata (name, id) is now parsed correctly on Android.

## 1.1.0

* Breaking change: added the prefix 'Link' to the metadata objects.
* Fixed exit event not being triggered in some occasions.
* Locked Plaid iOS SDK version to avoid conflits when integrating the plugin.
* Fixed issue with institution not being correctly parsed on the events metadata.

## 1.0.0

* Added support for the new link_token flow.
* Updated Plaid Android SDK to version 2.1.0

## 0.3.0

* Added update mode, payment initation mode, institution pre-selection and oauth code mode.

## 0.2.7

* Updated Plaid Android SDK to version 2.0.0

## 0.2.6

* Added important Android release configurations to README
* Updated example app with the new android release configurations

## 0.2.5

* Updated Plaid Android SDK to version 1.4.1
* Added support for account subtype filtering on Android.
* Added for additional products (Thank you @mrienstra)
* Added configuration support for: countryCodes, linkCustomizationName, language and userPhoneNumber.

## 0.2.4

* Breaking change: Added userLegalName and userEmailAddress to the open method.

## 0.2.3

* Added support to enable all Auth features (https://plaid.com/docs/#enabling-all-auth-features)
* Updated Plaid Android SDK to version 1.3.0

## 0.2.2

* Added iOS support for account subtype filtering
* Updated Plaid Android SDK to version 1.2.1

## 0.2.1

* Small bug fix LinkConfiguration

## 0.2.0

* Upgrade Plaid Android SDK to version 1.0.0

## 0.1.2

* pubspec.yaml plugin platform changes

## 0.1.1

* Minor changes to documentation

## 0.1.0

* Support for Android
* Support for oAuthRedirectUri property

## 0.0.1

* Initial release
* Support for iOS
