Feature: Attachment testing support
  In order for developers to test attachments in emails
  I want to be able to provide working steps which inspect attachments

  Scenario: Email with Attachments
    Given no emails have been sent
    And I go to request attachments be sent to me
    Then I should receive an email
    When I open the email
    Then I should see 2 attachments with the email
    And there should be an attachment named "image.png"
    And there should be an attachment named "document.pdf"
    And attachment 1 should be named "image.png"
    And attachment 2 should be named "document.pdf"
    And there should be an attachment of type "image/png"
    And there should be an attachment of type "application/pdf"
    And attachment 1 should be of type "image/png"
    And attachment 2 should be of type "application/pdf"
    And all attachments should not be blank

  Scenario: Email without Attachments
    Given no emails have been sent
    And I am on the homepage
    And I submit my registration information
    Then I should receive an email
    When I open the email
    Then I should see no attachments with the email
