# Errbit to Errbit-NG migration guide

In current moment, errbit-ng should be drop in replacement for errbit.
With few exceptions:

1. Default port (`PORT` env) changed to 3000 (sync rails defaults) for puma.
2. Default port in docker image is changed to 3000 (sync with rails defaults).
3. It should be safe just remove `PORT` env from any configurations.
4. You should not set `RACK_ENV` env if you don't know for what. It should be removed from any configurations.
