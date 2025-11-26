//
//  TodosAPIClient.swift
//  ToDoList
//
//  Created by Славка Корн on 18.11.2025.
//

import Foundation

final class TodosAPIClient {
    static let shared = TodosAPIClient()
    private let baseURL = URL(string: "https://dummyjson.com")!
    
    func fetchTodos(completion: @escaping (Result<[TodoDTO], Error>) -> Void) {
        let url = baseURL.appendingPathComponent("/todos")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(TodosResponse.self, from: data)
                completion(.success(response.todos))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
