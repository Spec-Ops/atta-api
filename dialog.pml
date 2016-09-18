@startuml

skinparam {
    backgroundColor transparent
    defaultFontName Helvetica
    shadowing false
}
skinparam sequence {
    DividerBackgroundColor transparent
    LifeLineBackgroundColor transparent
}

Actor Tester
Participant "WPT Run Interface" as wpt
Participant "Test Window" as test
Participant "ATTA" as atta
Participant "AT API" as atapi

Tester->wpt: Select tests
wpt->Tester: Shows matching test count
Tester->wpt: Start Test

group For each test selected

  wpt->test: Load test case

  Note right
      Test window is
      created the first time.
  End note

  test->atta: start (name, URI)

  Note right
      Communication with ATTA via HTTP
      to localhost port 4119
  End note

  atta<->atapi: Interrogate test window
  atta->test: READY (API name, etc)

  group For each step in test

    test->atta: test (element, things to look for)
    atta<->atapi: Get info about element
    atta->test: OK (result for each thing)

    test->atta: test (element2, things to look for)
    atta<->atapi: Get info about element2
    atta->test: OK (result for each thing)

  end

  test->atta: end

  atta<->atapi: Cleanup event listeners etc.

  test->wpt: Deliver results of each "subtest"

  wpt->Tester: Update table of results
end

wpt->Tester: Make results available in JSON

title WPT Dialog with ATTA

@enduml
