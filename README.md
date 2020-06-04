

# vulcan
Open-source UONET+ app for Apple devices.

## Installation
### Manual
1. Clone the repo.
2. Replace every `please.change.me` occurrence with your designated Bundle ID (`grep -r "please.change.me" ./`).
3. Set the app groups in the Xcode project.
4. Compile and run.

### Automatic
You might want to look into [AltStore](https://altstore.io) or (if you're jailbroken) [ReProvision](https://github.com/Matchstic/ReProvision).

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
- [x] watchOS app
- [ ] macOS app
- [x] Multi window
- [x] Background refresh
- [x] Today widget
- [x] Quick actions (somewhat done)
- [ ] Cursor support
- [ ] Siri shortcuts/intents (*Handoff?*)
- [ ] Notifications

## FAQ
### Why the app isn't in the App Store?
Uploading apps on the App Store requires being a member of the [Apple Developer Program](https://developer.apple.com/programs/), which costs 99$ per year. If someone is generous enough to pay for that, then I'm more than happy to upload the app to the App Store.

### Will I get banned if I use this app?
**I have no idea. You are using this app on your own responsibility.**

## Technical stuff
- There's no analytics, ads, weird libraries or other bullshit.
- The app is built using [SwiftUI](https://developer.apple.com/xcode/swiftui/), so the interface may sometimes be buggy. There's not much I can do about that.
- API is based on [uonet-api-docs](https://gitlab.com/erupcja/uonet-api-docs) and my own analysis.
- Network requests are made with [Combine](https://developer.apple.com/documentation/combine).
- Data is stored using CoreData - it was my first time using it, so I'm pretty sure there's a lot of stuff I could do better. Contributions are more than welcome!

## Credits
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)  
- [kishikawakatsumi/KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)  
- [erupcja/uonet-api-docs](https://gitlab.com/erupcja/uonet-api-docs)  

## License
[GPL v3.0](LICENSE)
