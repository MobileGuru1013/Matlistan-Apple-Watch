# SpeechKit iOS SDK

# Release 1.4.19 (06/24/2015)
Improved documentation for SSL hostname and keychain verification
Fixed bug on iOS 8 where speech recognition would prevent another audio channel which was paused from restarting

# Release 1.4.14 (03/19/2015)
Added support for SSL hostname and keychain verification

# Release 1.4.12 (09/11/2014)
Update to fix an issue compiling for ARM64 and XCode 6
Update to fix an issue related to arm64 compatibility for simulators and a bug where TTS audio would not play when the ringer was muted

# Release 1.4.10 (04/29/2014)
Update to fix an issue related to arm64 compatibility for simulators

# Release 1.4.9 (11/20/2013)
SpeechKit is now compatible with ARM64 architectures in Xcode
Fixed an issue where background audio, such as from the music app, would be stopped when initializing SpeechKit. It now continues playing after a 1s interruption
Fixed an issue where sending an app to the background after doing a recognition with the SKRecognizer class would interrupt the background music when bringing back the app to the foreground
Lacking the microphone permission on iOS 7 will now give the message "Microphone input permission refused - will record only silence" rather than a generic "Speech not recognized"
Updated the Xcode deployment target from 3.0 to 4.3

# Release 1.4.5 (10/4/2012)
Fixed issue that background music is not stopped after SpeechKit started in iOS6 environment

# Release 1.4.4 (internal release)
Remove SpeechKit setter override compiling warning

# Release 1.4.3 (internal release)
Build for ARM v7s in Xcode 4.5 this adds support for the ARM v7s instruction set and resolves error messages generated in Xcode 4.5 in previous releases

# Release 1.4.2
Save UUID into keychain instead of app storage. UUID will be same even app is reinstalled

# Release 1.4.0
Replaced use of iPhone Unique Device ID with an anonymous per-application UUID generated the first time each application is run
Improved handling of Bluetooth headsets
Fixed issue with VoiceOver

# Release 1.3.2
Updated audio system for iOS Updates to documentation and sample code

# Release 1.3.1
Fixes a bug for a specific use case where repeated losing of the network connection while doing recognition will eventually crash the SpeechKit

# Release 1.3.0
Fixed a few timing issues related to audio recording
Correctly exposed the SpeechError.Codes values
Added SSL support

# Release 1.2.1
Implemented new audio management system resulting in faster initialization/audio record start/stop
Increased support for backgrounding (i.e. if the home key is pressed during a recording, there are no longer any ill effects)
Increased support for background audio (i.e. recording and playback now coexist more effectively with iPod music playback)
Implemented new [Speechkit destroy] function and an associated [SpeechKitDelegate destroyed] callback enabling users to tear down the framework and re-call [SpeechKit setupwithID] if necessary
Additional memory management improvements

# Release 1.1.2
Updated release

# Release 1.1.1
Patches minor memory leaks in the "setupWithID()" and "initWithType()" methods that occur when the connection to the network servers is initiated

# Release 1.1
Added SKEarcon class and setEarcon:forType: method to provide automatic earcon playback on recording, finish and cancel stages of the recognition process
Added custom data property to SKRecognition for custom server-end models and processing
Alternatives list only lists results other than the top item in Recognizer demo app

# Release 1.0
Ensure all appropriate delegate messages are sent for all vocalizer requests Support for simulator
Original string pointer passed to speakString is provided in delegate callbacks for direct pointer comparison Delegate error methods are called in response to cancel
Delegate error methods report no connection
Updated documentation to reflect new APIs
Updated documentation to reflect recent changes to sample applications

# Release 0.9.6
Recognition sample app allows selection of Search or Dictation recognizer types

# Release 0.9.5
Add sessionID method to SpeechKit class to return session ID
Add audioLevel property to SKRecognizer class to provide on demand access to audio power level
Add VUMeter to Recognizer demo app, providing a sample usage of the audioLevel property

# Release 0.9.4
Release SDK
