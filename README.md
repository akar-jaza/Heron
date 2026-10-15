<p align="center">
<img width="700" height="205" alt="heron" src="https://github.com/user-attachments/assets/da89ec55-fb2d-4e72-9daa-657318af668e" />
</p>

# Heron

Heron is a command-line URL checker built with Swift. It checks multiple links concurrently and reports HTTP status codes and connection errors.
Built as a practical exploration of Swift Concurrency, including async/await, task groups, actors, and asynchronous streams.y**.

## What it will do

```
✅ https://apple.com            (200)
❌ https://apple.com/nothing    (404)
❌ https://appleeee.com         (could not find server)
```

## Why I'm building this

Checking links is slow, because every link needs a network request. Checking them one by one takes forever, so the tool checks many at the same time. That makes it a good way to practice:

- `async` / `await`
- `TaskGroup` (running many tasks at once, with a limit)
- `actor` (safely sharing data between tasks)
- Timeouts and cancellation
- `AsyncStream` (live progress updates)
- Modeling results with enums

## Roadmap

- [x] Read links from a file
- [x] Add a real command-line interface with Swift Argument Parser
- [ ] Package and simplify installation
- [ ] Publish a versioned release for easier distribution
- [ ] Continue improving error handling and usability

## Requirements

- macOS
- Xcode with Swift 5.9 or later (the goal is to move to Swift 6 language mode)

## Running it

### Option 1: Terminal

1. Clone the repository.
2. Open Terminal in the project directory.
3. Compile and run Heron:

   ```bash
   swiftc main.swift Banner.swift Menu.swift -o heron
   ./heron

**Small note:** If you wanna use Terminal, make sure you're in the folder with the 3 Swift files. If you wanna use Xcode, make sure there's an Xcode project to open!

### Option 2: Terminal

1. Clone the repository.
2. Open the project in Xcode.
3. Press Run (⌘R).

## License

MIT
