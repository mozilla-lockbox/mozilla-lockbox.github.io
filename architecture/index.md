---
layout: page
title: Architecture
---

This is a collection of technical documents describing current and potential
(future) engineering design decisions.

* [Data Storage](./data-storage.md)
  * [Locking/Unlocking](./lock-unlock.md)
* [Firefox Accounts](./fxa.md)
* [Backup and Sync](./sync.md)

Other technical documents and resources can be found in the code repositories:


Component                           | Documentation                       | Status | Coverage
---                                 | ---                                 | ---    | ---
[Data Store][datastore-repo]        | [data-store][datastore-docs]        | [![Build Status][datastore-travis-image]][datastore-travis-link] | [![Coverage Status][datastore-codecov-image]][datastore-codecov-link]
[Firefox extension][extension-repo] | [lockbox-extension][extension-docs] | [![Build Status][extension-travis-image]][extension-travis-link] |  [![Coverage Status][extension-codecov-image]][extension-codecov-link]
[iOS application][ios-repo]         | [lockbox-ios][ios-docs]             | [![BuddyBuild][buddybuild-image]][buddybuild-link] | [![Coverage Status][ios-codecov-image]][ios-codecov-link]
[Android application][android-repo]         | [lockbox-android][android-docs]             | |
[Project documentation][docs-repo]  | [mozilla-lockbox][website]

This is not exhaustive nor a guarantee of any future plans but meant as a
helpful reference.

[website]: https://lockbox.firefox.com/

[datastore-repo]: https://github.com/mozilla-lockbox/lockbox-datastore
[datastore-docs]: https://mozilla-lockbox.github.io/lockbox-datastore/
[datastore-travis-image]: https://travis-ci.org/mozilla-lockbox/lockbox-datastore.svg?branch=master
[datastore-travis-link]: https://travis-ci.org/mozilla-lockbox/lockbox-datastore
[datastore-codecov-image]: https://img.shields.io/codecov/c/github/mozilla-lockbox/lockbox-datastore.svg
[datastore-codecov-link]: https://codecov.io/gh/mozilla-lockbox/lockbox-datastore

[extension-repo]: https://github.com/mozilla-lockbox/lockbox-extension
[extension-docs]: https://mozilla-lockbox.github.io/lockbox-extension/
[extension-travis-image]: https://travis-ci.org/mozilla-lockbox/lockbox-extension.svg?branch=master
[extension-travis-link]: https://travis-ci.org/mozilla-lockbox/lockbox-extension
[extension-codecov-image]: https://img.shields.io/codecov/c/github/mozilla-lockbox/lockbox-extension.svg
[extension-codecov-link]: https://codecov.io/gh/mozilla-lockbox/lockbox-extension

[ios-repo]: https://github.com/mozilla-lockbox/lockbox-ios
[ios-docs]: https://mozilla-lockbox.github.io/lockbox-ios/
[buddybuild-image]: https://dashboard.buddybuild.com/api/statusImage?appID=5a0ddb736e19370001034f85&branch=master&build=latest
[buddybuild-link]: https://dashboard.buddybuild.com/apps/5a0ddb736e19370001034f85/build/latest?branch=master
[ios-codecov-image]: https://img.shields.io/codecov/c/github/mozilla-lockbox/lockbox-ios.svg
[ios-codecov-link]: https://codecov.io/gh/mozilla-lockbox/lockbox-ios

[android-repo]: https://github.com/mozilla-lockbox/lockbox-android
[android-docs]: https://mozilla-lockbox.github.io/lockbox-android/

[docs-repo]: https://github.com/mozilla-lockbox/mozilla-lockbox.github.io/
