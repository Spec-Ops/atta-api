The spec in this repo will describe the following:

## Proposed Architecture ##


The basic architecture of a client side test in the Web Platform Tests system is this:

```

  WEB BROWSER   <----->  CHILD WINDOW
  MAIN WINDOW            FOR INDIVIDUAL TEST
```

The main window acts as the driver, opening up a child window and populating it with data from the web test server (HTML, JS, etc).  In fully automated tests, some JS then evaluates the DOM or the network activity or whatever, then decides if the test passed or failed.  The JS API is well documented here [5].

My concept for ARIA tests would augment this general flow like this:

```
  WEB BROWSER   <----->  CHILD WINDOW         <----- HTTP TO ------>  WPTSERVE  <---> ARIA TEST CASES
  MAIN WINDOW            FOR INDIVIDUAL TEST         TEST SERVER                      IN HTML AND JS
                               ^ 
                               | 
                             HTTP 
                               |  
                               v
                          LOCAL ATTA  
```

The local ATTA is an "Assistive Technology Test Adapter".  It acts as a "fake" assistive technology client that attaches the AT API of the platform under test - the one on which the browser is running.  It listens on an HTTP socket on localhost for information about the window under test and the test criteria, then responds to the HTTP request with information about the success or failure of each test criteria.  The CHILD WINDOW then uses that response to record the result of the test.  If there are multiple tests for a given CHILD WINDOW (e.g., if the test needs to do some setup, then change state, then check that the state change is reflected) it will send additional information to the ATTA.  Otherwise it tells the MAIN WINDOW that it is done.  The MAIN WINDOW then cycles to the next test in the sequence and we continue.

The output of the main window is JSON that has basic information.  That information is used by reporting tools to maintain implementation reports that can help with CR criteria evaluation.  Test results reports and maintained by the w3c.  There are sample reports linked above.

Note that you do not need to develop the JS tests by hand.  The JSON that is being developed as part of the ARIA testable statements should be adequate to drive most testing. You can see an example of that approach in what we are doing for the Web Annotation Group in the annotation-model tree of the Web Platform Tests.

=== JSON Format ===

The ATTAcomm library takes a parameter that tells it what test or tests should be performed for a given individual test file (.html).  
This section documents the structure of that JavaScript Object and the expectations of each automation platform.

==== General Structure ====

This parameter to the ATTAcomm constructor is a JSON object shaped like this:

```
  { "title": "A title for the overall test case",
    "steps": [
      {
        "type":    "test", (this is the default and may be omitted)
        "title":   "What is being checked",
        "element": "ID_OF_ELEMENT",
        "test" :  {
          "APINAME": [
            [ 
              "role" | "state" | "object" | "event",
              "itemName",
              "expectedLiteral" | "<undefined>" | "<defined>" 
            ],...
          ],
          "API2NAME": [ ...
          ],...
      },
      {
        "type":    "script",
        "script":  "Eval-able JavaScript (e.g., to change the state of something in the DOM)"
      },
      {
        "type":    "event",
        "element": "ID_OF_ELEMENT",
        "event":   "event name (event will be triggered on element)"
      },
      {
        "title":   "Second thing being checked",
        "element": "ID_OF_ELEMENT",
        "test" : ...
      },...
    ]
  }
```

Where:

; `title` : The overall title for the test case (which is stored in a file with a suffix of :-manual.html").
; `steps` : A sequence of steps to carry out.
; `type` : The type of operation in the sequence.  One of "test", "script", or "event".  Defaults to "test".
; `title` : A description of the block.  In blocks of type "test" this is used as the name of the WPT "subtest".
; `element` : The ID of an element in the target window that is the target of the operation. 
; `script` : A block of JS that can be 'evalled' in the context of the test window to perform some DOM operation.
; `subtests` : A hash of A11Y API names where each entry is a list of assertions to be evaluated by the ATTA that claims to support the API with the corresponding `APINAME`.  Details on the layout of those assertions are defined below.

### Per-Platform Structures ###

Each platform ATTA has unique requirements for the format of the assertions.  A script will extract these structures from the tables in the [[ARIA 1.1 Testable Statements|ARIA 1.1 Testable Statements page]] and ensure they are in the proper format to feed into each ATTA. Note that if an ATTA receives an assertion that is in an unexpected format or is otherwise impossible to evaluate, the ATTA SHOULD return a result of "ERROR" and a message explaining the processing failure. 

#### ATK ####

#### AXAPI ####

#### iAccessible2 ####

#### MSAA ####

#### UIA ####

### ATTA Commands ###

The ATTA URI specifies a base URI for accessing the URI (by default, localhost listening on port 4119).  The environment must provide appropriate CORS headers so that the user agent does not prevent access to the information being returned by the ATTA.  Each ATTA command below is accessed in a RESTful fashion (e.g., ATTAuri + "/start").

#### start Command ####

`start` - new test starting; Parameters in a JSON object are:

* test - name of the test
* url - url of the test in the window being tested

Response should be a JSON structure that includes:

* status - "READY", "ERROR"
* statusText - any message about being ready
* ATTAname - name of the ATTA implementation
* ATTAversion - version of the ATTA implementation
* API - Name of the API supported by the ATTA
* APIversion - version of the API supported by the ATTA

#### test Command ####

Individual 'test statements' within a test file.  Parameters in a JSON object are:

* name - the name of the test
* id - "id" of the element to interrogate in the window
* data - JSON structure containing the a11y data to check. Note that this is an array where each member maps to a nested array of information from a 'row' in the testable statement. The exact structure and values of the information varies by Accessibility API, but in general have a structure like:
** type of item to evaluate (e.g., state, property, role, method)
** name of item to evaluate (e.g., ROLE_TABLE_CELL)
** condition to evaluate (e.g., &lt;undefined&gt;, &lt;defined&gt;, "LITERAL")

Note that in order to make the comparison of test results across platforms "apples to apples" similar, the 'rows' in the testable statement will be evaluated and their results collected into a single result for the overall 'test statement'. Any failure or other messages will be included in the result for that overall 'test statement'.

Response should be a JSON structure that is an array with the same number of items as the 'data' array above.  Each member of this array is an object with the following properties:

* status - "OK", "ERROR"
* statusText - message about error (see below)
* results - array of result objects corresponding to each array member in the 'data' input parameter with members:
** result - "PASS", "FAIL", "NOTRUN", "ERROR"
** message - explanatory information about the result if it is not "PASS"

A status of "ERROR" means the ATTA was unable to perform some task.  Example messages include:

* id could not be found in window
* window could not be found
* required parameter missing
* incorrect HTTP request method

A result of "ERROR" means the ATTA was unable to perform some task related to the evaluation of a specific test criteria.  Examples messages include:

* Unable to evaluate test condition

#### end Command ####

Tests in this file are complete.  No parameters

### Example Dialog ##

When a test starts up, it loads the ATTAconn.js script.  This script is initialized with information about the specific test. Once that is loaded, the test does the following:

1. Start a test - note that if this connection fails within a short timeout period, then the test reverts to "manual" mode.  The test will present information adequate for someone to manually inspect the A11Y structures and determine whether the overall test passes or fails.  However, we are designing for automation, so:
  * Send the 'start' command
  * ATTA confirms it can attach to the test window and responds with the name of the API under test and a status of "READY".  NOTE: If the ATTA does not respond with READY the system will act as if there is no ATTA available.
2. Set focus on the correct element (if required)
3. Test an assertion
  * Send the 'test' command along with the data for the API supported by the ATTA
  * Respond with the result of the evaluation
4. Repeat steps 3 and 4 until all the assertions in the testable statements for a given test are complete.
5. Complete the test
  * Send the 'end' command
6. Close out the test with WPT and continue to the next test case - repeating steps 1-5 until all selected tests are complete.

For each assertion above / result above, the ATTAcomm.js creates a WPT "subtest" for which it records the assertion being tested, the result of testing, and any messages that might have come in.  The overall, or aggregate, result of a "test" is the worst result of all the subtests that were executed (e.g., if there is 1 FAIL, the test FAILS.  If they all PASS, the test passes).

### Running the Tests ###

Tests are run using WPT's "runner" (and other mechanisms, but let's focus on this one).  Runner will run ANYTHING in the WPT tree, including the wai-aria tests when we get them in there.  Here is what the run interface looks like having executed a couple of tests using the architecture above:

[[File:Web tests.png|framed|center|Example Test Run Page]]
