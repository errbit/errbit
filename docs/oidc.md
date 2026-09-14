# OpenID Connect

Set `OIDC_AUTHENTICATION=true` to enable one provider. The callback URI is:

`https://<ERRBIT_HOST>/users/auth/openid_connect/callback`

Required settings when enabled: `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_SECRET`,
and `OIDC_REDIRECT_URI`. The provider host, scheme, and port are derived from
`OIDC_ISSUER`.

Optional settings:

- `OIDC_SITE_TITLE`, default `OpenID Connect`
- `OIDC_SCOPES`, default `openid,profile,email`
- `OIDC_UID_FIELD`, default `sub`
- `OIDC_AUTO_PROVISION`, default `false`
- `OIDC_AUTHORIZED_DOMAINS`, comma-separated exact email domains for provisioning

Users are matched by issuer and stable provider UID. A first-time identity can
be associated with an existing account, or provisioned when enabled, only when
the provider supplies a verified email address. Provider tokens are not stored.

Example for GitLab:

```sh
OIDC_AUTHENTICATION=true
OIDC_SITE_TITLE=GitLab
OIDC_ISSUER=https://gitlab.com
OIDC_CLIENT_ID=client-id
OIDC_SECRET=secret
OIDC_REDIRECT_URI=https://errbit.example.com/users/auth/openid_connect/callback
OIDC_SCOPES=openid,profile,email
OIDC_AUTO_PROVISION=false
```
