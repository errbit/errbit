# Some Tips to help you when you develop on Errbit

## Avoid running acceptance test with phantomjs

Some acceptance test use phantomjs to interpret the Javascript in page.
To avoid this test you can launch your test by skipping js tag

```
bundle exec rspec spec --tag="~js"
```
