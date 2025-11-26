//
//  TodosPresenter.swift
//  ToDoList
//
//  Created by Славка Корн on 18.11.2025.
//

import Foundation
import UIKit
import CoreData

protocol TodosViewProtocol: AnyObject {
    func showTodos(_ todos: [CDTodo])
    func showError(_ message: String)
}

final class TodosPresenter {
    private let interactor: TodosInteractorProtocol
    private let router: TodosRouterProtocol
    
    weak var view: TodosViewProtocol?
    weak var viewController: UIViewController?
    
    init(interactor: TodosInteractorProtocol, router: TodosRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }
    
    func viewDidLoad() {
        interactor.importIfNeeded()
        interactor.loadTodos()
    }
    
    func didTapAdd() {
        router.showDetail(for: nil)
    }
    
    func didSelect(todo: CDTodo) {
        router.showDetail(for: todo)
    }
    
    func didRequestDelete(todo: CDTodo) {
        interactor.deleteTodo(todo)
    }
    
    func search(query: String) {
        interactor.search(query: query)
    }
    
    func didTapShare(_ todo: CDTodo) {
        let text = "Задача: \(String(describing: todo.title))\(todo.details.map { "\n\($0)" } ?? "")"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        viewController?.present(activityVC, animated: true)
    }
    
    func toggleCompleted(todo: CDTodo) {
        let newValue = !todo.completed
        todo.completed = newValue

        interactor.updateTodoCompletion(todo: todo, completed: newValue)
    }
}

extension TodosPresenter: TodosInteractorOutput {
    func didLoadTodos(_ todos: [CDTodo]) {
        view?.showTodos(todos)
    }
    
    func didFailImport(error: any Error) {
        view?.showError("Import error: \(error.localizedDescription)")
    }
}

