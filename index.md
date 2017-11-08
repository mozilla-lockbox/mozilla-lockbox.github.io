---
layout: page
title: Lockbox
---

This website is to gather documentation and details for Mozilla's experimental
[Lockbox product][website]. Lockbox will be the framework for us to test and
quickly iterate on hypotheses (on desktop and mobile) without disrupting
existing Firefox users relying on the “saved logins” feature.

All planning and work performed is reflected on our Waffle.io kanban board:  
[https://waffle.io/mozilla-lockbox/lockbox-extension](https://waffle.io/mozilla-lockbox/lockbox-extension)

Learn more about the Lockbox [project processes](/process).

## Product Components

Here are links to the in-progress projects that make up the Lockbox experiment.

This is not exhaustive nor a guarantee of any future plans but meant as a
helpful reference.


Component                           | Documentation                       | Status | Coverage
---                                 | ---                                 | ---
[Data Store][datastore-repo]        | [data-store][datastore-docs]        | [![Build Status][datastore-travis-image]][datastore-travis-link] | [![Coverage Status][datastore-codecov-image]][datastore-codecov-link]
[Firefox extension][extension-repo] | [lockbox-extension][extension-docs] | [![Build Status][extension-travis-image]][extension-travis-link] |  [![Coverage Status][extension-codecov-image]][extension-codecov-link]
[iOS application][ios-repo]         |                                     | [![Build Status][ios-travis-image]][ios-travis-link] | [![Coverage Status][ios-codecov-image]][ios-codecov-link]
[Project documentation][docs-repo]  | [mozilla-lockbox][website]

---

[website]: https://mozilla-lockbox.github.io/
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
[ios-travis-image]: https://travis-ci.org/mozilla-lockbox/lockbox-ios.svg?branch=master
[ios-travis-link]: https://travis-ci.org/mozilla-lockbox/lockbox-ios
[ios-codecov-image]: https://img.shields.io/codecov/c/github/mozilla-lockbox/lockbox-ios.svg
[ios-codecov-link]: https://codecov.io/gh/mozilla-lockbox/lockbox-ios

[docs-repo]: https://github.com/mozilla-lockbox/mozilla-lockbox.github.io/
