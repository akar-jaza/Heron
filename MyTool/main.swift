import Foundation
import Darwin

enum NetworkResult {
    case success
    case invalidURL
    case duplicateURL
    case notHTTP
    case timedOut
    case cancelled
    case badStatus(code: Int)
    case failure(withError: Error)
}

var urls: [String] = []

actor VisitedLinks {
    private var activeURLs: [String] = []
    private var seen: Set<String> = []
    
    func startChecking(_ url: String) {
        activeURLs.append(url)
    }
    
    func finishChecking(_ url: String) {
        activeURLs.removeAll { $0 == url }
    }
    
    func getActiveURLs() -> [String] {
        return activeURLs
    }
    
    func markIfNew(_ url: String) -> Bool {
        seen.insert(url).inserted
    }
}

struct URLChecker {
    
    func checkLink(with urlString: String) async -> NetworkResult {
        let timeout: TimeInterval = 3
                
        guard let url = URL(string: urlString) else {
            return NetworkResult.invalidURL
        }
        
        let urlRequest = URLRequest(url: url, timeoutInterval: timeout)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return NetworkResult.notHTTP
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                return NetworkResult.success
            } else {
                return NetworkResult.badStatus(code: httpResponse.statusCode)
            }
        } catch {
            if Task.isCancelled {
                return NetworkResult.cancelled
            }
            
            if let urlError = error as? URLError,
               urlError.code == .timedOut {
                return NetworkResult.timedOut
            }
            
            return NetworkResult.failure(withError: error)
        }
        
    }
    
    
    func checkAll(urls: [String], visited: VisitedLinks) async -> [(String, NetworkResult)] {
        let maxHelpers: Int =  2
        var results: [(String, NetworkResult)] = []
        
        await withTaskGroup(of: (String, NetworkResult).self) { group in
            var next: Int = 0
            
            while next < maxHelpers && next < urls.count {
                let url = urls[next]
                startCheck(&group, url, visited: visited)
                next += 1
            }
            
            for await requestResult in group {
                results.append(requestResult)
                if next < urls.count && !Task.isCancelled {
                    let url = urls[next]
                    startCheck(&group, url, visited: visited)
                    next += 1
                }
            }
        }
        return results
    }
    
    private func startCheck(
        _ group: inout TaskGroup<(String, NetworkResult)>,
        _ url: String,
        visited: VisitedLinks
    ) {
        
        group.addTask {
            let isNew = await visited.markIfNew(url)
            
            if !isNew {
                return (url, NetworkResult.duplicateURL)
            }
            await visited.startChecking(url)
            let result = await checkLink(with: url)
            await visited.finishChecking(url)
            
            return (url, result)
        }
    }
}


private func printRequestResult(
    _ result: NetworkResult,
    _ urlString: String
) {
    switch result {
        
    case .success:
        print("""
        
        ✅ REQUEST SUCCEEDED
        URL: \(urlString)
        """)
        
    case .failure(let error):
        
        print("""
        
        ❌ REQUEST FAILED
        URL: \(urlString)
        Reason: \(error.localizedDescription)
        """)
        
    case .notHTTP:
        print("""
        
        ❌ INVALID RESPONSE TYPE
        URL: \(urlString)
        Reason: The response is not an HTTP response.
        """)
        
    case .badStatus(let code):
        print("""
        
        ⚠️ HTTP ERROR
        URL: \(urlString)
        Status Code: \(code)
        """)
        
    case .invalidURL:
        print("""
        
        ❌ INVALID URL
        URL: \(urlString)
        Reason: The URL string is invalid.
        """)
        
    case .duplicateURL:
        print("""
        
        ⏭️ DUPLICATE URL SKIPPED
        URL: \(urlString)
        Reason: This URL has already been processed.
        """)
        
        
    case .timedOut:
        print("""
    
    ⏱️ REQUEST TIMED OUT
    URL: \(urlString)
    Reason: The request took too long to complete.
    """)
        
    case .cancelled:
        print("🛑 REQUEST STOPPED FOR: \(urlString)")
    }
    
    
}

func runOneByOne() async {
    let checker = URLChecker()
    let start = Date()
    
    for urlString in await urls {
        
        let result = await checker.checkLink(with: urlString)
        
        printRequestResult(result, urlString)
    }
    
    print("Took \(Date().timeIntervalSince(start)) seconds")
}


func runConcurrently(url: String) async {
    let checker = URLChecker()
//    let start = Date()
    let visited = VisitedLinks()
    
    let spinner = Task {
        let frames = ["|", "/", "-", "\\"]
        var index = 0
        
        while !Task.isCancelled {
            let activeURLs = await visited.getActiveURLs()
            let display = activeURLs.isEmpty
            ? "No active URLs"
            : activeURLs.joined(separator: " \u{1B}[36m|\u{1B}[32m ")
            
            print(
                "\r\u{1B}[33m\(frames[index])\u{1B}[0m " +
                "\u{1B}[36mChecking:\u{1B}[0m " +
                "\u{1B}[32m\(display)\u{1B}[0m\u{1B}[K",
                terminator: ""
            )
            fflush(stdout)
            
            index = (index + 1) % frames.count
            
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
    
    let results = await checker.checkAll(urls: urls, visited: visited)
    
    spinner.cancel()
    await spinner.value
    print("\r\u{1B}[2K", terminator: "")
        
    for (urlString, result) in results {
        printRequestResult(result, urlString)
//        try? await Task.sleep(for: .milliseconds(100))

    }
    
//    print("")
//    print("⏰ Took \(Date().timeIntervalSince(start)) seconds")
}

Banner.show()

func correctURL(_ url: String) -> String {
    if url.hasPrefix("https://") || url.hasPrefix("http://") {
        return url
    }
    
    return "https://" + url
}

let choice = Menu.choose("What do you want to do?", options: [
    "A  Write down a URL to check",
    "B  Read URLs from a file"
])

switch choice {
case 0:
    print("")
    Menu.prompt("Enter URL")
    let url = readLine()!
    
    let correctedURL = correctURL(url)
    
    urls.append(correctedURL)

    let mainTask = Task {
        await runConcurrently(url: urls.first ?? "")
    }
    
    signal(SIGINT, SIG_IGN)
    
    let listener = DispatchSource.makeSignalSource(
        signal: SIGINT,
        queue: .main
    )
    
    listener.setEventHandler {
        mainTask.cancel()
    }
    
    listener.resume()
    
    await mainTask.value
    
    urls.removeAll()
    
case 1:
    print("")
    Menu.prompt("Paste the File Path")
    
    if let path = readLine() {
        let cleanedPath = path
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\ ", with: " ")
        
        let filePath = (cleanedPath as NSString).expandingTildeInPath
        
        do {
            let contents = try String(
                contentsOfFile: filePath,
                encoding: .utf8
            )
            
            urls = contents
                .split(separator: ",")
                .map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .filter {
                    !$0.isEmpty
                }
            
            print("")
            print("\u{1B}[36mLoaded \(urls.count) URLs.\u{1B}[0m")
            print("-----")
                        
            
            await runConcurrently(url: urls.first ?? "")
            
        } catch {
            print("Couldn't read file: \(error.localizedDescription)")
        }
    }
default:
    break
}




