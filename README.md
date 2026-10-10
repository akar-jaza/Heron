<p align="center">
<img width="500" height="500" alt="Minimalist Blue Heron App Icon" src="https://github.com/user-attachments/assets/b6216dd6-cead-4e5c-b0f2-cfb1899131a4" />
</p>

# Heron

A command-line tool that checks links and tells you which ones are broken.

Give it a list of URLs, and it reports which links work and which ones don't, and why.

> 🚧 **Work in progress.** This is a learning project. I'm building it step by step to get better at Swift, especially **Swift Concurrency**.

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

- [x] Check one link with `URLSession` and `async/await`
- [x] Return a result enum instead of printing
- [x] Check several links one by one in a loop
- [⏳] Check links at the same time with `TaskGroup`
- [ ] Limit how many checks run at once
- [ ] Use an `actor` to skip links that were already checked
- [ ] Add timeouts and clean cancellation (Ctrl+C)
- [ ] Read links from a file
- [ ] Add a real command-line interface with Swift Argument Parser

## Requirements

- macOS
- Xcode with Swift 5.9 or later (the goal is to move to Swift 6 language mode)

## Running it

1. Clone the repo
2. Open the project in Xcode
3. Press **Run** (⌘R)



## License

MIT
