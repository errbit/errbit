# Notices

This page describes how to look up notices in the Errbit UI.

## /locate/[notice_id]

When you hit this path in a browser (you have to be authenticated), it redirects
you to the associated Problem. Using the language used in Errbit code, Notices
belong to Errs, Problems can have many Errs, and Problems belong to Apps.

## /notices/[notice_id]

If you happen to know the specific notice_id (perhaps you are a javascript
client, and the server told you, like above), you can look up the specific
notice using this path in a browser.
