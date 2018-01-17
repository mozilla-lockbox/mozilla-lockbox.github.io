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

When an item or keystore is changed locally, a record is inserted/updated into the `pending` collection rather than directly applying to the `items` or `keystores`.  When remote changes are fetched, a record for each is inserted/updated into the `pending` collection.

In both scenarios, the `pending` collection is queried for an existing record (by source, collection, and id) before a record is inserted.  If there is an existing record, it is updated with the latest; otherwise a new record is inserted.

When listing or retrieving items, the `pending` collection (for source "local") is queried first, then the stable `items` collection is queried.

# Remote Storage

The remote storage is managed via a [Kinto](https://kinto.readthedocs.io/) server instance.  Authentication and authorization to this remote storage service is performed using [Firefox Accounts](./fxa.md) and [OAUTH](https://oauth.net/) bearer tokens, with at least the following scopes:

* `profile` - Access to the user's identifier (uid).
* `https://identity.firefox.com/apps/lockbox` - The Lockbox application feature.

Lockbox uses the following collections in the (per-user) `default` bucket:

* `lockbox_items` - The collection of Lockbox item records.
* `lockbox_keystores` - The collection of Lockbox item keystores (usually there is only one entry).

# Process

The following steps are performed during a sync:

1. Fetch remote changes
2. Examine pending changes (and apply non-conflicting remote changes to stable)
3. Reconcile any conflicts (and treat as local changes)

    - **NOTE**: this step is skipped if the datastore is locked

5. Apply local changes to remote

    - **NOTE**: this step is skipped for any unresolved conflicts.
    - **NOTE**: this step is skipped if a network connection to the remote storage service is not available.

6. Apply local changes to (on-device) stable collections

    - **NOTE**: this step is skipped for any changes not applied to the remote storage service.

Generally each step is executed for both collections before moving onto the next step; first for `items` then for `keystores`.

Each of the above steps opens and commits an IndexedDB transaction; this helps mitigate 

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
2. For each collection;

  1. The marker for the collection is retrieved if available.
  2. An HTTP "GET" request is made for the collection; the query parameter `_since` is set to the marker value if available, or omitted otherwise.
  3. Each record in the HTTP response is examined and applied to the `pending` collection:

      - If a record for the "remote" source with the given collection and id already exists, it is updated to match the retrieved record;
      - Otherwise, a new record is inserted.

4. The `markers` records for all collections are updated with the ETag HTTP response header value.
5. The IndexedDB transaction is committed.

## Examining and Applying Pending Changes from Remote

The next step after fetching remote changes is to examine the pending changes for conflicting changes, and applying any pending "remote" changes that have no conflicts.

This step is performed as follows:

1. A read/write IndexedDB transaction is opened against the `pending` and targeted collections (`items` and `keystores`).
2. For each collection (first `items`, then `keystores`):

    1. The `pending` collection is queried for all records for the given collection and separated into separate maps (id => record) based on `source` ("local" versus "remote").

    2. Each element in the "remote" map is examined and one of the following actions taken:

        * _There is no corresponding element in the "local" map_: insert/update/remove the matching record in the target collection, delete the record from the `pending` collection, and remove it from the "remote" map.
        * _This "remote" records is an "update" and there is a corresponding "local" record to "remove"_: update the matching record in the target collection, delete the "remote" and "local" records from the `pending` collection, and remove it from both maps.
        * _This "remote" record is a "remove" and there is a corresponding "local" record to "update"_: delete the "remote" record from the `pending` collection, and remove it from the "remote" map.
        * _This "remote" record is an "update" and there is a corresponding "local" record to "update"_: reserve to later reconcile the conflicts as appropriate ([`items`](#item-conflicts) or [`keystores`](#keystore-conflicts)).

3. The IndexedDB transaction is committed.

## Reconciling Conflicts

Conflicts can occur when a change is made both in the local state and remote state.  For instance, the user made changes to an item's title on their mobile device while there was no network access (e.g., airplane mode), and also made changes to the same item's tags ore origins on their desktop; or the user added an item independently on both devices, resulting in a conflict of the keystores.

**Note** that the datastore needs to be unlocked before conflicts can be reconciled; such changes will be held until the datastore is unlocked, and all other changes will be applied if possible.

### Keystore Conflicts

Resolving keystore conflicts is relatively simple: just take the union of all keys.  While this can result in unused keys being present in the keystore, such a result is considered harmless.

### Item Conflicts

Reconciling conflicting item changes start with the following basic rules:

* _Favor "update" actions over "remove" actions_. If an item is both removed and updated, treat it as updated.
* _Favor local changes over remote changes_. For a given change within an item, favor the local change over the remote change.

Item conflicts are reconciled as follows:

1. A read/write IndexedDB transaction is opened against the `pending` `items` collections.
2. The `pending` collection is queried for records targeting "items", and grouped by id.
3. For each unique id:

    1. A working item is constructed as follows:

        1. Start with the "local" item and clone it to create a workspace item ("working").
        2. Compare the `title` and `disabled` properties:

            - if "local" does not match "stable", keep "local"
            - if "local" does match "stable", apply "remote"

        3. Compare the properties within `entry`; for each property:

            - If "local" does not match "stable", keep "local"
            - If "local" does match "stable", apply "remote"

        4. Perform a three-way merge (local, stable, remote) of the `origins` property.
        5. Perform a three-way merge (local, stable, remote) of the `tags` property.
        6. Difference and merge history entries, with local history entries more recent than remote history entries.
        7. Prepend a history entry, using "working.entry" as the source state and "remote.entry" as the target state.
        8. Set the `modified` property to the current date/time.

    4. The working item is applied to the "local" record in `pending` as follows:

        1. The search hashes for `origins` and `tags` are recalculated and applied to the record.
        2. The `active` property is changed to properly reflect the working item's `disabled` state.
        3. The working item is encrypted using its item key; this ciphertext replaces the record's `encrypted` value.
        `disabled` state. 
        4. The `last_modified` value from the matching "remote" record in `pending` is applied to this record.

    5. The "remote" record in `pending` is deleted from the collection.

4. The transaction is committed.

## Applying Pending Changes

The next step after reconciling any conflicts is to apply the remaining pending changes.  At this step, all pending changes should originate from "local", and are applied as follows:

1. A read/write transaction IndexedDB transaction is opened against the `pending` and stable collections (`items` and `keystores`).

2. For each targeted collection (first `items` then `keystores`):

    1. The `pending` collection is queried for all records for the targeted collection; any `pending` record with unresolved conflicts is skipped.
    2. A kinto [batch operation](http://kinto.readthedocs.io/en/stable/api/1.x/batch.html) is constructed; the `body` of each element in `requests` is the `pending` record's `record` property, and a  
2. A remote batch operation is constructed

1.   First any remote-sourced pending changes are applied to the device's stable collections, then local-sourced changes are applied to the remote storage, then finally those local-sourced pending are applied to the device's stable collections.

# Occurrence and Frequency

The following trigger an automatic sync operation in the "desktop" extension:

* The browser is first started, and is bound to an FxA account;
* A change is made locally; or
* More than 30 seconds have elapsed since the last sync.

On mobile, the following trigger an automatic sync operation:

* The application is first started, and is bound to an FxA account;
* A request to fill (via share sheet or Android's auto-fill API); or
* The application is in the foreground and more than 120 seconds have elapsed since the last sync.

The difference in time-based durations between desktop and mobile are an attempt to balance mobile power management (which is much more aggressive than typical personal computer operating systems) against convenient access to the user's data.

Additionally, a user can trigger a sync operation manually.

# Errors

The following error reasons can occur:

* `OFFLINE` - There is no network connectivity to the remote storage services; connectivity needs to be restored before sync can continue.
* `NETWORK` - A network error -- other than lack of connectivity -- was detected.
* `SYNC_LOCKED` - There is a conflict detected between the local and remote changes; the datastore needs to be unlock in order to reconcile.
* `SYNC_AUTH` - The remote service access tokens have expired or are missing; the user needs to authenticate before sync and continue.
