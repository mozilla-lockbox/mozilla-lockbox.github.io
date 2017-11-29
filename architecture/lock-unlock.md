# Locking/Unlocking

## Summary

This document summarizes our goals for locking/unlocking the Lockbox
datastore. While unlocking should always be the result of some explicit user
action, locking can happen automatically for a variety of reasons. The following
is an incomplete list of triggers that should cause the datastore to lock:

* Application closed
* Screen turned off/desktop locked
* Timed out while idle
* Manually locked

## Basic Flow

The cases below cover the basic user flow for locking/unlocking. When calling
methods on the datastore, these will have an additional layer of indirection,
since the UI layer needs to communicate with the background script of the
WebExtension via message ports. This indirection has been elided from the
examples below, but is covered in the [Frontend](#frontend-extension) section
further on.

### Opening the Management UI

When the user opens the Lockbox management UI, it will first call
`DataStore.locked` to determine if the password prompt should be displayed. If
the store is locked, the UI will prompt the user to enter their password, which
will be passed to `DataStore.unlock()`.  Upon success, the prompt will close and
the full management UI will be displayed.

### Filling a Login

Filling a login is somewhat more complex since we must ensure that we don't
display the unlocking prompt at confusing times (as with the current password
manager). Once a relevant login form is displayed, the user should have an
indication (e.g. as a doorhanger) that we can fill usernames/passwords on that
site. If the datastore is locked, this will include a password form to unlock
the store.

As above, this will be determined by first calling `DataStore.locked` and then
attempting to unlock the store by passing the user's password to
`DataStore.unlock()`.

## Configurability

Not all users have the same priorities for security vs. convenience. As such, we
should allow configuration of events that automatically lock the datastore. Even
more importantly, a given user might have different priorities *depending on the
device they're using*; for example, a user might not want their datastore to
automatically lock when the screen turns off on their desktop at home, but
*would* want it to automatically lock on their laptop (e.g. if they take
their laptop to coffee shops).

As a result, we shouldn't automatically sync a user's event configuration across
all their devices; if we do provide sync for the event config, there should be a
way to tie it to a specific device.

## Backend (Datastore)

For the purposes of locking and unlocking, the datastore should have the
following API:

```js
class DataStore {
  get locked() { /* ... */ }

  async unlock(/* string */ password) { /* ... */ }
}
```

### Lock Status

In order to determine whether to show a password prompt to unlock the datastore,
the UI needs an indication of whether the store is currently locked (via
`DataStore.locked`). This property would also be convenient for providing a
quick way of indicating to the user whether the datastore is currently locked
(e.g. via a toolbar icon).

### Unlocking

The datastore should require that unlocking be performed explicitly. This will
make it easier for our frontends to ensure that users are only shown the
unlocking dialog when it's actually necessary. `DataStore.unlock()` will take
the password the user entered as its sole parameter; this allows the UI layer to
determine the best way to display the password prompt to the user (for example,
the management UI may use an in-content overlay while the form fill code may use
a doorhanger).

Since unlocking should always be explicit, there's no need to fire an event from
the datastore to indicate that the store has been unlocked. Callers can just
wait until `unlock()` resolves and update the UI as needed.

### Errors

There are two types of errors relevant to locking/unlocking the datastore:
first, the datastore should throw an error if unlocking was unsuccessful so that
the UI can inform the user that they made a mistake and should try again. In
addition, the datastore should throw an error if any preconditions are violated
(e.g. the datastore hasn't been initialized).

## Frontend (Extension)

All direct interaction with the datastore will happen in the background script
(since that's where the datastore lives anyway). This adds a layer of
indirection for the UI to contend with. In particular, the background script's
message port should accept requests to check the lock status and unlock the
datastore.

### Lock Status

The following shows the request/response expected for determining lock status:

```js
// Request
{ type: "locked" }

// Response
{ locked: Boolean }
```

### Unlocking

The following shows the request/response expected for unlocking the datastore:

```js
// Request
{ type: "unlock",
  password: String }

// Response
{}
- or -
UnlockError
```

In addition to providing a direct response to the request to unlock, the
background script should broadcast the fact that the store was unlocked so that
other UI contexts know to update their state.

### Locking

The following shows the request/response expected for locking the datastore
(note: manually locking is out of our initial scope):

```js
// Request
{ type: "lock" }

// Response
{}
```

Like unlocking above, the background script should broadcast the fact that the
store was locked so that other UI contexts know to update their state.

### Event-Based Locking

There are a variety of events that can be fired to cause the datastore to lock,
some of them platform-specific (e.g. KeePass supports locking the store when
someone RDPs in). This is compounded by the fact that our mobile apps may be
native, meaning our integration with OS-level events will probably not be
portable between desktop and mobile. (I'm not sure whether we'll be able to use
the existing `lockbox-datastore` package on native-mobile.)

Based on the above, I suggest that we keep OS-level hooks out of the datastore
package. Each hook could reside in its own node package, and consumers (read:
the frontend) could depend on them as needed.

Event hooks should have no specific knowledge of the datastore and will be
hooked up to the store via the background script in frontend (i.e. the frontend
adds a listener to the event and calls `DataStore.lock()` when it fires).

## Scope

### Now

Right now, we should focus on manually unlocking the datastore (assuming a
master password is set) and automatically locking it when Firefox closes. This
is the minimum we'd need for the locking/unlocking to be useful.

### Later

Later, we should add support for manually locking as well as event-based
locking. As a first pass, we should probably support time-based locking and
locking when the desktop locks/the screen turns off.
