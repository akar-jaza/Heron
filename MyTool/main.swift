import Foundation

enum NetworkResult {
    case success
    case invalidURL
    case duplicateURL
    case notHTTP
    case timedOut
    case badStatus(code: Int)
    case failure(withError: Error)
}

let urls = [
    "https://jsonplaceholder.typicode.com/posts/1",
    "https://jsonplaceholder.typicode.com/users/1",
    "https://jsonplaceholder.typicode.com/todos/1",
    "https://httpbin.org/delay/10",
    "https://httpbin.org/get",
    "https://httpbin.org/get",
    "https://httpbin.org/get",
    "https://api.github.com/zen",
    "https://server12345.invalid",
    "https://missing-site98765.invalid",
    "https://fake-api54321.invalid",
    "https://no-server67890.invalid",
    "https://unknown-host24680.invalid",
    "https://httpbin.org/status/404",
    "file:///etc/hosts",
    "",
]

actor VisitedLinks {
    private var seen: Set<String> = []
    
    func markIfNew(_ link: String) -> Bool {
        seen.insert(link).inserted
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
            if let urlError = error as? URLError,
               urlError.code == .timedOut {
                return NetworkResult.timedOut
            }
            
            return NetworkResult.failure(withError: error)
        }
        
    }
    
    
    func checkAll(urls: [String]) async -> [(String, NetworkResult)] {
        let visited = VisitedLinks()
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
                if next < urls.count {
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
            
            let result = await checkLink(with: url)
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
    }
    
    
}

func runOneByOne() async {
    let checker = URLChecker()
    let start = Date()
    
    for urlString in urls {
        
        let result = await checker.checkLink(with: urlString)
        
        printRequestResult(result, urlString)
    }
    
    print("Took \(Date().timeIntervalSince(start)) seconds")
}


func runConcurrently() async {
    let checker = URLChecker()
    let start = Date()
    
    let results = await checker.checkAll(urls: urls)
    
    for (urlString, result) in results {
        printRequestResult(result, urlString)
    }
    
    print("Took \(Date().timeIntervalSince(start)) seconds")
    
}

await runConcurrently()

