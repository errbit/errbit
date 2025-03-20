# Some Tips to help you when you develop on Errbit

## Install direnv

[direnv](https://github.com/direnv/direnv) awesome tool. We recommend
install and use it for development.

## Configure HTTPS for localhost

### Install software

[mkcert](https://github.com/FiloSottile/mkcert)

```shell
brew install mkcert nss
```

### Install root cert

```shell
mkcert -install
```

### Generate certificates

```shell
mkcert errbit.lvh.me localhost 127.0.0.1 ::1
```

Rename the two generated files to `errbit.lvh.me.pem` and `errbit.lvh.me.key.pem` respectively.

### Update Procfile.dev

Uncomment `web-https` and comment `web`.

### Run

TODO
