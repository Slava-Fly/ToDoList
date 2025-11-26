//
//  TodosInteractor.swift
//  ToDoList
//
//  Created by Славка Корн on 18.11.2025.
//

import Foundation

protocol TodosInteractorProtocol {
    func loadTodos()
    func importIfNeeded()
    func createTodo(title: String, details: String?)
    func updateTodo(_ todo: CDTodo, title: String, details: String?, completed: Bool)
    func deleteTodo(_ todo: CDTodo)
    func search(query: String)
    func updateTodoCompletion(todo: CDTodo, completed: Bool)
}

final class TodosInteractor: TodosInteractorProtocol {
    private let repository: TodosRepositoryProtocol
    
    weak var presenter: TodosInteractorOutput?
    
    init(repository: TodosRepositoryProtocol) {
        self.repository = repository
    }
    
    func loadTodos() {
        repository.loadTodosFromStore { [weak self] items in
            self?.presenter?.didLoadTodos(items)
        }
    }
    
    func importIfNeeded() {
        repository.importTodosIfNeeded { [weak self] result in
            switch result {
            case .success:
                self?.loadTodos()
            case .failure(let error):
                self?.presenter?.didFailImport(error: error)
            }
        }
    }
    
    func createTodo(title: String, details: String?) {
        repository.createTodo(title: title, details: details, userId: nil) { [weak self] _ in
            self?.loadTodos()
        }
    }
    
    func updateTodo(_ todo: CDTodo, title: String, details: String?, completed: Bool) {
        repository.updateTodo(todo, title: title, details: details, completed: completed) { [weak self] _ in
            self?.loadTodos()
        }
    }
    
    func deleteTodo(_ todo: CDTodo) {
        repository.deleteTodo(todo) { [weak self] _ in
            self?.loadTodos()
        }
    }
    
    func search(query: String) {
        repository.searchTodos(query: query) { [weak self] items in
            self?.presenter?.didLoadTodos(items)
        }
    }
    
    func updateTodoCompletion(todo: CDTodo, completed: Bool) {
        repository.updateTodo(
            todo,
            title: todo.title ?? "",
            details: todo.details,
            completed: completed
        ) { [weak self] success in
            if success {
                self?.loadTodos() 
            }
        }
    }
}

protocol TodosInteractorOutput: AnyObject {
    func didLoadTodos(_ todos: [CDTodo])
    func didFailImport(error: Error)
}
