Feature: the Mirage client provides methods for setting responses and loading default responses.
  There is no need to escape any parameters before using the client api as this is done for you.

  Patterns can be either a string or regex object.

  Background:
    Given the following gems are required to run the Mirage client test code:
    """
    require 'rubygems'
    require 'rspec'
    require 'mirage/client'
    """


  Scenario: Setting a basic response
    Given I run
    """
    Mirage::Client.new.put('greeting','hello')
    """
    When I send GET to 'http://localhost:7001/mirage/responses/greeting'
    Then 'hello' should be returned

  Scenario: Setting the method that a response should be returned on
    Given I run
    """
    Mirage::Client.new.put('greeting', 'Hello Leon') do |response|
      response.method = 'POST'
    end
    """
    When I send GET to 'http://localhost:7001/mirage/responses/greeting'
    Then a 404 should be returned
    When I send POST to 'http://localhost:7001/mirage/responses/greeting'
    Then 'Hello Leon' should be returned


  Scenario: Setting a response with required body content
    Given I run
    """
    Mirage::Client.new.put('greeting', 'Hello Leon') do |response|
      response.method = 'POST'
      response.add_body_content_requirement /leon/
    end
    """
    When I send POST to 'http://localhost:7001/mirage/responses/greeting'
    Then a 404 should be returned
    When I send POST to 'http://localhost:7001/mirage/responses/greeting' with request entity
    """
     <greetingRequest>
      <name>leon</name>
     </greetingRequest>
    """
    Then 'Hello Leon' should be returned

  Scenario: Setting a response with a request parameter requirement
    Given I run
    """
    Mirage::Client.new.put('greeting', 'Hello Leon') do |response|
      response.method = 'POST'
      response.add_request_parameter_requirement :name, /leon/
    end
    """
    When I send POST to 'http://localhost:7001/mirage/responses/greeting'
    Then a 404 should be returned
    When I send POST to 'http://localhost:7001/mirage/responses/greeting' with parameters:
      | name | leon |

    Then 'Hello Leon' should be returned

  Scenario: setting a response as default
    Given I run
    """
    Mirage::Client.new.put('greeting', 'default greeting') do |response|
      response.default = true
    end
    """
    When I send GET to 'http://localhost:7001/mirage/responses/greeting/for/joel'
    Then 'default greeting' should be returned


  Scenario: Setting the content type
    Given I run
    """
    Mirage::Client.new.put('greeting', '<xml></xml>') do |response|
      response.content_type = 'text/xml'
    end
    """
    When I send GET to 'http://localhost:7001/mirage/responses/greeting'
    And the response 'content-type' should be 'text/xml'

  Scenario: Priming Mirage
    Given Mirage is not running
    And I run 'mirage start'

    When the file 'responses/default_greetings.rb' contains:
    """
    prime do |mirage|
      mirage.put('greeting', 'hello')
      mirage.put('leaving', 'goodbye')
    end
    """
    And I run
    """
    Mirage::Client.new.prime
    """
    And I send GET to 'http://localhost:7001/mirage/responses/greeting'
    Then 'hello' should be returned

    When I send GET to 'http://localhost:7001/mirage/responses/leaving'
    Then 'goodbye' should be returned

  Scenario: Priming Mirage when one of the response file has something bad in it
    Given the file 'responses/default_greetings.rb' contains:
    """
    Something bad...
    """
    When I run
    """
    begin
      Mirage::Client.new.prime
      fail("Error should have been thrown")
    rescue Exception => e
      e.is_a?(Mirage::InternalServerException).should == true
    end
    """

  Scenario: Setting a file as a response
    Given the file 'test_file.txt' contains:
    """
    test content
    """
    And I run
    """
    Mirage::Client.new.put('download', File.open('test_file.txt'))
    """
    When I send GET to 'http://localhost:7001/mirage/responses/download'
    Then the response should be the same as the content of 'test_file.txt'

  Scenario: Setting a response status code
    Given I run
    """
    Mirage::Client.new.put('greeting', 'hello'){|response| response.status = 203}
    """
    When I send GET to 'http://localhost:7001/mirage/responses/greeting'
    Then a 203 should be returned


  Scenario: Setting a response with a delay
    Given I run
    """
    Mirage::Client.new.put('greeting', 'hello'){|response| response.delay = 2}
    """
    When I send GET to 'http://localhost:7001/mirage/responses/greeting'
    Then it should take at least '2' seconds
