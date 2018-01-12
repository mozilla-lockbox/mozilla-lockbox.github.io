---
layout: page
title: Remote Storage for Backup and Cross-device Synchronization
---

# Terms

For the purposes of this document, the various states are used:

* `stable` - An item or keystore whose representation is agreed to by both remote and local storage.
* `remote` - An item or keystore whose representation changed in remote storage compared to the current stable state.
* `local` - An item or keystore whose representation change in local storage compared to the current stable state..
* `working` - An item or keystore in the process of conflict reconciliation.

The following terms are also used:

* `item` - The representation of a Lockbox entry (i.e., stored login credentials), realized as a JSON object.
* `keystore` - The representation of Lockbox's item keystore, realized as a JSON objet.
* `record` - The persisted representation of an item or keystore; this contains additional unencrypted metadata alongside the encrypted item, realized as a JSON object.

# Device-Local Caches

All pending changes to items and keystores are tracked in IndexedDB; if the datastore is locked and there are conflicts that need to be reconciled, it may not be possible to process the changes until the datastore is unlocked.

Changes are first placed in the `pending` collection before they are applied to the stable collections (`items` and `keystores`).  The structure of a `pending` record is:

```json
{
  "key": integer auto,
  "collection": "items" | "keystores",
  "id": string {collection}.id,
  "action": "add" | "update" | "remove",
  "last_modified": integer,
  "record": JSON record
}
```

* `key` [**integer**] (_primary key_, _auto-incremented_) - A primary key for the pending change record.
* `collection` [**string**] (_indexed_) - The target collection; can one of "items" or "keystores".
* `id` [**string**] (_indexed_) - The target record identifier; this is equal to the affected `id` of the record in `items` or `keystores`.
* `action` [**string**] - The type of change made; can be one of "add" , "update", or "delete".
* `record` [**JSON**] - The complete record of the change; for a removed item, the only properties expected are:
  - `last_modified` (set to the relevant server timestamp, or `0` if not known)
  - `deleted` (set to `true`)

## Staging and Tracking Changes

When an item or keystore is changed locally, a record is inserted/updated in the `pending` collection rather than directly impacting the `items` or `keystores` directly.  When remote changes are fetched, a record for each is inserted/updated in the `pending` collection.

In both scenarios, the `pending` collection is first queried for an existing record (by source, collection, and id).  If there is an existing record, it is updated with the latest; otherwise a new record is inserted.

# Remote Storage

The remote storage is manaaged via a [Kinto](https://kinto.readthedocs.io/) server instance.  Authentication and authorization to this remote storage service is performed using [Firefox Accounts](./fxa.md) and [OAUTH](https://oauth.net/) bearer tokens, with at least the following scopes:

* `profile` - Access to the user's identifier (uid).
* `https://identity.firefox.com/apps/lockbox` - The Lockbox application feature.

Lockbox uses the following collections in the (per-user) `default` bucket:

* `lockbox_items` - The collection of Lockbox item records.
* `lockbox_keystores` - The collection of Lockbox item keystores (usually there is only one entry).

# Process

The following steps are performed during a sync:

1. Fetch remote changes
3. Reconcile conflicts
4. Apply remote changes to stable
5. Apply local changes to remote and stable

A sync operation runs these steps for each collection ("items" and "keystores").

## Markers

Each sync operation begins with examining the collection markers and ends with advancing those markers.  Each collection marker is the `ETag` HTTP response header value from the previous operation; if there is no previous sync operation, the value is treated as `0`.  The marker is stored on the device in IndexedDB via the `markers` collection:

```json
{
  "collection": "keystores" | "items",
  "etag": string
}
```

* `collection` [**string**] (_primary key_) - The name of the collection; this can be one of "items" or "keystores".
* `etag` [**string**] - The latest remote server timestamp for the associated collection, conveyed as the ETag HTTP response header.

## Fetching from Remote

The first step of a sync operation is to fetch the remote changes.  Within a remote fetch:

1. A read/write IndexedDB transaction is opened against the `markers` and `pending` collections.
2. the marker for the collection is retrieved, if available
3. A GET HTTP request is made for the collection; if a marker is available it is passed via the `_since` query parameter, otherwise no `_since` parameter is specified.
3. Each record in the HTTP response is examined and applied to the `pending` collection:

  - If a record for the "remote" source with the given collection and id already exists, it is updated to match the retrieved record;
  - Otherwise, a new record is inserted.

4. The `markers` record for this collection is updated with the ETag HTTP response header value.
5. The IndexedDB transaction is committed.

## Reconciling Conflicts

Conflicts can occur when a change is made both in the local state and remote state.  For instance, the user made changes to an item's title on their mobile device while there was no network access (e.g., airplane mode), and also made changes to the same item's tags ore origins on their desktop; or the user added an item independently on both devices, resulting in a conflict of the keystores.

In most conflict cases, the datastore needs to be unlocked before the conflicts can be reconciled; such changes will be held until the datastore is unlocked, and all other changes will be applied is possible.

The overall process here is:

1. A read/write IndexedDB transaction is opened against the `pending` and targeted collection (`items` or `keystores`).
2. The `pending` collection is queried for all records for the given collection and separated into distinct maps (id => record) based on source ("local" versus "remote").
3. Each element in the "remote" map is examined:

  - If there is no corresponding element in the "local" map; insert/update/remove the matching record in the target collection, delete the record from the `pending` collection, and remove it from the map.
  - If the corresponding "local" record is a "remove" while this "remote" record is an "update"; update the matching record in the target collection, delete the "remote" and "local" records from the `pending` collection, and remove it from both maps.
  - The the corresponding "local" record is an "update" while this "remote" record is a "remove"; delete the "remote" record from the `pending` collection, and remove it from the "remote" map.
  - If the corresponding "local" record **and** the "remote" record are both "update"; reserve it for conflict reconciliation.

4. Each element in the "local" map is examined:
5. The IndexedDB transaction is committed.

### Keystore Conflicts

Resolving keystore conflicts is relatively simple: just take the union of all keys.  While this can result in unused keys being present in the keystore, such a result is considered harmless.

### Item Conflicts

Reconciling conflicting changes within an item can be complex.  To start with, the following basic rules will apply:

* _Favor "update" actions over "remove" actions_. If an item is both removed and updated, treat it as updated.
* _Favor local changes over remote changes_. For a given change within an item, favor the local change over the remote change.

If the local action is "remove" and the remote action is "update", reconcile to the remote item.  If the local action is "update" and the remote action is "remove", reconcile to the local item.  Otherwise, reconcile remote/local "update" conflicts for an item as follows:

* Start with the "local" item and clone it to create a workspace item ("working").
* Compare the `title` and `disabled` properties:

  - if "local" does not match "stable", keep "local"
  - if "local" does match "stable", apply "remote"

* Compare the properties within `entry`; for each property:

  - If "local" does not match "stable", keep "local"
  - If "local" does match "stable", apply "remote"

* Perform a three-way merge (local, stable, remote) of the `origins` property.
* Perform a three-way merge (local, stable, remote) of the `tags` property.
* Difference and merge history entries, with local history entries ahead of remote history entries.
* Prepend a history entry, using "working.entry" as the source state and "remote.entry" as the target state.
* Set the `modified` property to the current date/time.

Once the item is reconciled, prepare a working record for the item:

* Recalculate and apply the search hashes for `origins` and `tags` values, respectively.
* Encrypt the item and replace the existing record's `encrypted` value.
* Update the `active` property to appropriately reflect the contained item's `disabled` state. 
* Apply the `last_modified` value from the matching "remote" record in `pending`.
* Change the matching "local" record in `pending` to this record.

## Applying Pending Changes

The next step after reconciling any conflicts is to apply the pending changes to the stable collections.  First any remote-sourced pending changes are applied to the device's stable collections, then local-sourced changes are applied to the remote storage, then finally those local-sourced pending are applied to the device's stable collections.

Remote-sourced changes are applied to the device's stable collections and cleared from the `pending` collection.

# Occurrence and Frequency

The following trigger a sync operation in the "desktop" extension:

* The browser is first started, and is bound to an FxA account;
* A change is made locally; or
* More than 30 seconds have elapsed since the last sync.

On mobile, the following trigger a sync operation:

* The application is first started, and is bound to an FxA account;
* A request to fill (via share sheet or Android's auto-fill API); or
* The application is in the foreground and more than 120 seconds have elapsed since the last sync.

The difference in time-based durations between desktop and mobile are an attempt to balance mobile power management (which is much more aggressive than typical personal computer operating systems) against convenient access to the user's data.

# Errors

The following errors can occur:

* `OFFLINE` - There is no network connectivity to the remote storage services; connectivity needs to be restored before sync can continue.
* `NETWORK` - A network error -- other than lack of connectivity -- was detected.
* `SYNC_LOCKED` - There is a conflict detected between the local and remote changes; the datastore needs to be unlock in order to reconcile.
* `SYNC_AUTH` - The remote service access tokens have expired or are missing; the user needs to authenticate before sync and continue.
