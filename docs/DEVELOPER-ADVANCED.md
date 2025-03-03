# Some Tips to help you when you develop on Errbit

## Install direnv

[direnv](https://github.com/direnv/direnv) awesome tool. We recommend
install and use it for development.

## Avoid running acceptance test with phantomjs

Some acceptance test use phantomjs to interpret the Javascript in page.
To avoid this test you can launch your test by skipping js tag

```shell
bundle exec rspec spec --tag="~js"
```
