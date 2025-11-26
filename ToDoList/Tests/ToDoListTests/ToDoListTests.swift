//
//  ToDoListTests.swift
//  ToDoListTests
//
//  Created by Славка Корн on 18.11.2025.
//


import XCTest
import CoreData
@testable import ToDoList

// MARK: - InMemoryCoreDataStack для тестов
class InMemoryCoreDataStack {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ToDoList")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
}

// MARK: - Вспомогательные методы для создания тестовых объектов
extension InMemoryCoreDataStack {
    func createTestTodo(title: String = "Test Todo", completed: Bool = false) -> CDTodo {
        let todo = CDTodo(context: viewContext)
        todo.id = Int64.random(in: 1...1000)
        todo.title = title
        todo.createdAt = Date()
        todo.completed = completed
        todo.userId = 1
        return todo
    }
    
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}


// MARK: - Mock Repository
class MockTodosRepository: TodosRepositoryProtocol {
    var loadTodosFromStoreCalled = false
    var loadTodosResult: [CDTodo] = []
    
    var importTodosIfNeededCalled = false
    var importTodosResult: Result<[CDTodo], Error> = .success([])
    
    var createTodoCalled = false
    var createdTitle: String?
    var createdDetails: String?
    var createTodoResult: CDTodo?
    
    var updateTodoCalled = false
    var updatedTodo: CDTodo?
    var updateTodoResult = true
    
    var deleteTodoCalled = false
    var deletedTodo: CDTodo?
    var deleteTodoResult = true
    
    var searchTodosCalled = false
    var searchQuery: String?
    var searchResult: [CDTodo] = []
    
    func loadTodosFromStore(completion: @escaping ([CDTodo]) -> Void) {
        loadTodosFromStoreCalled = true
        completion(loadTodosResult)
    }
    
    func importTodosIfNeeded(completion: @escaping (Result<[CDTodo], Error>) -> Void) {
        importTodosIfNeededCalled = true
        completion(importTodosResult)
    }
    
    func createTodo(title: String, details: String?, userId: Int64?, completion: @escaping (CDTodo?) -> Void) {
        createTodoCalled = true
        createdTitle = title
        createdDetails = details
        completion(createTodoResult)
    }
    
    func updateTodo(_ todo: CDTodo, title: String, details: String?, completed: Bool, completion: @escaping (Bool) -> Void) {
        updateTodoCalled = true
        updatedTodo = todo
        completion(updateTodoResult)
    }
    
    func deleteTodo(_ todo: CDTodo, completion: @escaping (Bool) -> Void) {
        deleteTodoCalled = true
        deletedTodo = todo
        completion(deleteTodoResult)
    }
    
    func searchTodos(query: String, completion: @escaping ([CDTodo]) -> Void) {
        searchTodosCalled = true
        searchQuery = query
        completion(searchResult)
    }
}


// MARK: - Основные тесты Interactor
class TodosInteractorTests: XCTestCase {
    var sut: TodosInteractor!
    var mockRepository: MockTodosRepository!
    var mockPresenter: MockTodosInteractorOutput!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockTodosRepository()
        mockPresenter = MockTodosInteractorOutput()
        sut = TodosInteractor(repository: mockRepository)
        sut.presenter = mockPresenter
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockPresenter = nil
        super.tearDown()
    }
    
    func testLoadTodos() {
        // Given
        let coreDataStack = InMemoryCoreDataStack()
        let testTodo = coreDataStack.createTestTodo()
        coreDataStack.saveContext()
        
        mockRepository.loadTodosResult = [testTodo]
        
        // When
        sut.loadTodos()
        
        // Then
        XCTAssertTrue(mockRepository.loadTodosFromStoreCalled)
        XCTAssertTrue(mockPresenter.didLoadTodosCalled)
        XCTAssertEqual(mockPresenter.receivedTodos?.count, 1)
    }
    
    func testCreateTodo() {
        // Given
        let title = "Test Todo"
        let details = "Test Details"
        
        // When
        sut.createTodo(title: title, details: details)
        
        // Then
        XCTAssertTrue(mockRepository.createTodoCalled)
        XCTAssertEqual(mockRepository.createdTitle, title)
        XCTAssertEqual(mockRepository.createdDetails, details)
    }
    
    func testDeleteTodo() {
        // Given
        let coreDataStack = InMemoryCoreDataStack()
        let testTodo = coreDataStack.createTestTodo()
        
        // When
        sut.deleteTodo(testTodo)
        
        // Then
        XCTAssertTrue(mockRepository.deleteTodoCalled)
        XCTAssertEqual(mockRepository.deletedTodo, testTodo)
    }
}

class MockTodosInteractorOutput: TodosInteractorOutput {
    var didLoadTodosCalled = false
    var receivedTodos: [CDTodo]?
    
    var didFailImportCalled = false
    var receivedError: Error?
    
    func didLoadTodos(_ todos: [CDTodo]) {
        didLoadTodosCalled = true
        receivedTodos = todos
    }
    
    func didFailImport(error: Error) {
        didFailImportCalled = true
        receivedError = error
    }
}


// MARK: - Основные тесты Presenter
class TodosPresenterTests: XCTestCase {
    var sut: TodosPresenter!
    var mockInteractor: MockTodosInteractor!
    var mockRouter: MockTodosRouter!
    var mockView: MockTodosView!
    
    override func setUp() {
        super.setUp()
        mockInteractor = MockTodosInteractor()
        mockRouter = MockTodosRouter()
        mockView = MockTodosView()
        sut = TodosPresenter(interactor: mockInteractor, router: mockRouter)
        sut.view = mockView
    }
    
    override func tearDown() {
        sut = nil
        mockInteractor = nil
        mockRouter = nil
        mockView = nil
        super.tearDown()
    }
    
    func testViewDidLoad() {
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertTrue(mockInteractor.importIfNeededCalled)
        XCTAssertTrue(mockInteractor.loadTodosCalled)
    }
    
    func testDidTapAdd() {
        // When
        sut.didTapAdd()
        
        // Then
        XCTAssertTrue(mockRouter.showDetailForNilCalled)
    }
    
    func testDidRequestDelete() {
        // Given
        let coreDataStack = InMemoryCoreDataStack()
        let testTodo = coreDataStack.createTestTodo()
        
        // When
        sut.didRequestDelete(todo: testTodo)
        
        // Then
        XCTAssertTrue(mockInteractor.deleteTodoCalled)
        XCTAssertEqual(mockInteractor.deletedTodo, testTodo)
    }
}

class MockTodosInteractor: TodosInteractorProtocol {
    var loadTodosCalled = false
    var importIfNeededCalled = false
    var createTodoCalled = false
    var createdTitle: String?
    var createdDetails: String?
    var deleteTodoCalled = false
    var deletedTodo: CDTodo?
    var searchCalled = false
    var searchQuery: String?
    var updateTodoCompletionCalled = false
    var updatedTodo: CDTodo?
    var updatedCompleted: Bool = false
    
    // Эти методы не будем тестировать в базовых тестах
    func updateTodo(_ todo: CDTodo, title: String, details: String?, completed: Bool) {}
    
    func loadTodos() { loadTodosCalled = true }
    func importIfNeeded() { importIfNeededCalled = true }
    
    func createTodo(title: String, details: String?) {
        createTodoCalled = true
        createdTitle = title
        createdDetails = details
    }
    
    func deleteTodo(_ todo: CDTodo) {
        deleteTodoCalled = true
        deletedTodo = todo
    }
    
    func search(query: String) {
        searchCalled = true
        searchQuery = query
    }
    
    func updateTodoCompletion(todo: CDTodo, completed: Bool) {
        updateTodoCompletionCalled = true
        updatedTodo = todo
        updatedCompleted = completed
    }
}

class MockTodosRouter: TodosRouterProtocol {
    var startCalled = false
    var showDetailForTodoCalled = false
    var showDetailForNilCalled = false
    var receivedTodo: CDTodo?
    
    func start() { startCalled = true }
    
    func showDetail(for todo: CDTodo?) {
        if let todo = todo {
            showDetailForTodoCalled = true
            receivedTodo = todo
        } else {
            showDetailForNilCalled = true
        }
    }
}

class MockTodosView: TodosViewProtocol {
    var showTodosCalled = false
    var receivedTodos: [CDTodo]?
    var showErrorCalled = false
    var receivedErrorMessage: String?
    
    func showTodos(_ todos: [CDTodo]) {
        showTodosCalled = true
        receivedTodos = todos
    }
    
    func showError(_ message: String) {
        showErrorCalled = true
        receivedErrorMessage = message
    }
}
