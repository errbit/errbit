# Slack

The slack notification sends to [Slack](https://www.slack.com/).

## Configuration

### Add the Airbrake Notification Integration on Slack

### To configure Slack user mentions, please supply the environmental variables `ERROR_TO_USER_FORCE_ASSIGNMENT_MAP`, `ENV_TO_BRANCH_MAP`, and `SLACK_USER_ID_MAP` as detailed in `/docs/configuration.md`.

### To treat certain Slack alerts as notifications rather than exceptions, please supply the environmental variable `NOTIFICATION_ERROR_CLASS_NAMES` as detailed in `/docs/configuration.md`.

![Airbrake Notification](airbrake_notification.png)

### Hook URL

Copy the Hook URL specified by the Slack service.

![Hook URL](hook_url.png)

### Setup in Errbit

On the App Edit Page, click to highlight the slack integration.
Input the hook url from above into the field and click save.

![Errbit Notification Setup](errbit_notification.png)
