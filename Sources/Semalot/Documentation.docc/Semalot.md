# ``Semalot``

An elementary counting semaphore for async tasks in Swift

## Overview

👨 "Semalot!"
👨‍🦱 "Semalot!!"
👴 "Semalot!!!"
🤦‍♀️ "It's only a counter…"
👨👨‍🦱👴 _"Shh!!!!"_

It's very simple and efficient, does not use any dispatch locks, and does not cause any Task queue congestion.

```
    let maxConcurrentOperations = Semalot(tickets: 3)

    try await withThrowingTaskGroup { group in
        for request in lotsOfRequests {
            await maximumOperations.takeTicket()
            group.addTask {
                let data = try await urlSession.data(for: request).0
                await doThings(with: data)
                maximumOperations.returnTicket()
            }
        }
    }
```

## Topics

### Creating a counter
- ``Semalot/Semalot/init(tickets:)``

### Taking and returning tickets
- ``Semalot/Semalot/takeTicket()``
- ``Semalot/Semalot/returnTicket()``
