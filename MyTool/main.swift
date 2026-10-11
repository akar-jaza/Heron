import Foundation

enum NetworkResult {
    case success
    case invalidURL
    case notHTTP
    case badStatus(code: Int)
    case failure(withError: Error)
}

let urls = [
    "https://jsonplaceholder.typicode.com/posts/1",
    "https://jsonplaceholder.typicode.com/users/1",
    "https://jsonplaceholder.typicode.com/todos/1",
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

struct URLChecker {
    
    func checkLink(with urlString: String) async -> NetworkResult {
        
        guard let url = URL(string: urlString) else {
            return NetworkResult.invalidURL
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return NetworkResult.notHTTP
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                return NetworkResult.success
            } else {
                return NetworkResult.badStatus(code: httpResponse.statusCode)
            }
        } catch {
            return NetworkResult.failure(withError: error)
        }
        
    }
    
    
    func checkAll(urls: [String]) async -> [(String, NetworkResult)] {
        let maxHelpers: Int =  2
        var results: [(String, NetworkResult)] = []
        
        await withTaskGroup(of: (String, NetworkResult).self) { group in
            var next: Int = 0
            
            while next < maxHelpers && next < urls.count {
                let url = urls[next]
                group
                    .addTask {
                        let result = await self.checkLink(
                            with: url
                        )
                        return (url, result)
                    }
                next += 1
            }
            
            for await requestResult in group {
                results.append(requestResult)
                if next < urls.count {
                    let url = urls[next]
                    group
                        .addTask {
                            let result = await self.checkLink(
                                with: url
                            )
                            return (url, result)
                        }
                    next += 1
                }
            }
        }
        return results
    }
}


fileprivate func printRequestResult(_ requests: NetworkResult, _ urlString: String) {
    switch requests {
    case .success:
        print("\(urlString) works ✅")
    case .failure(let error):
        print("❌ \(urlString): \(error.localizedDescription)")
    case .notHTTP:
        print("Not a valid HTTP \(urlString)")
    case .badStatus(let code):
        print("❌ bad status for \(urlString): \(code)")
    case .invalidURL:
        print("❌ \(urlString): Invalid URL")
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

//await runUrlCheckerWithoutTaskGroup()

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

