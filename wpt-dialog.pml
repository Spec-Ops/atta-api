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

Tester->wpt: Select tests
wpt->Tester: Shows matching test count
Tester->wpt: Start Test

group For each test selected

  wpt->test: Load test case

  Note right
      Test window is
      created the first time.
  End note

  test->test: Evaluates conditions via Javascript

  test->wpt: Deliver results of each "subtest"

  wpt->Tester: Update table of results
end

wpt->Tester: Make results available in JSON

title Simple WPT Dialog

@enduml
