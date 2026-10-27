<p align="center"><img src="Assets/shrubtwitch-icon.png" width="150" alt="ShrubTwitch logo"></p>

# ShrubTwitch 1.2

A native iOS Twitch customization project by **ShrubHub**. Includes a custom control center, per-channel chat-density profiles, Chat Focus Mode, private channel notes, channel bookmarks, and a long-press Quick Panel (via the optional floating button), in addition to retained AdBlock, chat, emote and playback functionality.

## What's original in 1.2?

- ShrubTwitch Control Center: redesigned entry menu with unique artwork, quick actions and clear navigation.
- Stream Profiles: choose **Compact** (13pt/0 spacing) or **Comfortable** (17pt/4 spacing) for the currently active channel. Profile selection persists by channel and reapplies on channel changes. Clearing a profile does not erase your existing chat appearance settings.
- Chat Focus Mode: local-only keyword filtering in the project's **custom chat renderer**. It does not alter native Twitch chat or moderate other users. Toggles refresh the rendered chat.
- ShrubBookmarks: bookmark current channel, revisit channel URLs, swipe to delete. Saved locally.
- Private channel notes: text notes saved per channel, never uploaded.
- Quick Panel: use the **Quick** control in settings, or long-press the optional in-app floating settings button to toggle OLED mode, save the current channel or edit notes.
- Reusable custom user-provided ShrubTwitch logo included in app tweak interface and as source PNG.
- GitHub Actions: build the dylib and inject it into a user-supplied decrypted Twitch IPA automatically via a persistent `TWITCH_IPA_URL` variable.

**Important limitations:** This is an uncompiled source release, not a device-tested IPA. Not every upstream option has been redesigned; legacy menu subpages are preserved for compatibility. The app's SpringBoard icon may remain Twitch's because the workflow deliberately preserves the original `Assets.car`. The workflow sets the display name to ShrubTwitch, and includes the exact artwork as `ShrubTwitch-Logo.png` within the IPA. AdBlock still depends on Twitch's evolving implementation and is not guaranteed to block all ads.

## Setup and publishing

See **CODESPACES_SETUP.md** for the one-command upload-and-commit instructions, and how to configure `TWITCH_IPA_URL` once. The GitHub workflow does not produce a certificate-signed IPA; sign the generated IPA using your own sideloading signer.

## License and attribution

ShrubTwitch is a fork of [TwitchPlusK by Knoks1111](https://github.com/Knoks1111/TwitchPlusK) and contributors. Upstream source and third-party components retain their copyright notices and [GPLv3 license](LICENSE); see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). You must retain the required credits and comply with the license when publishing modifications. The new ShrubTwitch feature implementation is also distributed under GPLv3.

The Twitch app and Twitch trademarks belong to their respective owners. Only the open-source tweak is in this repository; users supply their own legitimately obtained decrypted IPA for local patching.
