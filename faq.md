---
layout: page
title: FAQ
---

### What is Firefox Lockbox?

Firefox Lockbox is an experimental product from Mozilla, the makers of Firefox. It’s an app for iPhone (and coming soon for Android) that gives you access to passwords you’ve saved to Firefox.  

<a id="how-do-i-use-firefox-lockbox">
### How do I get my saved logins into Firefox Lockbox?

Firefox Lockbox works by syncing logins from the Firefox browser to the Firefox Lockbox app. To get started, [sign in](#how-do-i-enable-sync-on-firefox) to a Firefox browser using the same Firefox Account you use for Firefox Lockbox. (Don’t have an account yet? Start [here](https://accounts.firefox.com/signup).)

<a id="how-do-i-enable-sync-on-firefox">
### How do I enable sync on Firefox?

#### On Desktop

To begin syncing between Firefox and the Firefox Lockbox app, you’ll need to sign in or create a Firefox Account on Firefox for desktop. You can do this in the **Firefox Account** panel within **Preferences** (accessed via the gear icon in the main menu).

<div class="image-grid">
  <img src="/assets/images/faq/sync-desktop-1.png" alt="Enable Sync on Desktop" />
  <img src="/assets/images/faq/sync-desktop-2.png" alt="Enable Sync on Desktop" />
</div>

If you already have an account, make sure you’ve selected the **Logins** checkbox in Sync Settings.

<div class="image-grid full">
  <img src="/assets/images/faq/sync-desktop-3.png" alt="Enable Sync on Desktop" />
</div>

#### On iOS

To begin syncing between Firefox for iOS and the Firefox Lockbox app, you’ll need to sign in to your Firefox Account on Firefox. You’ll find the sign-in screen under **Settings** (via the gear icon in the main menu).

<div class="image-grid">
  <img src="/assets/images/faq/sync-ios-1.png" alt="Enable Sync on iOS" />
  <img src="/assets/images/faq/sync-ios-2.png" alt="Enable Sync on iOS" />
</div>

Once you are signed in to your account, you can select “Sync Now” to send your saved logins to Firefox Lockbox. If you are already signed in to your account, ensure the **Logins** item within Sync Settings is checked in order to sync your logins to Firefox Lockbox.

<div class="image-grid">
  <img src="/assets/images/faq/sync-ios-3.png" alt="Enable Sync on iOS" />
  <img src="/assets/images/faq/sync-ios-4.png" alt="Enable Sync on iOS" />
</div>

<a id="how-do-i-create-new-entries">
### How do I create new entries?

When you are logged into your Firefox Account on Firefox for desktop or mobile, every time you enter new login information, Firefox will prompt you to save these details. Your login information will then sync to Firefox Lockbox.

<a id="how-do-i-edit-existing-entries">
### How do I edit existing entries?

You’ll need to edit entries in Firefox. To do this in Firefox for desktop, go to Settings/Preferences, and under the Privacy & Security panel, select the Saved Logins button. Double click on entry information to edit.

To edit entries on Firefox for iOS, go to settings and select the Logins menu under the Privacy section.

<a id="what-security-technology-does-firefox-lockbox-use">
### What security technologies does Firefox Lockbox use?

Firefox Lockbox uses the following technologies to protect your data:

* [AES-256-GCM](https://en.wikipedia.org/wiki/Galois/Counter_Mode) encryption, a tamper-resistant block cipher technology.
* [onepw](https://github.com/mozilla/fxa-auth-server/wiki/onepw-protocol) protocol to sign into Firefox Accounts and obtain encryption keys.
* [PBKDF2](https://en.wikipedia.org/wiki/PBKDF2) and [HKDF](https://en.wikipedia.org/wiki/HKDF) with [SHA-256](https://en.wikipedia.org/wiki/SHA-2) to create the encryption key from your Firefox Accounts username and password.

All of this is done on your device, so Mozilla cannot know your password and cannot read your data.

<a id="how-do-i-manually-sync-my-entries-in-firefox">
### How do I manually sync my entries in Firefox?

#### On Desktop

First, open Firefox for desktop and open the main menu to see if you are signed in. Once you are signed in, select the sync icon to the right of your display name. Now, open the Firefox Lockbox mobile app and pull down on the list of logins to refresh the list. If you don’t see your entries in Firefox Lockbox, wait a few minutes and refresh again.

<div class="image-grid">
  <img src="/assets/images/faq/manual-sync-desktop.png" alt="Manual Sync on Desktop" />
  <img src="/assets/images/faq/manual-sync-refresh.png" alt="Pull to Refresh in Lockbox" />
</div>

#### On iOS

First, open the Firefox for iOS main menu to see if you are signed in. Once you are signed in, select “Sync Now” under your display name. Now, open the Firefox Lockbox mobile app and pull down on the list of logins to refresh the list. If you don’t see your entries in Firefox Lockbox, wait a few minutes and refresh again.

<div class="image-grid">
  <img src="/assets/images/faq/manual-sync-ios.png" alt="Manual Sync on iOS" />
  <img src="/assets/images/faq/manual-sync-refresh.png" alt="Pull to Refresh in Firefox Lockbox" />
</div>

<a id="how-do-i-set-up-autofill">
### How do I set up AutoFill?

If you just downloaded Firefox Lockbox, you’ll start with a screen which includes “Set Up Autofill”, which takes you directly to your device settings.

<div class="image-grid">
  <img src="/assets/images/faq/autofill-onboarding.png" alt="AutoFill Onboarding" />
  <img src="/assets/images/faq/autofill-settings.png" alt="Settings - AutoFill Passwords" />
</div>

Here you can select Firefox Lockbox to autofill logins for you. You also want to make sure that “AutoFill Passwords” is green and toggled on.

<div class="image-grid">
  <img src="/assets/images/faq/autofill-password-settings.png" alt="Settings - Passwords and Accounts" />
  <img src="/assets/images/faq/autofill-signin.png" alt="Settings - Sign in Required" />
</div>

If you’re already using Firefox Lockbox, you can set Lockbox to autofill your logins by navigating through the device: Settings > Passwords & Accounts > AutoFill Passwords

If you haven’t yet signed in to Lockbox, you will be prompted to do so in order to authenticate the app to automatically fill passwords.

Your setup is now complete. You can now start using your saved logins in Lockbox.
