<p align="center">
	<img width="200" src="Shared/Assets.xcassets/vulcan.imageset/Vulcan@2x.png" alt="vulcan Logo"><br/>
	<h3 align="center">vulcan</h3>
	<p align="center">Open-source UONET+ app for Apple devices.</p>
</p>

## Installation
Compile using Xcode, sideload .ipa from [releases](https://github.com/rrroyal/vulcan/releases) or [register for TestFlight](https://form.typeform.com/to/Mqh3AvAx).

## Functionality
### UONET+
- [x] Grades
- [x] Schedule
- [x] Tasks
- [x] Messages
- [x] Notes
- [ ] QR code logging in
- [ ] Message attachements

### Core
- [x] iOS app
- [x] iPadOS app
- [x] watchOS app (kinda)
- [ ] macOS app
- [x] Widgets
- [x] Siri shortcuts/intents
- [x] Notifications - [**read below**](#what-about-notifications)

## FAQ
### Why the app isn't in the App Store?
Uploading apps on the App Store requires being a member of the [Apple Developer Program](https://developer.apple.com/programs/), which costs 99$ per year. If someone is generous enough to pay for that, I'm more than happy to upload the app to the App Store.

### What about notifications?
App will remind you about your next lessons or tasks. Unfortunately, as of right now I'm unable to add real-time notifications about new messages, grades etc.

## Technical stuff
- There's no analytics, ads, weird libraries or other bullshit.
- The app is built with [SwiftUI](https://developer.apple.com/xcode/swiftui/), [Combine](https://developer.apple.com/documentation/combine) and CoreData. The interface may sometimes be glitchy - please report every bug you've encountered to me!
- API is based on [uonet-api-docs](https://gitlab.com/erupcja/uonet-api-docs) and my own analysis. App will be migrating to the new API soon, providing further functionality (lucky number, etc).

## Credits
- [kishikawakatsumi/KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)  
- [erupcja/uonet-api-docs](https://gitlab.com/erupcja/uonet-api-docs)  

## License
[GPL v3.0](LICENSE)

[![Build Status](https://app.bitrise.io/app/96fcd2c4966a42d2/status.svg?token=tyQy2iKlWi_0yMeQtq2X7g&branch=main)](https://app.bitrise.io/app/96fcd2c4966a42d2)