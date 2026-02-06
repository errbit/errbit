# OIDC aka OpenID Connect

## Environment variables

### `OIDC_ENABLED`

Enable OIDC?

Default: `false`

### `OIDC_NAME`

OIDC name. Give this OIDC name.

Default: `nil`

### `OIDC_SCOPES`

List of scopes for OIDC.

Default: `[]`

## Example configurations

### GitLab.com or any gitlab-powered instance

```shell
export OIDC_ENABLED="true"
export OIDC_NAME="gitlab"
export OIDC_SCOPES="openid,email,read_user"
export OIDC_HOST="https://gitlab.com" # or "https://gitlab.example.com"
export OIDC_CLIENT_ID="client-id"
export OIDC_SECRET="secret"
```
