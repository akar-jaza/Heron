import Foundation

enum NetworkResult {
    case success
    case invalidURL
    case invalidResponse
    case failure(withError: Error)
}

let validURLString = "https://apple.com"
let invalidURLString = "https://appleeee.com"

func makeGetRequest(with urlString: String) async -> NetworkResult {
    
    guard let url = URL(string: urlString) else {
        return NetworkResult.invalidURL
    }

    do {
        let (_, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return NetworkResult.invalidResponse
        }
        
        return NetworkResult.success
    } catch {
        return NetworkResult.failure(withError: error)
    }
}

let request1 = await makeGetRequest(with: validURLString)
let request2 = await makeGetRequest(with: invalidURLString)

print(request1)
print(request2)


/**
 URLSession.shared.dataTask(with: url) {data, response, error in
 if let error = error {
 print("Error: \(error.localizedDescription)")
 return
 }
 
 guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
 print("Invalid Reponse")
 return
 }
 
 guard data != nil else {
 print("invalid data")
 return
 }
 }.resume()
 */

