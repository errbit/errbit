# Statistics API Documentation


## Get Stats

Represent error statistics. Render JSON if no extension specified on path.


### Request

Example:

```sh

curl 'http://myerrbit.com/api/v1/stats/app?api_key=6423d563e5285b34cb117f757b2bc7b1'

```

Parameters:

- **api_key** - required, this endpoints require authentication with an API Key.


### Response


```javascript

{
  name: "sample app",
  id: "552941336a756e4e71012345",
  last_error_time: "2015-04-12T08:43:47.480+00:00",
  unresolved_errors: 4
}

```
