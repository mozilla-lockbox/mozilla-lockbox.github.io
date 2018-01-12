---
layout: page
title: Remote Storage for Backup and Cross-device Synchronization
---

# Terms

For the purposes of this document, the various states are used:

* `stable` - An item whose representation is agreed to by both remote and local storage.
* `remote` - An item whose representation changed in remote storage compared to the current stable state.
* `local` - An item whose representation change in local storage compared to the current stable state..
* `working` - An item in the process of conflict reconciliation

The following terms are also used:

* `item` - The representation of a Lockbox entry (i.e., stored login credentials), realized as a JSON object
* `record` - The persisted representation of an item or keystore; this contains additional unencrypted metadata alongside the encrypted item, realized as a JSON object

#Tracking and Staging Changes

All changes to items and keystores are tracked in IndexedDB; if the datastore is locked and there are conflicts that need to be reconciled, it may not be possible to process the changes until the datastore is unlocked.

## Local Changes

Changes made locally against the stable collection are tracked in the `localchange` collection:
```json
{
  "key": integer auto,
  "collection": "items" | "keystores",
  "target": string {collection}.id,
  "action": "add" | "update" | "remove",
  ? ("record": JSON record)
}
```

## Remote Chnages

Changes received from the remote storage are tracked in the `remotechange` collection:
```json
{
  "key": integer auto,
  "collection": "items" | "keystores",
  "target": string {collection}.id,
  "action": "add" | "update" | "remove",
  ? ("record": JSON record)
}
```


# Process

The following steps are performed during a sync:

1. Examine markers
2. fetch remote changes
3. reconcile conflicts
4. apply remote changes to stable
5. apply local changes to remote and stable
6. advance markers

## Markers

Each sync operation begins with examining the collection markers and ends with advancing those markers.  Each collection marker is the `ETag` HTTP response header value from the previous operation; if there is no previous sync operation, the value is treated as `0`.  The marker is stored locally in an indexed database via the `markers` collection:

```json
{
  "collection": "keystores" | "items",
  "etag": string
}
```

* `collection` is the primary key, and is name of the collection (e.g., "keystores" or "items")
* `etag` is the latest value of the ETag HTTP response header

## Fetching from Remote

The next step of a sync operation is to fetch the remote changes.

Keystores
```json
{
  "group": string defaults to "",
  "id": string,
  "encrypted": <JWE compact serialization of keystore data>,
  "last_modified": integer
}
```

Items
```json
{
  "id": <UUID locally generated>,
  "active" : "active" | "",
  "origins": *[ <base64url HMAC of plaintext origins > ],
  "tags": *[ <base64url HMAC of plaintext tags > ],
  "encrypted": <JWE compact serialization of item data>,
  "last_modified": integer
}
```

## Reconciling Conflicts

Conflicts can occur when a change is made both in the local state and remote state.  For instance, the user made changes to an item's title on their mobile device while there was no network access (e.g., airplane mode), and also made changes to the same item's tags ore origins on their desktop.

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
* Apply the `last_modified` value from the matching `remotechanges` record.
* Change the matching record in `localchanges` to this record.

## Applying Remote Changes to Stable


# Occurrence and Frequency

## Desktop

## Mobile
