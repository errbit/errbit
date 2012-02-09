Feature: Delayed Job support
  In order for developers using delayed_job to test emails
  I want to be able to provide a compatibility layer, which
  should run all delayed jobs before checking email boxes
  In order to populate deliveries done via send_later

  Scenario: Newsletter
    Given no emails have been sent
    And I go to request a newsletter
    Then I should receive an email
    And I should have 1 email
    When I open the email
    Then I should see "Newsletter sent" in the email subject
