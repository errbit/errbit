# HTTPS on localhost

Sometimes we need working HTTPS on localhost.

For e.g. testing google auth.

## Install `mkcert`

```shell
brew install mkcert nss
```

## Install local CA

## Generate certs

```shell
mkcert -key-file key.pem -cert-file cert.pem localhost 127.0.0.1 ::1
```

It will print something like this:

```shell
# Created a new certificate valid for the following names 📜
#  - "localhost"
#  - "127.0.0.1"
#  - "::1"
#
# The certificate is at "cert.pem" and the key at "key.pem" ✅
#
# It will expire on 7 May 2028 🗓
```

## puma part

```shell
puma -b 'ssl://0.0.0.0:3000?key=key.pem&cert=cert.pem'
```
