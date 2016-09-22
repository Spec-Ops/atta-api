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
box "Scope of testing"
Participant "WPT Run Interface" as wpt
Participant "Test Window" as test
end box
Participant "Platform\nA11Y Layer" as atapi

== Startup ==
Tester->wpt: Select tests
wpt->Tester: Shows matching test count
Tester->wpt: Start Test

== Repeat ==

  wpt->test: Load test case

  Note right
      Test window is
      created the first time.
  End note
    note right of atapi
        A11Y Testing
        happens over here
    end note


  test->test: Evaluates conditions via Javascript

  test->wpt: Deliver results of each "subtest"

  wpt->Tester: Update table of results

== Complete ==

wpt->Tester: Make results available in JSON


@enduml
