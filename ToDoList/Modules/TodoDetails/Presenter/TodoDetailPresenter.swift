//
//  TodoDetailPresenter.swift
//  ToDoList
//
//  Created by Славка Корн on 20.11.2025.
//

import Foundation

protocol TodoDetailView: AnyObject {
    func dismiss()
}

final class TodoDetailPresenter {
    private let interactor: TodoDetailInteractorProtocol
    
    var router: TodoDetailRouter?
    
    weak var view: TodoDetailView?
    
    init(interactor: TodoDetailInteractorProtocol) {
        self.interactor = interactor
    }
    
    func save(original: CDTodo?, title: String, details: String?, completed: Bool) {
        interactor.saveTodo(original: original, title: title, details: details, completed: completed) { [weak self] success in
            self?.view?.dismiss()
        }
    }
}

