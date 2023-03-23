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

## Linking backtraces to custom repositories

Errbit builds backtraces with clickable links to Github and Bitbucket repositories.
The entry 'custom backtrace URL template' can be used to support clickable backtraces with other repositories.

The following fields are available for this template:

- %{branch}: The repo branch name
- %{file}: The relative file/path name of the backtrace file
- %{line}: The line number the backtrace occurred
- %{ebranch}: The URI escaped version of the branch name
- %{efile}: The URI escaped version of the file name

A few examples:

- Gitea: `https://errbit.example.com/repo/name/src/branch/%{branch}/%{file}#L%{line}`
- Gitlab: `https://errbit.example.com/repo/name/-/blob/%{branch}/%{file}#L%{line}`
