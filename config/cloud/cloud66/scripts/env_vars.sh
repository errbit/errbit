#!/bin/bash
FILE=/tmp/env_vars_done

if [ -f $FILE ]
then
	echo "File $FILE exists..."
else
	cd $RAILS_STACK_PATH
    echo "github_authentication: $GITHUB_AUTHENTICATION
    github_client_id: $GITHUB_CLIENT_ID
    github_secret: $GITHUB_SECRET
    ERRBIT_EMAIL_FROM: $MAILER_SENDER
    host: $ERRBIT_HOST
    email_from: $MAILER_SENDER
    smtp_settings:
    	:address: $SMTP_ADDRESS
        :domain: $SMTP_DOMAIN
        :port: $SMTP_PORT
        :authentication: :plain
        :enable_starttls_auto: "true"
        :user_name: $SMTP_USERNAME
        :password: $SMTP_PASSWORD" >> config/config.yml
    touch /tmp/env_vars_done
fi