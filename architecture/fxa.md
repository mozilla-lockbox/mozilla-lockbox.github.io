---
layout: page
title: Integration with Firefox Accounts
---

# Integration with Firefox Accounts #

Integration with Firefox Accounts (FxA) uses [OAuth](https://oauth.net/); Lockbox applications (Web Extension and mobile) are OAuth public clients and FxA is the authorization service.  It also functions as the user profile service where that information is needed.

## OAuth Protocol Highlights ##

**NOTE:** The OAuth details herein proscribe details and assumptions for Lockbox applications, defining specifics to the options that OAuth allows.

FxA supports [OAuth 2.0][RFC6749] Authorization Code Grant flow, with some additions:

* [PKCE][PKCE] proof keys, using the `S256` challenge mode
* Application-scoped encryption keys derived from the user's credentials

The complete interactive sign in flow for an FxA OAuth client is:

1. Send an HTTPS `GET` request via a user agent to the authorization endpoint with query parameters
2. The user agent interacts with the user to complete the authorization request
3. Upon success, the FxA authorization endpoint redirects to the client's `redirect_uri`, including results as query parameters
4. The client requests an exchange of the authorization code for access (and refresh) tokens from the token endpoint using an HTTPS `POST` request
5. The FxA token endpoint validates the request and (upon success) provides the requested tokens
6. If user information is needed, the client sends an HTTPS `GET` request to the FxA userinfo endpoint (providing the access token as authorization)
7. The FxA userinfo endpoint validates the authorization and (upon success) provides the user's profile information

The hosted FxA deployments support [endpoint discovery](https://developer.mozilla.org/en-US/docs/Mozilla/Tech/Firefox_Accounts/Introduction#Endpoint_Discovery) as well as [documented details](https://developer.mozilla.org/en-US/docs/Mozilla/Tech/Firefox_Accounts/Introduction#Firefox_Accounts_deployments).

### Authentication and Authorization ###

The authorization portion starts by sending an HTTPS `GET` request to the FxA authorization endpoint (`/v1/authorization`) via a web user agent (e.g., web browser).  The request includes following as query parameters:

* `response_type` (**== `authorization_code`**) - The type of authorization response the client expects
* `access_type` (**== `offline`**) - Set to obtain a refresh token from the initial token exchange
* `client_id` - The provisioned client identifier
* `redirect_uri` - The URL to redirect the authorization response to
* `scope` - The set of scopes to authorize this client for, as a space separated list:
  - `profile` to obtain information about the user
  - `openid` to obtain an `id_token` for the user
  - `https://identity.mozilla.org/apps/lockbox` to obtain a Lockbox application-scoped encryption key
* `keys_jwk` - The ephemeral ECDH public key used to securely obtain application-scoped keys (see [Application Scoped Keys](#app-scoped-keys))
* `state` - A randomly generated state value used to verify the authorization response (see [State Values](#state-values))
* `code_challenge` - The [PKCE][PKCE] code challenge for this sign in attempt (see [PKCE Details](#pkce-details))
* `code_challenge_method` (**== `S256`**) - The PKCE code challenge method, which is always `S256`

The web user agent opens the provided authorization URL, loading and executing the FxA web content.  This FxA web content prompts with the user to authenticate using their FxA credentials, either to "sign in" or "sign up":
* **Existing User** - If the FxA web content determines the user has signed in with FxA previously (e.g., cookie information), it presents the "sign in" flow; displaying read-only fields of the user's identity (e.g., avatar image, display name, email address) and an input field for the password, with a button to "sign in"
* **New User** - FxA web content presents the "sign up" flow; displaying input fields for email address and password (and possibly other information), with a button to "sign up"

**NOTE:** If the user's account required verification (e.g., registering for a new account), the FxA web content directs them to look for an incoming email with either a link to follow or a code to enter.  Authentication does not complete until this verification step is performed.

Once the user has successfully authenticated their credentials, the FxA web content calculates authorization codes and application-scoped keys, encrypts the key bundle, and posts this information back to the FxA authorization endpoint.  The endpoint then redirects the web user agent to the client's provisioned redirect URI, including the following as query parameters:

* `code` - The authorization code
* `state` - The client's provided state value

The client parses and validates the query parameters; it **MUST** validate the `state` before proceeding with the token exchange.

### Initial Token Exchange ###

The client completes the sign in process by exchanging an authorization code for access and refresh tokens.  The client sends an HTTPS `POST` request to the token endpoint (`/v1/token`) with the following as "application/json" content:

* `grant_type` (**== `authorization_code`**) - The type of grant for the access token
* `client_id` -- The client's provisioned identifier
* `code` -- The authorization code
* `code_verifier` -- The PKCE proof verifier (see [PKCE Details](#pkce-details))

The FxA token endpoint validates the request parameters, and (upon success) returns the token information (at minimum the following):

* `access_token` - The (Bearer) access token used for other resource requests
* `token_type` (**== `bearer`**) - The type of access token
* `auth_at` - The UTC Unix timestamp (in seconds since epoch) when the access token was generated
* `expires_in` - The relative number of seconds the access token is valid for 
* `refresh_token` - The token used to obtain updated access tokens
* `id_token` - The OpenID Connect ID token (assuming `scope` included `openid`)
* `keys_jwe` - The encrypted keys bundle for this client (see [Aplication Scoped Keys](#application-scoped-keys))


### Refresh Token Exchange ###

If the client's access token is expired and it has a refresh token, it can request an updated access token from the FxA token endpoint. The client sends an HTTPS `POST` request to the token endpoint (`/v1/token`) with the following as "application/json" content:

* `grant_type` (**== `refresh_token`**) - To refresh an access token using a refresh token
* `client_id` - The client's provisioned identifier
* `refresh_token` - The refresh token from the initial token exchange response

The FxA token endpoint validates the request parameters, and (upon success) returns the updated token information (at a minimum the following):

* `access_token` - The (Bearer) access token used in other resource requests
* `token_type` (**== `bearer`**) - The type of access token
* `auth_at` - The UTC Unix timestamp (in seconds since epoch) when the access token was generated
* `expires_in` - The relative number of seconds the access token is valid for 

### State Values ###

The `state` value is generated randomly for each authorization attempt; it is 32 bytes of cryptographically random data and encoded as "BAS64URL".

The client includes the `state` in the authorization request, and the FxA authorization endpoint includes it in the redirected authorization response.

### PKCE Details ###

[PKCE][PKCE] provides a mechanism for public clients to integrity protect the authorization grant flow.  FxA uses PKCE in lieu of true client credentials (`client_id` and `client_secret`) for public clients.

PKCE uses a unique code for each sign in attempt; a challenge is included in the authorization request and a verifier is included in the token request, with the server verifying the authorization request's challenge matches the token request's verifier

The PKCE proof is initiated as part of the authorization request as follows:

* The client generates a `code_verifier` and `code_challenge` for each sign in attempt
  - The `code_verifier` is 32 bytes of cryptographically random data, encoded as [BASE64URL][BASE64URL]
  - The `code_challenge` is derived from the `code_verifier` by performing a SHA-256 hash, and encoding the result as [BASE64URL][BASE64URL]
* The client includes the `code_challenge` (and the `code_challenge_method` as `S256`) in the authorization request
* If authorization is successful, the FxA authorization endpoint records the challenge with the requesting `client_id` and authorization code.

Once the client has obtained the authorization code, the PKCE proof is verified as part of the token exchange request as follows:

* The client includes the `code_verifier` with the other request parameters in the token exchange `POST` request.
* The token endpoint verifies the `code_verifier` matches the recorded `code_challenge`, authorization code, and client identifier.
  - The server performs the same `BASE64URL(SHA-256(code_verifier))` operations as the client to verify
* If verification is successful, the token information is returned to the client

### Application Scoped Keys ###

Application scoped keys is an upcoming feature in FxA.  The keys are derived from the user's credentials, are only known by the FxA web content (**_not_** the FxA server(s)) and the user, and are specific to the application(s) provisioned.  The user's credentials cannot be reversed from the derived key.

The application scoped keys are represented in a bundle as a JSON object; each member of the bundle is the scope and the value is the JSON [JWK][JWK] of the symmetric encryption key:

```javascript
{
  "https://identity.mozilla.org/apps/lockbox": {
    "kty": "oct",
    "kid": "5676f4a1-9f72-4c64-a596-9762f69e8769",
    "k": "Aw0RkT3fxi2V-XBl8t1O-CdOqDwkQPOwB85NxrNXcdk"
  }
}
```

This value is encrypted using ephemeral ECDH keys from both the client and FxA web content.

In order for a client to request application scoped keys, it must be provisioned with the appropriate scope (for Lockbox `https://identity.mozilla.org/apps/lockbox`).

To obtain the application scoped key, the client generates an ephemeral ECDH key-pair before attempting to authorize the user.  In terms of [JWK][JWK], the client randomly generates an ECDH key:

* `kty` is `EC`
* `crv` is `P-256`

The client retains the **private** ECDH key in memory, and derives the **public** key from it. The **public** ECDH key is included as part of the authorization request via the `keys_jwk` parameter; the JWK JSON representation is serialized as UTF-8 and encoded using [BASE64URL][BASE64URL].

Once the client receives the response from the initial token exchange, the encrypted bundle is included via the `keys_jwe` member.  The value of this member is the [JWE][JWE] compact serialization using the following JOSE header parameters:

* `alg` is set to `ECDH-ES`
* `enc` is set to `A256GCM`
* `epk` is set to the FxA web content's **public** ECDH key

The client decrypts this JWE using its **private** ECDH key, and parses the resulting plaintext as the JSON above

### Token Notes ###

FxA access tokens are valid for 1209600 seconds (two weeks) by default, and can be revoked; FxA refresh tokens never expire and can be revoked.  One more more of these tokens are revoked when:

* The user changes their password
* The user resets their account (forgotten password) 
* The `POST /v1/destroy` RESTful API is called

## User Profile Information ##

Information about the signed in user can be obtained from the FxA userinfo endpoint.

The client sends an HTTPS `GET` request to the userinfo endpoint (`/v1/profile`), including the HTTP `Authorization` header set to `Bearer ` and the access token.

The userinfo endpoint validates the access token, and (upon success) provides at least the following information as "application/json":

* `uid` - The user identifier string
* `email` - The user's primary email address

**WARNING**: The user's email address should not be stored unencrypted without their consent.

## Browser Extension ##

The Lockbox extension uses the async method `browser.identity.launchWebAuthFlow()` for OAuth-based sign in.  This method returns a Promise, providing the redirect URL when fulfilled.

### Account States ###

* `unbound` -- This Lockbox instance is not bound to FxA.  All data is stored locally using weaker protections; the encryption key is a default or platform-specific value and the datastore is accessible.
* `unauthenticated` -- This Lockbox instance is bound to FxA, but the user is not signed into Lockbox; the encryption key is not known and the datastore is not accessible.
* `authenticated` -- This Lockbox instance is bound to FxA and the user is signed into Lockbox; the encryption key is known and the datastore is accessible.

### Initial State ###

The a user first installs Lockbox, the datastore is initialized using a default master key.  If access to secure device storage is available, a random master key is generated and stored there.

This allows a user to make use of Lockbox, retrieving/adding/updating/deleting entries.  However, none of this data is sent to remote cloud storage.

### Binding ###

When binding to an FxA account, the user clicks the "sign in" action (either from the full editor view or the condensed doorhanger view), which then triggers the following:

1. The extension calls the `browser.identity.launchWebAuthFlow()` with the following members in the `details`:
   - `interactive` is set to `true`
   - `url` is set to FxA's authorization endpoint, including the query parameters for this specific request
2. The browser opens a popup window requesting the user's FxA credentials
3. Once the user submits their FxA credentials, FxA verifies the credentials and returns the authorization redirect URI containing the response's query parameters.
4. The extension processes the authorization response and requests the initial token exchange
5. FxA verifies the extension's request and (upon success) returns the token information
6. The extension requests the user's profile information from the FxA userinfo endpoint, in order to obtain their FxA user identifier (`uid`)
   - The access token is provided as authorization
7. The FxA userinfo endpoint verifies the request and (upon success) returns the user's profile information
8. The extension records the user identifier, access token, expiration time, and id token in `browser.storage.local` (the refresh token and application scoped key are only retained in memory)
9. The local datastore is migrated from the default key to the new application scoped key

### Signing In ###

If the user attempts to access Lockbox while in the `unauthenticated` state (e.g., clicks the toolbar icon), the extension triggers the following:

1. The extension calls the `browser.identity.launchWebAuthFlow()` with the following members in the `details`:
   - `interactive` is set to `true`
   - `url` is set to FxA's authorization endpoint, including the query parameters for this specific request
2. The browser opens a popup window requesting the user's FxA credentials
3. Once the user submits their FxA credentials, FxA verifies the credentials and returns the authorization redirect URI containing the response's query parameters.
4. The extension processes the authorization response and requests the initial token exchange
5. FxA verifies the extension's request and (upon success) returns the token information
6. As the extension already has the user's information, it updates its record with the new access token, expiration time, and id token (the updated refresh token and application scoped keys are only retained in memory)
7. The local datastore is unlocked using the newly-obtained application scoped key
8. The extension moves the account state to `authenticated`
   - The toolbar icon is updated to indicate the user is signed in
9. The extension opens the full editor view

### Authenticated State ###

If the user attempts to access Lockbox while in the `authenticated` state via the toolbar icon, the user is presented with the condensed doorhanger view.

### Signing Out ###

When the user signs out (e.g., clicking the "sign out" action in the full editor view or condensed doorhanger view), the account state changes to `unauthenticated` and the extension performs the following:

* Clear any plaintext data from memory
* Clear master key(s) from memory
* Closes the full editor view (if opened)
* Closes the condensed doorhanger view (if opened)

## iOS Mobile Application

_Tee bee Dee_

## Android Mobile Application

_Tee bee Dee_

<!-- References -->

[BASE64URL]: https://tools.ietf.org/html/rfc4648#section-5
[JWE]: https://tools.ietf.org/html/rfc7516
[JWK]: https://tools.ietf.org/html/rfc7517
[PKCE]: https://tools.ietf.org/html/rfc7636
[RFC6749]: https://tools.ietf.org/html/rfc6749
[RFC6750]: https://tools.ietf.org/html/rfc6750
