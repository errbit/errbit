# Errbit to Errbit-NG migration guide

In current moment, errbit-ng should be drop in replacement for errbit.
With few exceptions:

1. Default port (`PORT` env) changed to 3000 (sync rails defaults) for puma.
2. Default port in docker image is changed to 3000 (sync with rails defaults).
3. It should be safe just remove `PORT` env from any configurations.
4. You should not set `RACK_ENV` env if you don't know for what. It should be removed from any configurations.
5. `MAX_THREADS` env was removed. Use default rails `RAILS_MAX_THREADS` and `RAILS_MIN_THREADS`.

Deprecations:

* MongoDB 4.0 is reached EOL at 21 Jun 2018. 4.0 support will be removed after first stable and public release of Errbit-NG.
* MongoDB 4.2 is reached EOL at 09 Aug 2019. 4.2 support will be removed after first stable and public release of Errbit-NG.
* MongoDB 4.4 is reached EOL at 25 Jul 2020. 4.4 support will be removed after first stable and public release of Errbit-NG.
* MongoDB 5.0 is reached EOL at 08 Jul 2021. 5.0 support will be removed after first stable and public release of Errbit-NG.
