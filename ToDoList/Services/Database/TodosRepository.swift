//
//  TodosRepository.swift
//  ToDoList
//
//  Created by Славка Корн on 18.11.2025.
//

import Foundation
import CoreData

protocol TodosRepositoryProtocol {
    func loadTodosFromStore(completion: @escaping ([CDTodo]) -> Void)
    func importTodosIfNeeded(completion: @escaping (Result<[CDTodo], Error>) -> Void)
    func createTodo(title: String, details: String?, userId: Int64?, completion: @escaping (CDTodo?) -> Void)
    func updateTodo(_ todo: CDTodo, title: String, details: String?, completed: Bool, completion: @escaping (Bool) -> Void)
    func deleteTodo(_ todo: CDTodo, completion: @escaping (Bool) -> Void)
    func searchTodos(query: String, completion: @escaping ([CDTodo]) -> Void)
}

final class TodosRepository: TodosRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let userDefaultsKey = "didImportRemoteTodos"
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - LoadFromStore
    func loadTodosFromStore(completion: @escaping ([CDTodo]) -> Void) {
        let context = self.coreDataStack.viewContext
        context.perform {
            let request: NSFetchRequest<CDTodo> = CDTodo.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            do {
                let items = try context.fetch(request)
                completion(items)
            } catch {
                print("Fetch error: \(error)")
                completion([])
            }
        }
    }
    
    // MARK: - Update importIfNeeded
    func importTodosIfNeeded(completion: @escaping (Result<[CDTodo], Error>) -> Void) {
        let didImport = UserDefaults.standard.bool(forKey: userDefaultsKey)
        guard !didImport else {

            let context = coreDataStack.viewContext
            context.perform {
                let request: NSFetchRequest<CDTodo> = CDTodo.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                do {
                    let todos = try context.fetch(request)
                    DispatchQueue.main.async {
                        completion(.success(todos))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            return
        }
        
        TodosAPIClient.shared.fetchTodos { result in
            switch result {
            case .success(let dtos):
                let backgroundContext = self.coreDataStack.newBackgroundContext()
                backgroundContext.perform {
                    for dto in dtos {
                        let cDTodo = CDTodo(context: backgroundContext)
                        cDTodo.id = Int64(dto.id)
                        cDTodo.title = dto.todo
                        cDTodo.details = nil
                        cDTodo.createdAt = Date()
                        cDTodo.completed = dto.completed
                        cDTodo.userId = Int64(dto.userId)
                    }
                    do {
                        try backgroundContext.save()
                        UserDefaults.standard.set(true, forKey: self.userDefaultsKey)
                        
                        // Fetch из main context после сохранения
                        let context = self.coreDataStack.viewContext
                        context.perform {
                            let request: NSFetchRequest<CDTodo> = CDTodo.fetchRequest()
                            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                            do {
                                let todos = try context.fetch(request)
                                DispatchQueue.main.async {
                                    completion(.success(todos))
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    completion(.failure(error))
                                }
                            }
                        }
                        
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Create
    func createTodo(title: String, details: String?, userId: Int64? = nil, completion: @escaping (CDTodo?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let context = self.coreDataStack.newBackgroundContext()
            var createdObjectID: NSManagedObjectID?
            
            context.performAndWait {
                let cDTodo = CDTodo(context: context)
                cDTodo.id = Int64.random(in: 1000...Int64.max)
                cDTodo.title = title
                cDTodo.details = details
                cDTodo.createdAt = Date()
                cDTodo.completed = false
                cDTodo.userId = userId ?? 0
                
                do {
                    try context.save()
                    createdObjectID = cDTodo.objectID
                    
                    DispatchQueue.main.async {
                        self.coreDataStack.viewContext.refreshAllObjects()
                    }
                } catch {
                    print("Create save error: \(error)")
                    
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
            }
            
            DispatchQueue.main.async {
                if let objectID = createdObjectID,
                let mainTodo = try? self.coreDataStack.viewContext.existingObject(with: objectID) as? CDTodo {
                    completion(mainTodo)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Update
    func updateTodo(_ todo: CDTodo, title: String, details: String?, completed: Bool, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let context = self.coreDataStack.newBackgroundContext()
            var success = false
            
            context.performAndWait {
                do {
                    guard let object = try context.existingObject(with: todo.objectID) as? CDTodo else {
                        return
                    }
                    
                    object.title = title
                    object.details = details
                    object.completed = completed
                    
                    try context.save()
                    success = true
                    
                    DispatchQueue.main.async {
                        self.coreDataStack.viewContext.refreshAllObjects()
                    }
                } catch {
                    print("Update error: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    // MARK: - Delete
    func deleteTodo(_ todo: CDTodo, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let context = self.coreDataStack.newBackgroundContext()
            var success = false
            
            context.performAndWait {
                do {
                    guard let object = try context.existingObject(with: todo.objectID) as? CDTodo else {
                        return
                    }
                    context.delete(object)
                    try context.save()
                    success = true
               
                    DispatchQueue.main.async {
                        self.coreDataStack.viewContext.refreshAllObjects()
                    }
                } catch {
                    print("Delete error: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    // MARK: - Search
    func searchTodos(query: String, completion: @escaping ([CDTodo]) -> Void) {
        let context = self.coreDataStack.newBackgroundContext()
        var objectIDs: [NSManagedObjectID] = []
        
        context.performAndWait {
            let request: NSFetchRequest<CDTodo> = CDTodo.fetchRequest()
            
            if !query.isEmpty {
                request.predicate = NSPredicate(
                    format: "title CONTAINS[cd] %@ OR details CONTAINS[cd] %@",
                    query, query
                )
            }
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            do {
                let items = try context.fetch(request)
                objectIDs = items.map { $0.objectID}
            } catch {
                print("Search error: \(error)")
            }
        }
        
        // Конвертируем objectIDs в объекты главного контекста
        DispatchQueue.main.async {
            let mainContext = self.coreDataStack.viewContext
            let mainThreadItems = objectIDs.compactMap {
                try? mainContext.existingObject(with: $0) as? CDTodo
            }
            completion(mainThreadItems)
        }
    }
}

