# OpenID Connect authentication

Errbit can delegate sign-in to any OpenID Connect provider - authentik,
Keycloak, Okta, Microsoft Entra ID, Dex, ... - through the
[omniauth_openid_connect](https://github.com/omniauth/omniauth_openid_connect)
strategy. The provider is discovered at runtime from its
`.well-known/openid-configuration` document, so Errbit only needs to be told
the issuer and the client credentials.

The provider appears next to the GitHub and Google buttons on the login page
and on a user's profile page, and it can be used on its own: the other two
strategies are disabled by setting `GITHUB_AUTHENTICATION=false` and
`GOOGLE_AUTHENTICATION=false`.

## Configuration

| Variable                  | Meaning                                                                                                                                 |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `OIDC_AUTHENTICATION`     | Enable the strategy. Defaults to `false`.                                                                                               |
| `OIDC_ISSUER`             | Issuer URL, **copied verbatim from the provider**, trailing slash included.                                                             |
| `OIDC_CLIENT_ID`          | Client ID of the application registered with the provider.                                                                              |
| `OIDC_SECRET`             | Client secret. Read straight from the environment, never parsed. Single-quote it in a `.env` file, see below.                            |
| `OIDC_SITE_TITLE`         | Name shown in the UI, e.g. `'authentik'`. Defaults to `OpenID Connect`.                                                                 |
| `OIDC_SCOPE`              | Scopes to request. Defaults to `'[openid,profile,email]'`; `email` is required.                                                         |
| `OIDC_REDIRECT_URI`       | Defaults to `https://$ERRBIT_HOST/users/auth/openid_connect/callback`. Set it when Errbit is not reached over https at `ERRBIT_HOST`.   |
| `OIDC_UID_FIELD`          | Claim that identifies the account. Defaults to `sub`.                                                                                   |
| `OIDC_AUTO_PROVISION`     | Create an Errbit account on first sign-in. Without it an admin has to create the account up front.                                      |
| `OIDC_AUTHORIZED_DOMAINS` | Comma separated email domains allowed to auto-provision, matched case-insensitively. Blank means *any* domain - set it whenever `OIDC_AUTO_PROVISION` is on. |

`OIDC_ISSUER` has to match what the provider's discovery document reports,
character for character. A missing or extra trailing slash makes discovery
fail with `OpenIDConnect::Discovery::DiscoveryFailed`.

Single-quote the secret when it goes into a `.env` file. dotenv expands
`$VAR`, runs `$(...)`, and stops an unquoted value at a `#`, so a secret
containing any of those is silently truncated or rewritten and the token
endpoint answers `invalid_client` with nothing to point at the cause.
Single quotes keep the value verbatim.

With `OIDC_AUTHENTICATION=true`, Errbit refuses to boot unless the issuer,
the client id, the secret and a redirect URI are all there. That applies to
**every** process that loads the application - the server, `rails console`,
`rails runner`, `rake errbit:bootstrap`, `rake assets:precompile` - so the
settings have to reach all of them, not just the web server.

`OIDC_AUTHORIZED_DOMAINS` is not access control - it only limits which
addresses may have an account created for them, and it is worth no more than
the provider's email claim. Restricting who may sign in is the provider's
job: bind a group or a policy to the application there.

Leave `OIDC_UID_FIELD` at `sub` unless you have a reason not to. `sub` is the
one claim a provider guarantees to be stable and unique; a `preferred_username`
can be reassigned to a different person, who would then inherit the Errbit
account.

## Account handling

Errbit looks the account up by the `OIDC_UID_FIELD` claim, stored on the user
as `oidc_uid`:

* **Known identity** - the user is signed in.
* **Unknown identity, already signed in** - the identity is linked to the
  current account, the same way the *Link account* button on the profile page
  does. An identity that another user already claimed is refused.
* **Unknown identity, `OIDC_AUTO_PROVISION` off** - sign-in is refused with
  *"There are no authorized users with ... login"*. Nothing is matched by
  email here: the account has to be linked from the inside, by signing in to
  it with its password and pressing *Link ... account*.
* **Unknown identity, `OIDC_AUTO_PROVISION` on** - the email is checked
  against `OIDC_AUTHORIZED_DOMAINS`, and then:
  * no account has that email address - a new, **non-admin** account is
    created;
  * an account has it, the provider reported `email_verified`, and that
    account is neither an admin nor already linked to a GitHub, Google or
    OpenID Connect identity - it is claimed;
  * otherwise sign-in is refused and the user is told to sign in with their
    password and link the account themselves.

Those rules keep an email address from being a way into an account that
already exists. Errbit has no way to tell whether a provider lets people set
their own address, so an existing account is only ever claimed on an address
the provider says it checked, and never one that already has an identity to
sign in with or an admin flag to inherit.

They do not stop an unverified address from *creating* an account: whoever
the provider lets through can be provisioned under a colleague's address,
which then blocks that colleague from the claim path for good. What limits
that is the group or policy bound to the application on the provider, with
`OIDC_AUTHORIZED_DOMAINS` as a second, weaker fence.
authentik sends `email_verified: false` unless told otherwise (2025.10 and
newer), so on a stock authentik existing users link their own accounts once
and new ones are provisioned normally. An authentik administrator who wants
the claim path can assert the claim from a property mapping.

Auto provisioning does not work together with
`ERRBIT_USER_HAS_USERNAME=true`: a username is then mandatory and nothing in
the callback supplies one, so account creation fails with *"Username can't be
blank"* on the login page. Leave auto provisioning off in that setup and
create the accounts by hand. (The Google strategy has the same gap.)

A newly created account is never an admin. Promote the first one by hand:

```console
$ bundle exec rails console
> User.find_by(email: "you@example.com").update!(admin: true)
```

Signing out of Errbit ends the Errbit session only - the provider session is
untouched, so the next sign-in may go through without a password prompt. That
is normal single sign-on behaviour.

## Example: authentik

### 1. Create the provider

In the authentik admin interface, under **Applications -> Providers**, add an
**OAuth2/OpenID Provider**:

| Field                   | Value                                                          |
|-------------------------|----------------------------------------------------------------|
| Name                    | `errbit`                                                       |
| Authorization flow      | your usual explicit- or implicit-consent flow                  |
| Client type             | **Confidential**                                               |
| Client ID / Client Secret | generated - copy both                                        |
| Redirect URI, strict    | `https://errbit.example.com/users/auth/openid_connect/callback` |
| Signing key             | a certificate, to sign the ID token with RS256                  |
| Scopes                  | `openid`, `profile`, `email`                                   |

The redirect URI must be the exact string Errbit sends. That is
`OIDC_REDIRECT_URI`, which by default is
`https://$ERRBIT_HOST/users/auth/openid_connect/callback`.

### 2. Create the application

Under **Applications -> Applications**, add an application, pick the provider
above and give it a **Slug**, e.g. `errbit`. Bind a group or policy to it if
only part of the directory should reach Errbit - that binding, not
`OIDC_AUTHORIZED_DOMAINS`, is the real access control.

### 3. Point Errbit at it

The issuer is `https://authentik.example.com/application/o/<slug>/`. Confirm
it and the endpoints with:

```console
$ curl -s https://authentik.example.com/application/o/errbit/.well-known/openid-configuration | jq .issuer
"https://authentik.example.com/application/o/errbit/"
```

Then:

```sh
OIDC_AUTHENTICATION=true
OIDC_SITE_TITLE='authentik'
OIDC_ISSUER=https://authentik.example.com/application/o/errbit/
OIDC_CLIENT_ID=<client id>
OIDC_SECRET='<client secret>'
OIDC_AUTO_PROVISION=true
OIDC_AUTHORIZED_DOMAINS=example.com
```

Restart Errbit. The login page gains a **Sign in with authentik** button.

## Troubleshooting

<dl>
  <dt>OpenIDConnect::Discovery::DiscoveryFailed</dt>
  <dd>
    <code>OIDC_ISSUER</code> does not match the <code>issuer</code> of the
    discovery document - usually a missing trailing slash - or Errbit cannot
    reach the provider. Compare with the <code>curl</code> above, from the
    Errbit host.
  </dd>
  <dt>The provider reports a redirect URI mismatch</dt>
  <dd>
    What Errbit sends is <code>OIDC_REDIRECT_URI</code>, defaulted from
    <code>ERRBIT_HOST</code>. It has to be registered on the provider
    verbatim, scheme and trailing path included.
  </dd>
  <dt>Sign-in ends on the login page with no error</dt>
  <dd>
    The sign-in link is a <code>POST</code>
    (<a href="https://github.com/cookpad/omniauth-rails_csrf_protection">omniauth-rails_csrf_protection</a>).
    Opening <code>/users/auth/openid_connect</code> in the address bar, or
    through a proxy that rewrites the request, will not work.
  </dd>
  <dt>Errbit redirects to http:// after a successful sign-in</dt>
  <dd>
    The proxy has to pass <code>X-Forwarded-Proto: https</code>. This does not
    affect <code>OIDC_REDIRECT_URI</code>, which is configured rather than
    derived from the request, but it does affect where Errbit sends the
    browser afterwards and whether <code>force_ssl</code> loops.
  </dd>
  <dt>An existing user is always told their account "already exists"</dt>
  <dd>
    The claim needs <code>email_verified</code> to be the JSON literal
    <code>true</code>; a provider that sends the string <code>"true"</code>
    is refused. Check the claim in the discovery-authenticated
    <code>userinfo</code> response, and either fix it on the provider or have
    the user link the account themselves. An account that already has a
    GitHub, Google or OpenID Connect identity, or the admin flag, is never
    claimed either - those are linked from the inside on purpose.
  </dd>
  <dt>"Account's email domain is not authorized for login"</dt>
  <dd>
    The email claim is outside <code>OIDC_AUTHORIZED_DOMAINS</code>, or the
    provider sent no email at all - check that the <code>email</code> scope is
    granted and that the account has an email address set.
  </dd>
  <dt>Invalid 'state' parameter</dt>
  <dd>
    The session cookie was lost between the redirect out and the callback -
    the state is compared against the session, nothing else. Check that the
    Errbit host is reached under a single name and that the cookie survives
    the round trip.
  </dd>
  <dt>OpenIDConnect::ResponseObject::IdToken::ExpiredToken</dt>
  <dd>
    The clock of the Errbit host is out of sync with the provider's.
  </dd>
</dl>
