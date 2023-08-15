<img src="https://ptsochantaris.github.io/trailer/SemalotLogo.webp" alt="Logo" width=256 align="right">

# Semalot

👨 "Semalot!" 👨‍🦱 "Semalot!!" 👴 "Semalot!!!" 🤦‍♀️ "It's only a counter…" 👨👨‍🦱👴 _"Shh!!!!"_

An elementary counting semaphore for async tasks in Swift, which I use a lot in my code so I thought I should turn it into a package!

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fptsochantaris%2Fkey-vine%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ptsochantaris/key-vine) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fptsochantaris%2Fkey-vine%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ptsochantaris/key-vine)

Currently used in
- [Trailer](https://github.com/ptsochantaris/trailer)
- [Trailer-CLI](https://github.com/ptsochantaris/trailer-cli)
- [Gladys](https://github.com/ptsochantaris/gladys)

Detailed docs [can be found here](https://swiftpackageindex.com/ptsochantaris/semalot/documentation)

## Overview

Does what it says on the tin. It's simple and efficient, does not use any dispatch locks, and does not cause any Task queue congestion.

```
let maxConcurrentOperations = Semalot(tickets: 3)

try await withThrowingTaskGroup { group in
    for request in lotsOfRequests {
        await maxConcurrentOperations.takeTicket()
        group.addTask {
            let data = try await urlSession.data(for: request).0
            await doThings(with: data)
            maxConcurrentOperations.returnTicket()
        }
    }
}
```


## License
Copyright (c) 2023 Paul Tsochantaris. Licensed under the MIT License, see LICENSE for details.
