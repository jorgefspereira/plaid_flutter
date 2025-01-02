## 4.2.0

* Migrate to js interop (@AlexVegner)
* Fix: Prevent handler deallocation on multi-item Link handoff (@dtroupe-plaid)
* Added missing events and view names

## 4.1.1

* Fixed issue with Plaid not opening in an add-to-app hybrid model 
* Updated iOS SDK to 5.6.1
* Updated Android SDK to 4.6.1

## 4.1.0-rc

* Added submit for the new layer product.
* Adding new two-step loading paradigm where Link is first created and then opened. Should improve loading times.
* Updated Android SDK to 4.6.0

## 4.0.7-rc

* Downgraded dart sdk version

## 4.0.6-rc

* Updated Android SDK to 4.5.1
* Updated iOS SDK to 5.6.0
* Removed imperative apply of Flutter's Gradle plugins

## 4.0.5-rc

* Fixing issue with handoff event not triggering
* Updated Android SDK to 4.3.1
* Updated iOS SDK to 5.4.2
* Added PROFILE_ELIGIBILITY_CHECK_READY, PROFILE_ELIGIBILITY_CHECK_ERROR and SUBMIT_OTP events.
  
## 4.0.4-rc

* Added mocktail testing. Thank you @MauriMiguez
* Updated Android SDK to 4.2.1
* Updated iOS SDK to 5.3.3
* Added equality operator to LinkTokenConfiguration

## 4.0.3-rc

* Fixing issue with env on plaid js. Thank you @almovsesanso 

## 4.0.2-rc

* Updated README iOS requirments

## 4.0.1-rc.1

* Updated Android SDK to 4.1.1
* Updated iOS SDK to 5.2.0
* Added export for PlaidPlatformInterface
* BREAKING CHANGE: iOS deployment target 14.0

## 4.0.0-rc.1

* Updated Android SDK to 4.0.0
* Updated iOS SDK to 5.0.0
* Added support for selection, routingNumber, matchReason, accountNumberMask, isUpdateMode to LinkEventMetadata
* BREAKING CHANGE: Removed LegacyLinkConfiguration


## 3.1.4

* Fix compatible with Gradle 8
* Fixed Plaid.open() never returning

## 3.1.3

* Updated Android SDK to 3.14.1
* Updated iOS SDK to 4.7.0
* Added missing exit status, event names and view names.

## 3.1.2

* Flutter 3.10 support
* Dart 3 support
* Fixed jsToMap to handle null on web. Thank you @rs-follow
* Fixed Screening View Name
* Updated iOS SDK to 4.4.0
* Updated Android SDK to 3.13.2

## 3.1.1

* Fixed typo on LinkEventMetadata
* Updated Android SDK to 3.11.0
* Updated iOS SDK to 4.2.0  

## 3.1.0

* Fixed optional parameters on events metadata
* Updated iOS SDK to 4.1.0  

## 3.0.1

* Changed LinkAccount parameters 'mask' and 'verificationStatus' to optional

## 3.0.0

* Added receivedRedirectUri property to Web
* Added a new EventChannel to broadcast events from native platform
* Changed jcenter to mavenCentral
* Updated Android SDK to 3.10.1
* Updated iOS SDK to 4.0.1

## 2.2.2

* Fixed enumerations not handled
* Updated Android SDK to 3.10.0
* Updated iOS SDK to 2.5.1

## 2.2.1

* Added close method implementation
* Updated Android SDK to 3.7.1
* Update Gradle
* Updated iOS SDK to 2.4.0

## 2.2.0

* BREAKING CHANGE: All PlaidLink methods are now static (check example provided)
* BREAKING CHANGE: Renamed callbacks to handlers (e.g. SuccessCallback -> LinkSuccessHandler)
* Added noLoadingState property to LinkTokenConfiguration.
* Updated iOS SDK to version 2.3.1
* Updated Android SDK to version 3.6.2

## 2.1.4

* Updated iOS SDK to version 2.2.0
* Updated Android SDK to version 3.5.1

## 2.1.3

* Updated iOS SDK to version 2.1.3
* Using LinkKit openWithPresentationHandler.
* Check for a token input with the public- prefix.
* Updated Android SDK to version 3.4.0

## 2.1.2

* Exposing continueWithRedirectUri function.

## 2.1.1

* Fixes MissingPluginException issue #42
* Fixes metada conversion on Plaid Web version

## 2.1.0+1

* Small edit to README file

## 2.1.0

* Updated iOS SDK to version 2.1.0
* Fix: elements not iterable on web. Thank you @cwesterhold
* Migration to null safety. New minimum dart sdk version: 2.12
* BREAKING CHANGE: Renamed LinkConfiguration to LinkTokenConfiguration

## 2.0.2+1

* Added analysis_options.yaml to exclude generated files

## 2.0.2

* Updated iOS SDK to version 2.0.11
* Updated Android SDK to version 3.2.4

## 2.0.1

* Updated iOS SDK to version 2.0.10

## 2.0.0

* iOS: migration 1.x SDK to the 2.0.9 SDK.
* Android: migration 2.x SDK to the 3.2.2 SDK.
* Supporting the new Android plugins APIs
* Initial Web support

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
