# Semalot

 👨 "Semalot!"
 👨‍🦱 "Semalot!!"
 👴 "Semalot!!!"
 🤦‍♀️ "It's only a counter…"
 👨👨‍🦱👴 _"Shh!!!!"_

An elementary counting semaphore for async tasks in Swift, which I use a lot in my code so I thought I should turn it into a package!

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

## Projects
For public projects, I've used Semalot in:
- [Trailer](https://github.com/ptsochantaris/trailer)
- [Trailer-CLI](https://github.com/ptsochantaris/trailer-cli)
- [Gladys](https://github.com/ptsochantaris/gladys)

### License
Copyright (c) 2023 Paul Tsochantaris. Licensed under the MIT License, see LICENSE for details.
