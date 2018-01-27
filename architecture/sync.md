---
layout: page
title: Cloud-based Sync and Backup
---

# Cloud-based Sync and Backup

Cloud-based synchronization can provide a user reliable access to their logins.  Building off the encrypt-always nature of [data storage] extends the secure protection of the user's data across their devices in a consistent manner.

## Core Technologies

The approach taken here depends heavily on the following technologies:

* [Kinto] for remote cloud storage; via the [kinto-http.js] library.
* [IndexedDB] for on-device data caching and management; via the [Dexie] library.

## Terms

For the purposes of this document, the various states are used:

* `stable` - An item or keystore whose representation is agreed on by both remote and local storage.
* `remote` - An item or keystore whose representation changed in remote storage compared to the current stable state.
* `local` - An item or keystore whose representation changed in local storage compared to the current stable state.
* `working` - An item or keystore in the process of conflict reconciliation.

The following terms are also used:

* `item` - The representation of a Lockbox entry (_e.g._, stored login credentials), realized as a JSON object.
* `keystore` - The representation of Lockbox's item keystore, realized as a JSON objet.
* `record` - The persisted representation of an item or keystore; this contains additional unencrypted metadata alongside the encrypted item, realized as a JSON object.

## Remote Storage

The remote storage is managed via a [Kinto] server instance.  Kinto is essentially a RESTful key/value record store, with records managed with a collection, and a collection managed within a bucket.  Buckets and collections can also have application-specific meta-data associated with them.  It can provide a per-user default bucket (referred to as "default").

Authentication and authorization to Kinto is performed using [Firefox Accounts][fxa] and [OAUTH] bearer tokens, with at least the following scopes:

* `profile` - Access to the user's profile information, especially their user identifier (uid).
* `https://identity.firefox.com/apps/lockbox` - The Lockbox application feature.

Lockbox uses the following collections in the (per-user) `default` bucket:

* `lockbox_items` (`"/buckets/default/collections/lockbox_items"`) — The collection of Lockbox item records.
* `lockbox_keystores` (`"/buckets/default/collections/lockbox_keystores"`) — The collection of Lockbox item keystores. Usually there is only one entry.

### Server Timestamps

All buckets, collections, and records have a server-maintained last modified timestamp.  This value is provided in a record/collection/bucket's representation under the `last_modified` property as an integer, and is returned as an [ETag] response header.

For lists (collections in a bucket, records in a collection), the timestamp is used on "list" GET requests via a `_since` query parameter to limit response data to any changes (including creates, updates, and deletes) after that timestamp.

For individual values (a record, or metadata on a collection or bucket), the timestamp is used via the `If-Match` HTTP request header to prevent updates or deletes if the record has changed since last operated on the server.

## Tracking and Staging

All pending changes to items and keystores are tracked in IndexedDB; if the datastore is locked and there are conflicts that need to be reconciled, it may not be possible to process the changes until the datastore is unlocked.

Changes are first placed in the `pending` collection before they are applied to the stable collections (`items` and `keystores`).  The structure of a `pending` record is:

```
{
  "key": integer auto,
  "source": "local" | "remote",
  "collection": "items" | "keystores",
  "id": string in the form "${collection}.id",
  "action": "add" | "update" | "remove",
  "last_modified": integer,
  "record": JSON record,
  "conflicts": integer
}
```

* `key` [**integer**] (_primary key_, _auto-incremented_) - A primary key for the pending change record.
* `collection` [**string**] (_indexed_) - The target collection; can one of "items" or "keystores".
* `id` [**string**] (_indexed_) - The target record identifier; this is equal to the record's `id` from the targeted collection (`items` or `keystores`).
* `action` [**string**] - The type of change made; can be one of "add" , "update", or "remove".
* `record` [**JSONObject**] - The complete record of the change:

    - For a "add" or "update" action, `record` is the complete record to insert (locally or remotely); or
    - For a "remove" action, `record` only contains the following properties:

        - `last_modified` (set to the relevant server timestamp, or `0` if not known)
        - `deleted` (set to `true`)

* `conflicts`: [**integer**] - the index of a record in the `pending` collection with which this record conflicts (absent or `0` if it does not conflict).

Whenever a change is to be tracked (whether that change comes from remote storage or a local modification), the `pending` collection is queried for an existing record (by source, collection, and id) before a record is inserted.  If there is an existing `pending` record, it is updated with the latest changes; otherwise a new record is inserted.

When an item or keystore is changed locally, a record is inserted/updated into the `pending` collection rather than directly applying to the `items` or `keystores` collections.  When remote changes are fetched, a record for each is inserted/updated into the `pending` collection.

### Markers

In addition to tracking the actual changes, the markers (_i.e._, [server timestamps](#server-timestamps)) are also tracked locally. The marker for each collection is stored on the device in IndexedDB via the `markers` collection:

```
{
  "collection": "keystores" | "items",
  "etag": string
}
```

* `collection` [**string**] (_primary key_) - The name of the collection; this can be one of "items" or "keystores".
* `etag` [**string**] - The latest remote server timestamp for the associated collection, conveyed as the ETag HTTP response header.

### On-Device Item Queries

When listing items — or retrieving a specific items — the `pending` collection (for source "local") is queried first, then the stable `items` collection is queried, with local items taking precedence over their stable ancestor.

### On-Device Item Changes

When a local change is made to an item, the follow is performed:

1. A read/write IndexedDB transaction is opened against the collections `pending` and the targeted stable collection (`items` or `keystores`).

2. The `pending` collection is queried for an existing record with `id` matching the modified record's id, in the "item" `collection` and the "local" `source`:
    -  If an existing `pending` record is not found, the "stable" item is used as the source for generating history patches and an empty record is initialized:
        - `source` is set to "local".
        - `collection` is set to "item".
        - `id` is set to the changed item's id.
        - `action` is set as appropriate ("add", "update", or "remove").
    - If an existing `pending` record is found, its recorded item is used as the source for generating history patches and this record is retained and updated to reflect these new changes:
        - If the `pending` record's `action` is "add" or "update" and this change is a "remove", the `action` property is set to "remove";
        - If the `pending` record's `action` is "remove" and this change is an "add" or "update", the `action` property is set to the incoming action;
        - Otherwise, the `pending` record's `action` property is unchanged.

4. The appropriate steps for the action are applied:

    - For "add":
        1. The new item is validated.
        2. If there is already a `pending` record for this item, a history entry is created and prepended using the changed item as the source and the `pending` item as the patch source.
        3. The `origin` and `tags` hashes are generated and applied to the pending `record` object.
        4. The item is encrypted using its item key (creating a new one if it does not yet exist) and applied to the `encrypted` property of the pending `record`.
    
    - For "update":
        1. The changed item is validated.
        2. A history entry is created and prepended using the changed item as the source and the appropriate source item as the patch source.
        3. The `origin` and `tags` hashes are generated and applied to the pending `record` object.
        4. The item is encrypted using its item key and applied to the `encrypted` property of the pending `record`.
        5. The `last_modified` value for the pending `record` is set to the value from the existing stable record, if present.

    - For "remove":
        1. The pending `record` property is set with the following properties:
            - `deleted` set to true.
            - `last_modified` set to the stable item's record, if present.

4. The `pending` record is inserted/updated.

5. The IndexedDB transaction is committed.

## Sync Process

The following steps are performed during a sync:

1. Verify authorization to remote storage service
    - **NOTE**: If this step fails, an error is propagated and the sync operation is terminated.

2. Fetch remote changes
3. Examine pending changes (and apply non-conflicting remote changes to stable)
4. Reconcile any "update" conflicts (and treat as local changes)
    - **NOTE**: this step is skipped if the datastore is locked

5. Apply local changes to remote
    - **NOTE**: this step is skipped for any unresolved conflicts.
    - **NOTE**: this step is skipped if a network connection to the remote storage service is not available.

6. Apply local changes to (on-device) stable collections
    - **NOTE**: this step is skipped for any changes not applied to the remote storage service.

Generally each step is executed for both collections before moving onto the next step; first for `items` then for `keystores`.

Each of the above steps opens and commits an IndexedDB transaction.  This helps to mitigate data loss; including if sync is interrupted for some reason, or if a conflicting remote change occurs from another device while sync is in progress.

### Verifying Remote Authorization

Before the sync operation can begin in earnest, authorization to the remote service is verified.

Verification is performed as follows:

1. The cached access token is examined; access token is missing or expired, an attempt is made to refresh it.
2. A request is made for the user's profile information:
  - If this request fails with an HTTP error code of **403 (Unauthorized)**, an attempt is made to refresh it.
  - If this request succeeds, the user's authorization is valid.

Expired, invalidated, or missing access token can be refreshed as follows:

1. The cached refresh token is examined; if there is no refresh token, any existing access token is cleared from device cache and verification fails with a `AUTH` error.
2. A `POST` HTTPS request is made to the FxA OAuth token endpoint, with a `grant_type` of "refresh_token" and including the cached refresh token:
    - If this request fails, any cached access and refresh tokens are cleared from device cache and verification fails with a `AUTH` error.
    - If this request succeeds, the newly obtained access token is cached along with its new expiration time, and the verification process starts over.

### Fetching from Remote

Once authorization is verified, the next step of a sync operation is to fetch the remote changes.  Within a remote fetch:

1. A read/write IndexedDB transaction is opened against the collections `markers`, `pending`, and targeted stable (`items` then `keystores`).
2. For each targeted collection:

    1. The marker for the collection is retrieved from the on-device cache, if available.
    2. An HTTP "GET" request is made for the collection; the query parameter `_since` is set to the marker value if available, or omitted otherwise.
    3. Each record in the HTTP response is examined and applied to the `pending` collection:
        1. The `pending` collection is queried for an existing "stable" record, matched by `id` with the "remote" source:
            - If there is an existing `pending` record, it will be updated to match the latest remote changes.
            - If there is no existing `pending` record, a new `pending` record will be created and inserted.
        2. Determine the `action` for this remote change; the targeted stable collection is queried for an existing record matched by `id`:
            - If the remote record has a `deleted` property set to `true` and there is an existing stable record, treat the remote change as "remove".
            - If the remote record is marked as "deleted" and there eis no existing stable record, discard the incoming remote change (and delete any existing `pending` "remote" record).
            - If there is an existing stable record, and its `encrypted` value exactly matches the incoming remote record, disregard the incoming remote change (and delete any existing `pending` remote record); the `last_modified` value of the stable collection's record is updated to match the remote record before the remote record is discarded.
            - If there is an existing stable record but its `encrypted` value does not exactly match the incoming remote record, treat the remote change as an "update".
            - If there is no existing stable record in the targeted collection, treat the remote change as an "add".
        3. The "remote" change record is inserted/updated into the `pending` collection.

4. The `markers` records for all collections are updated with the [ETag] HTTP response header value.
5. The IndexedDB transaction is committed.

### Examining and Applying Pending Changes from Remote

The next step after fetching remote changes is to examine the pending changes for conflicting changes, and applying any pending "remote" changes that have no conflicts.

This step is performed as follows:

1. A read/write IndexedDB transaction is opened against the `pending` and targeted collections (`items` and `keystores`).
2. For each collection (first `items`, then `keystores`):

    1. The `pending` collection is queried for all records for the given collection and separated into separate maps (id => record) based on `source` ("local" versus "remote").

    2. Each element in the "remote" map is examined and one of the following actions taken:
        * _There is no corresponding element in the "local" map_: insert/update/remove the matching record in the target collection, delete the record from the `pending` collection, and remove it from the "remote" map.
        * _This "remote" records is an "update" and there is a corresponding "local" record to "remove"_: update the matching record in the target collection, delete the "remote" and "local" records from the `pending` collection, and remove it from both maps.
        * _This "remote" record is a "remove" and there is a corresponding "local" record to "remove"_: remove the matching record in the target collection, delete the "remote" and "local" records from the `pending` collcetion, and remove it from both maps.
        * _This "remote" record is a "remove" and there is a corresponding "local" record to "update"_: delete the "remote" record from the `pending` collection, and remove it from the "remote" map.
        * _This "remote" record is an "update" and there is a corresponding "local" record to "update"_: The records are reserved to later reconcile the conflicts as appropriate ([`items`](#item-conflicts) or [`keystores`](#keystore-conflicts)):
            - The `conflicts` property of the "local" `pending` record is set to the `key` of the "remote" `pending` record.
            - The `conflicts` property of the "remote" `pending` record is set to the `key` of the "local" `pending` record.

3. The IndexedDB transaction is committed.

### Reconciling "Update" Conflicts

Conflicts can occur when a change is made both in the local state and remote state.  For instance, the user made changes to an item's title on their mobile device while there was no network access (_e.g._, airplane mode), and also made changes to the same item's tags ore origins on their desktop; or the user added an item independently on both devices, resulting in a conflict of the keystores.

**Note** that the datastore needs to be unlocked before conflicts can be reconciled; such changes will be held until the datastore is unlocked, and all other changes will be applied if possible.

The conflict reconciliation is performed as follows:

1. A read/write IndexedDB transaction is opened against the `pending` and stable collections (`items` then `keystores`).
2. All conflicting items are reconciled (potentially adding new keystore changes to be reconciled).
3. All conflicting keystores are reconciled.
4. The IndexedDB transaction is committed.

#### Keystore Conflicts

Resolving keystore conflicts is relatively simple; the final keystore is a union of all keys present in the (local and remote) pending and stable versions.

Note that any potential item conflicts also result in a union of all keys present in the (local and/or remote) pending and stable versions; this helps prevent potential data loss due to missing encryption keys.

The steps to resolve keystore conflicts are as follows:

1. The `pending` collection is queried for records targeting "keystores", and grouped by id.
2. For each unique id:

    1. A working keystore is constructed as follows:

        1. Start with the stable keystore and clone it to create a "working" keystore.
        2. If there is a "remote" `pending` keystore change, add all of its keys to this working keystore.
        3. If there is a "local" `pending` keystore change, add all of its keys to this working keystore.
    
    2. The working keystore is applied to the "local" `pending` record as follows:

        1. If there is no "local" `pending` record, start with an empty object.
        2. The keystore is encrypted using the scoped application key.
        3. If there is a "remote" `pending` record, its `last_modified` value is applied to this record.
        4. This  "local" record is inserted/updated into the `pending` collection.
    
    3. If there is a "remote" record, it is deleted from the `pending` collection.

#### Item Conflicts

Reconciling conflicting item changes start with the following basic rules:

* _Favor "update" actions over "remove" actions_. If an item is both removed and updated, treat it as updated.
* _Favor local changes over remote changes_. For a given change within an item, favor the local change over the remote change.

Item conflicts are reconciled as follows:

2. The `pending` collection is queried for records targeting "items", and grouped by id.
3. For each unique id:

    1. A working item is constructed as follows:

        1. Start with the "local" item and clone it to create a "working" item, keeping the following properties unchanged:

            - `created`

        2. Compare the `title`, `disabled`, and `last_accessed` properties:

            - if "local" does not match "stable", keep "local"
            - if "local" does match "stable", apply "remote"

        3. Compare the properties within `entry`; for each property:

            - If "local" does not match "stable", keep "local"
            - If "local" does match "stable", apply "remote"

        4. Perform a [merge](#merging-origins) (local, stable, remote) of the `origins` property.
        5. Perform a [merge](#merging-tags) (local, stable, remote) of the `tags` property.
        6. Perform a [merge](#merging-history) (local, stable, remote) of the `history` array.
        7. Prepend a history entry, using `working.entry` as the source state and `remote.entry` as the target state.
        8. Prepend a history entry, using `working.entry` as the source state and `stable.entry` as the target state.
        9. Set the `modified` property to the current date/time.

    4. The working item is applied to the "local" record in `pending` as follows:
        1. The search hashes for `origins` and `tags` are recalculated and applied to the record.
        2. The `active` property is changed to properly reflect the working item's `disabled` state.
        3. The working item is encrypted using its item key; this ciphertext replaces the record's `encrypted` value.
        4. The `last_modified` value from the matching "remote" record in `pending` is applied to this record.
        5. This "local" record is updated in the `pending` collection.

    5. The "remote" record in `pending` is deleted from the collection.

##### Merging `origins`

For **BETA**, only one origin is supported.  To that end, the merging strategy for origins is as follows:

1. Note the first element of "local", "remote", and "stable"; a missing value is treated as `null`.
2. Perform a comparison and retain the resolved value:
    - If "local" does not match "stable", keep "local"
    - If "local" does match "stable", apply "remote"

3. Set the `origins` property to an array with a single element; the single element is the value resolved as above.

##### Merging `tags`

For **BETA**, tags may not be supported.  However, potential loss here is far less critical than other properties; the general strategy is to "difference" and "merge" the values.

1. Calculate the changes made by "local":
    - Calculate the difference of "local" over "stable", and note as "local-add".
    - Calculate the difference of "stable" over "local", and note as "local-rem".

2. Calculate the changes made by "remote":
    - Calculate the difference of "remote" over "stable", and note as "remote-add".
    - Calculate the difference of "stable" over "remote", and note as "remote-rem".

3. Remove all values from "working" that are present in "local-rem" and "remote-rem".
4. Add all values to "working" that are present in "local-add" and "remote-add".
5. Filter "working" to remove any duplicates.

##### Merging `history`

History within an item is tracked as an ordered list of JSON objects, from newest to oldest.  The following steps are followed to merge histories:

1. The difference of remote history against the stable history is calculated, and prepended to the working item's `history`.
2. the difference of local history against the stable history is calculated, and and prepended to the working item's `history`.

### Applying Pending Changes

The next step after reconciling any conflicts is to apply the remaining pending changes.  At this step, all pending changes should originate from "local", and are applied as follows:

1. A read/write transaction IndexedDB transaction is opened against the `pending` and stable collections (`items` and `keystores`).

2. For each targeted collection (first `items` then `keystores`):

    1. The `pending` collection is queried for all records for the targeted collection; any `pending` record with unresolved conflicts is skipped.
    2. A Kinto [batch operation](http://kinto.readthedocs.io/en/stable/api/1.x/batch.html) is constructed and sent to the remote storage service; for each `pending` "local" record:
        - The `method` is set based on the record's `action` (`PUT` for "add" or "update"; `DELETE` for "remove").
        - The `path` is set to the full path of the targeted record.
        - The `body` is set to the record's `record` value.
        - The `headers` is set to include `If-Match` set to the `last_modified` property if known, or include `If-None-Match` set to "*" otherwise.
    
    3. The response from the remote storage service is processed; for each element in the response's `responses` array:
        - If it is a success, the corresponding `pending` record is applied to the on-device stable collection, the on-device stable collection's record's `last_modified` is updated to this response's `last_modified` value, and the `pending` record is deleted.
        - If it is a failure, the corresponding `pending` record is saved, and the failure is noted.

3. The IndexedDB transaction is committed.

If any records failed to be applied, the sync process is performed again.

### Initial vs. Incremental Sync

The lack of `markers` is used to indicate if an initial sync operation is necessary.  An initial sync follows the same process as the incremental sync process documented above, but treats all existing stable collection records as pending "local" "add" actions.

The following are performed prior to the rest of the sync process to prepare an initial sync:

1. A read/write IndexedDB transaction is opened against the `pending` and stable collcetions (`items` and `keystores`).
2. For each record in the stable collections, a record is inserted into the `pending` collection:
    1. The `pending` collections is queried to verify an existing record for this stable record is not present: if a `pending` record is present then its `record` property is updated; otherwise a new `pending` record is prepared:
        1. The `source` property is set to "local".
        2. The `action` property is set to "add"
        3. The `collection` and `id` properties are set appropriate to this stable record.
        4. The `record` property is set to a clone of this stable record.
    2. The new `pending` record is inserted/updated.

3. The IndexedDB transaction is committed.

## Occurrence and Frequency

Lockbox automatically attempts to sync the user's data between the device and remote storage transparently and unobtrusively.  Additionally, Lockbox provides a action that lets the user immediately trigger a sync.

### Desktop Triggers

The following trigger an automatic sync operation in the "desktop" extension:

* The user first "upgrades" or links an FxA account to Lockbox;
* The browser is first started and is bound to an FxA account;
* A change is made locally; or
* More than 30 seconds have elapsed since the last sync.

### Mobile Triggers

On mobile, the following trigger an automatic sync operation:

* The user completes initial onboarding of the application, including signing in/signing up for an FxA account;
* The application is first started (presumed to be bound to an FxA account);
* A request to fill (via share sheet or Android's auto-fill API); or
* The application is in the foreground and more than 120 seconds have elapsed since the last sync.

The difference in time-based durations between desktop and mobile are an attempt to balance mobile power management (which is much more aggressive than typical personal computer operating systems) against convenient access to the user's data.

## Sync Errors

The sync process has various points at which a failure can occur:

* `OFFLINE` - There is no network connectivity to the remote storage services; connectivity needs to be restored before sync can continue.
* `NETWORK` - A network error — other than lack of connectivity — was detected.
* `AUTH` - The remote service access tokens have expired or are missing; the user needs to authenticate before sync and continue.
* `SYNC_LOCKED` - There is a conflict detected between the local and remote changes; the datastore needs to be unlocked in order to reconcile.

In almost all cases, these errors occur outside of direct user interaction.  It is necessary to surface these conditions to the user in a manner that is not overly disruptive yet still noticeable.

## Telemetry

The following telemetry event is used to record sync interactions.

- Single "sync" event, on completion of the [process](#sync-process), with the following extra properties:

    - `fxa_uid` [**string**] - The FxA user identifier.
    - `error` [**string**] - The [failure reason](#errors), or `null` if sync was successful.

## Schema Changes

The on-device IndexedDB database originally documented in [data storage]().

### `keystore` Changes

The `keystore` IndexedDB object representation has the following additions:

* `id` [**string**] (_indexed_) the (remote storage) identifier for this keystore; this is calculated by taking a SHA-256 hash of `group`, encoded as a hex string.
* `last_modified` [**number**] the last modified timestamp from its remote storage equivalent; can be `undefined` for a keystore not yet synced.

The following indexes are removed:

* `uuid` - this was envisioned to be the server-provided identifier; however having the identifier consistently available on the device prior to sync is more advantageous.

**NOTE**: for `lockbox-datastore` version 0.2.0 and earlier, the removed indexes above do not contain (valid) information, so no effort to migrate it is made.

### `item` Changes

* `last_modified` [**number**] the last modified timestamp from its remote storage equivalent; can by `undefined` for an item not yet synced.


[data storage]: ./data-storage.md
[Dexie]: https://dexie.org/
[ETag]: https://en.wikipedia.org/wiki/HTTP_ETag
[FxA]: ./fxa.md
[IndexedDB]: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API
[Kinto]: https://kinto.readthedocs.io/
[kinto-http.js]: https://doc.esdoc.org/github.com/Kinto/kinto-http.js/
[OAuth]: https://oauth.net/
