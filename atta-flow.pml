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

Participant "Test Window" as test
Participant "ATTAcomm.js" as comm
Participant "ATTA" as atta
Participant "Platform\nA11Y Layer" as atapi

  test->comm: initialize
  comm->test: Register DOMContentLoaded\nevent handler
  test->comm: DOMContentLoaded fires

  comm->atta: start (name, URI)

  Note right
      Communication with ATTA via HTTP
      to localhost port 4119
  End note

  atta<->atapi: Interrogate window\nand environment
  atta->comm: READY (API name, etc)

  comm->atta: listen (events)
  atta<->atapi: Setup event listeners
  atta->comm: READY

    group step 1
    comm->atta: test (element, things to look for)
    atta<->atapi: Get info about element
    atta->comm: OK (result for each thing)
    end group

    group step 2
    comm->test: set aria-busy to true
    end group

    group step 3
    comm->atta: test (element, different\nthings to look for)
    atta<->atapi: Get info about element
    atta->comm: OK (result for each thing)
    end group

  comm->atta: end

  atta<->atapi: Cleanup event listeners etc.

@enduml
