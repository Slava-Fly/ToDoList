//
//  TodoDetailRouter.swift
//  ToDoList
//
//  Created by Славка Корн on 20.11.2025.
//

import UIKit

final class TodoDetailRouter {
    private let navigationController: UINavigationController
    private let repository: TodosRepositoryProtocol
    
    init(navigationController: UINavigationController, repository: TodosRepositoryProtocol) {
        self.navigationController = navigationController
        self.repository = repository
    }
    
    func start(with todo: CDTodo?) {
        let interactor = TodoDetailInteractor(repository: repository)
        let presenter = TodoDetailPresenter(interactor: interactor)
        let vc = TodoDetailViewController(presenter: presenter, editingTodo: todo)
        
        presenter.view = vc
        presenter.router = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func dismiss() {
        navigationController.popViewController(animated: true)
    }
}
