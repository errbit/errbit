Feature: Email-spec errors example
  In order to help alleviate email testing in apps
  As a email-spec contributor I a newcomer
  Should be able to easily determine where I have gone wrong
  These scenarios should fail with helpful messages

  Background:
    Given I am on the homepage
    And no emails have been sent
    When I fill in "Email" with "example@example.com"
    And I press "Sign up"

  Scenario: I fail to open an email with incorrect subject
    Then I should receive an email
    When "example@example.com" opens the email with subject "no email"

  Scenario: I fail to open an email with incorrect subject
    Then I should receive an email
    When "example@example.com" opens the email with subject /no email/

  Scenario: I fail to open an email with incorrect text
    Then I should receive an email
    When "example@example.com" opens the email with text "no email"

  Scenario: I fail to open an email with incorrect text
    Then I should receive an email
    When "example@example.com" opens the email with text /no email/

  Scenario: I fail to receive an email with the expected link
    Then I should receive an email
    When I open the email
    When I follow "link that doesn't exist" in the email

  Scenario: I attempt to operate on an email that is not opened
    Then I should receive an email
    When I follow "confirm" in the email

  Scenario: I attempt to check out an unopened email
    Then I should see "confirm" in the email body
    And I should see "Account confirmation" in the email subject
