# OIDC aka OpenID Connect

## Environment variables

### `OIDC_ENABLED`

Enable OIDC?

Default: `false`

### `OIDC_NAME`

OIDC name. Give this OIDC name.

Default: `nil`

### `OIDC_ISSUER`

OIDC issuer.

Default: `nil`

### `OIDC_SCOPES`

List of scopes for OIDC.

Default: `openid,profile,email`.

### `OIDC_HOST`

OIDC host.

Default: `nil`

### `OIDC_CLIENT_ID`

OIDC client ID.

Default: `nil`

### `OIDC_SECRET`

OIDC secret.

Default: `nil`

### `OIDC_REDIRECT_URI`

OIDC redirect URI.

Default: `nil`

Example: `https://localhost:3000/users/auth/openid_connect/callback`

Replace `localhost:3000` with your application's host.

## Example configurations

### GitLab.com or any gitlab-powered instance

```shell
export OIDC_ENABLED="true"
export OIDC_NAME="gitlab"
export OIDC_ISSUER="https://gitlab.com"
export OIDC_SITE_TITLE="GitLab.com"
export OIDC_SCOPES="openid,profile,email"
export OIDC_HOST="gitlab.com" # or "gitlab.example.com"
export OIDC_CLIENT_ID="client-id"
export OIDC_SECRET="secret"
# NOTE: replace `localhost:3000` with your application's host
export OIDC_REDIRECT_URI="https://localhost:3000/users/auth/openid_connect/callback"
```
