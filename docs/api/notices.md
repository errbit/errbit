# Notices API Documentation

## List Notices

Returns notices visible to the authenticated user. The v1 API intentionally
has global visibility: authenticated users can see notices from all apps.

### Request

```shell
curl 'https://myerrbit.com/api/v1/notices?auth_token=USER_AUTHENTICATION_TOKEN&start_date=2015-04-01&end_date=2015-04-30&page=2&per_page=25'
```

Authentication uses a per-user authentication token, passed as the `auth_token`
query parameter. This is a bearer credential. The query-parameter form is
retained for API v1 compatibility.

Query-string credentials can be exposed in URLs, browser history, proxy logs,
and application logs.

Parameters:

- **start_date** and **end_date** - optional date range. The filter is
  applied only when both parameters are present.
- **page** - optional positive integer page number, defaulting to `1`.
- **per_page** - optional positive integer page size, defaulting to `100` and
  capped at `100`.

Malformed, blank, non-integer, and non-positive pagination values use their
defaults. Results are ordered by `created_at` ascending and `_id` ascending.

### Response

The response is an array with no pagination metadata. Request subsequent pages
when more results are needed.

```json
[
  {
    "_id": "552941336a756e4e71012345",
    "created_at": "2015-04-12T08:43:47.480Z",
    "message": "Something went wrong",
    "error_class": "RuntimeError"
  }
]
```

JSON is returned by default. XML is also supported with `format=xml` or an XML
`Accept` header, while retaining the same array response shape and fields.

For example, request XML explicitly with:

```shell
curl 'https://myerrbit.com/api/v1/notices?auth_token=USER_AUTHENTICATION_TOKEN&start_date=2015-04-01&end_date=2015-04-30&page=1&per_page=10&format=xml' \
  -H 'Accept: application/xml'
```

An XML response has the following shape:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<objects type="array">
  <object>
    <_id>552941336a756e4e71012345</_id>
    <created-at type="dateTime">2015-04-12T08:43:47Z</created-at>
    <message>Something went wrong</message>
    <error-class>RuntimeError</error-class>
  </object>
</objects>
```
