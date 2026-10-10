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

struct URLChecker{
    
    func makeRequestWithoutTaskGroup(with urlString: String) async -> NetworkResult {
        
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
    
    
    func checkingWithTaskGroup(urls: [String]) async -> [(String, NetworkResult)] {
        await withTaskGroup(of: (String, NetworkResult).self) { group in
            
            for urlString in urls {
                group.addTask {
                    let result = await self.makeRequestWithoutTaskGroup(with: urlString)
                    return (urlString, result)
                }
            }
            
            var results: [(String, NetworkResult)] = []
            
            for await item in group {
                results.append(item)
            }
            
            return results
            
        }
    }
}


func runUrlCheckerWithoutTaskGroup() async {
    let checker = URLChecker()
    let start = Date()
    
    for urlString in urls {
        
        let requests = await checker.makeRequestWithoutTaskGroup(with: urlString)
        
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
    
    print("Took \(Date().timeIntervalSince(start)) seconds")
}

//await runUrlCheckerWithoutTaskGroup()

func runUrlCheckerWithTaskGroup() async {
    let checker = URLChecker()
    let start = Date()
    
    let results = await checker.checkingWithTaskGroup(urls: urls)
    
    for (urlString, result) in results {
        switch result {
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
    
    print("Took \(Date().timeIntervalSince(start)) seconds")
    
}

await runUrlCheckerWithTaskGroup()
