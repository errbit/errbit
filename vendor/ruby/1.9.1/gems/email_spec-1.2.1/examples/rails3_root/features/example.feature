Feature: EmailSpec Example -- Prevent Bots from creating accounts

  In order to help alleviate email testing in apps
  As an email-spec contributor I want new users of the library
  to easily adopt email-spec in their app by following this example

  In order to prevent bots from setting up new accounts
  As a site manager I want new users
  to verify their email address with a confirmation link

  Background:
    Given no emails have been sent
    And I am a real person wanting to sign up for an account
    And I am on the homepage
    And I submit my registration information

  Scenario: First person signup (as myself) with three ways of opening email
    Then I should receive an email
    And I should have 1 email

    # Opening email #1
    When I open the email
    Then I should see "Account confirmation" in the email subject
    And I should see "Joe Someone" in the email body
    And I should see "confirm" in the email body

    # Opening email #2
    When I open the email with subject "Account confirmation"
    Then I should see "Account confirmation" in the email subject
    And I should see "Joe Someone" in the email body
    And I should see "confirm" in the email body

    # Opening email #3
    When I open the email with subject /Account confirmation/
    Then I should see "Account confirmation" in the email subject
    And I should see "Joe Someone" in the email body
    And I should see "confirm" in the email body

    When I follow "Click here to confirm your account!" in the email
    Then I should see "Confirm your new account"

    And "foo@bar.com" should have no emails

  Scenario: Third person signup (emails sent to others) with three ways of opening email
    Then "foo@bar.com" should have no emails
    And "example@example.com" should receive an email
    And "example@example.com" should have 1 email

    # Opening email #1
    When they open the email
    Then they should see "Account confirmation" in the email subject
    And they should see "Joe Someone" in the email body
    And they should see "confirm" in the email body

    # Opening email #2
    When "example@example.com" opens the email with subject "Account confirmation"
    Then they should see "Account confirmation" in the email subject
    And they should see "Joe Someone" in the email body
    And they should see "confirm" in the email body

    # Opening email #3
    When "example@example.com" opens the email with subject /Account confirmation/
    Then they should see "Account confirmation" in the email subject
    And they should see "Joe Someone" in the email body
    And they should see "confirm" in the email body

    When they follow "Click here to confirm your account!" in the email
    Then they should see "Confirm your new account"

  Scenario: Declarative First Person signup
    Then I should receive an email with a link to a confirmation page

  Scenario: Declarative First Person signup
    Then they should receive an email with a link to a confirmation page
  
  Scenario: Checking for text in different parts
    Then I should receive an email
    And I should have 1 email

    # Opening email #1
    When I open the email
    Then I should see "This is the HTML part" in the email html part body
    And I should see "This is the text part" in the email text part body

    # Opening email #2
    When I open the email with text "This is the HTML part"
    Then I should see "This is the HTML part" in the email html part body
    And I should see "This is the text part" in the email text part body

    # Opening email #3
    When I open the email with text /This is the HTML part/
    Then I should see "This is the HTML part" in the email html part body
    And I should see "This is the text part" in the email text part body
