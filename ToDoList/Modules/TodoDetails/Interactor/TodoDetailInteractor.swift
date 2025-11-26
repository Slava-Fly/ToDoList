//
//  TodoDetailInteractor.swift
//  ToDoList
//
//  Created by Славка Корн on 20.11.2025.
//

import Foundation

protocol TodoDetailInteractorProtocol {
    func saveTodo(original: CDTodo?, title: String, details: String?, completed: Bool, completion: @escaping (Bool) -> Void)
}

final class TodoDetailInteractor: TodoDetailInteractorProtocol {
    private let repository: TodosRepositoryProtocol
    
    init(repository: TodosRepositoryProtocol) {
        self.repository = repository
    }
    
    func saveTodo(original: CDTodo?, title: String, details: String?, completed: Bool, completion: @escaping (Bool) -> Void) {
        if let original = original {
            repository.updateTodo(original, title: title, details: details, completed: completed) { success in
                completion(success)
            }
        } else {
            repository.createTodo(title: title, details: details, userId: nil) { todo in
                completion(todo != nil)
            }
        }
    }
}
