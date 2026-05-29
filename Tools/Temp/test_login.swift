import Foundation

func testLogin() async {
    let url = URL(string: "http://10.211.55.4:30080/api/v1/auth/login")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Simulate Basic Auth to see if that's what the backend expects
    let loginString = "admin:password"
    let loginData = loginString.data(using: .utf8)!
    let base64LoginString = loginData.base64EncodedString()
    request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("Status code: \(httpResponse.statusCode)")
            if let headers = httpResponse.allHeaderFields as? [String: String] {
                for (k, v) in headers {
                    print("\(k): \(v)")
                }
            }
            if let str = String(data: data, encoding: .utf8) {
                print("Body: \(str)")
            }
        }
    } catch {
        print("Error: \(error)")
    }
}

let semaphore = DispatchSemaphore(value: 0)
Task {
    await testLogin()
    semaphore.signal()
}
semaphore.wait()
