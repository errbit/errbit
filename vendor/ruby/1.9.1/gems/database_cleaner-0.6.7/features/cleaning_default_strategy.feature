Feature: database cleaning
  In order to ease example and feature writing
  As a developer
  I want to have my database in a clean state with default strategy

  Scenario Outline: ruby app
    Given I am using <ORM>
    And the default cleaning strategy

    When I run my scenarios that rely on a clean database
    Then I should see all green

  Examples:
    | ORM          |
    | ActiveRecord |
    | DataMapper   |
    | MongoMapper  |
    | Mongoid      |
    | CouchPotato  |
