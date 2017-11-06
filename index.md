# Lockbox

## Components

* WebExtension: [https://github.com/mozilla-lockbox/lockbox-extension](https://github.com/mozilla-lockbox/lockbox-extension)
  - Documentation: [https://mozilla-lockbox.github.io/lockbox-extension/](https://mozilla-lockbox.github.io/lockbox-extension/)
* Data Store: [https://github.com/mozilla-lockbox/lockbox-datastore](https://github.com/mozilla-lockbox/lockbox-datastore)
  - Documentation: [https://mozilla-lockbox.github.io/lockbox-datastore/](https://mozilla-lockbox.github.io/lockbox-datastore/)

## Design

* [Architecture Overview](./architecture)
* [Integration with Firefox Accounts](./architecture/fxa.md)

## Development Process

* Daily standup: async but prompted by "geekbot" at 3 PM Mountain
* All code in Git(Hub)
  - PR -> Review -> Merge (optimistic)
* MDN Coding Style (m-c .eslint defaults)
* Automated CI: run through Travis CI
