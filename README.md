

# vulcan
Open-source UONET+ app for Apple devices.

## How to run it?
You can compile it yourself, or join the TestFlight [here](https://form.typeform.com/to/Mqh3AvAx).

### TODO
- [ ] Migrate to the new API
- [ ] macOS app
- [ ] Quick actions
- [ ] Cursor support
- [ ] Siri suggestions/shortcuts/intents
- [ ] Handoff

## FAQ
### Will I get banned if I use this app?
**I have no idea. You are using this app on your own responsibility.**

## Technical stuff
- There's no analytics, ads, weird libraries or other bullshit.
- The app is built with [SwiftUI](https://developer.apple.com/xcode/swiftui) and [Combine](https://developer.apple.com/documentation/combine).
- API requests are based on [uonet-api-docs](https://gitlab.com/erupcja/uonet-api-docs) and my own analysis.
- Data is stored using CoreData - it was my first time using it, so I'm pretty sure there's a lot of stuff I could do better. Contributions are more than welcome!

## Credits
- [kishikawakatsumi/KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)
- [erupcja/uonet-api-docs](https://gitlab.com/erupcja/uonet-api-docs)

## License
[GPL v3.0](LICENSE)

[![Build Status](https://app.bitrise.io/app/96fcd2c4966a42d2/status.svg?token=tyQy2iKlWi_0yMeQtq2X7g&branch=main)](https://app.bitrise.io/app/96fcd2c4966a42d2)
