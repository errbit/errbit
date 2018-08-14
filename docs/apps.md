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

## Excluding some apps when viewing problems (plus other awesome filtering in future)
Normally when you visit the /problems page, you see the most recently
received problems from all apps. Let's say you have a situation where
you have three apps in the system: awesomeapp, noisy_app, and
another_noisy_app. Further, let's assume that 99% of the problems
come from noisy_app and another_noisy_app, and that you don't care
about these apps for whatever reason. In this case, you could surf
to the problems page and exclude the noisy apps from view like this:
/problems?filter=-app:noisy_app%20-app:another_noisy_app

There is no UI for this feature, just the query param.
