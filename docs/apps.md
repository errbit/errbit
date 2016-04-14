# Apps
An Errbit app is a place to collect error notifications from your
external application deployments. Each one has a name and a unique API
key that your notifiers can use to send notices to Errbit.

## Old Application Versions
You may have many versions of an application running at a given time and
some of them may be old enough that you no longer care about errors from
those applications. If that's the case, set the LATEST APP VERSION field
for your Errbit app, and Errbit will ignore notices from older
application versions. Be sure your notifier is setting the
context.version field in its notifications (see
[https://airbrake.io/docs/](https://airbrake.io/docs/)).
