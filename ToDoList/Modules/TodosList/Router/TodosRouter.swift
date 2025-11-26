//
//  TodosRouter.swift
//  ToDoList
//
//  Created by Славка Корн on 18.11.2025.
//

import UIKit

protocol TodosRouterProtocol {
    func start()
    func showDetail(for todo: CDTodo?)
}

final class TodosRouter: TodosRouterProtocol {
    private let navigationController: UINavigationController
    private let coreDataStack: CoreDataStack
    
    init(navigationController: UINavigationController, coreDataStack: CoreDataStack) {
        self.navigationController = navigationController
        self.coreDataStack = coreDataStack
    }
    
    func start() {
        let repository = TodosRepository(coreDataStack: coreDataStack)
        let interactor = TodosInteractor(repository: repository)
        let presenter = TodosPresenter(interactor: interactor, router: self)
        let vc = TodosViewController(presenter: presenter)
        
        presenter.view = vc
        interactor.presenter = presenter
        navigationController.viewControllers = [vc]
        
    }
    
    func showDetail(for todo: CDTodo?) {
        let repository = TodosRepository(coreDataStack: coreDataStack)
        let detailRouter = TodoDetailRouter(navigationController: navigationController, repository: repository) 
        detailRouter.start(with: todo)
    }
}
