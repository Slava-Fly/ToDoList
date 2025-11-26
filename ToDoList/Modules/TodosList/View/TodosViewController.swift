//
//  TodosViewController.swift
//  ToDoList
//
//  Created by Славка Корн on 18.11.2025.
//

import UIKit
import SnapKit
import CoreData

final class TodosViewController: UIViewController, TodoCellDelegate {
    // MARK: - Properties
    private let presenter: TodosPresenter
    
    private var todos: [CDTodo] = []
    private var bottomBarHeight: CGFloat = 49
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TodoCell.self, forCellReuseIdentifier: "TodoCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return tableView
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.barTintColor = .black
        searchBar.tintColor = .white
        searchBar.searchTextField.backgroundColor = UIColor(white: 0.2, alpha: 1)
        searchBar.searchTextField.textColor = .white
        searchBar.searchTextField.layer.cornerRadius = 10
        searchBar.searchTextField.layer.masksToBounds = true
        
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        )
        
        if let microphoneImage = UIImage(systemName: "mic.fill") {
            searchBar.showsBookmarkButton = true
            let tintedMicrophoneImage = microphoneImage.withTintColor(.lightGray,renderingMode: .alwaysOriginal)
            searchBar.setImage(tintedMicrophoneImage, for: .bookmark, state: .normal)
        }
        
        if let searchImage = UIImage(systemName: "magnifyingglass") {
            let tintedSearchImage = searchImage.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            searchBar.setImage(tintedSearchImage, for: .search, state: .normal)
        }
        
        if let clearImage = UIImage(systemName: "xmark.circle.fill") {
            let tintedClearImage = clearImage.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            searchBar.setImage(tintedClearImage, for: .clear, state: .normal)
        }
        
        return searchBar
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Задачи"
        label.font = UIFont.boldSystemFont(ofSize: 34)
        label.textColor = .white
        return label
    }()
    
    private lazy var bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.2, alpha: 1) 
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var bottomBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.2, alpha: 1)
        return view
    }()
    
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.text = "0 Задач"
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private lazy var addBottomButton: UIButton = {
        let button = UIButton(type: .system)
        let configImage = UIImage(named: "edit.pencil")
        button.setImage(configImage, for: .normal)
        button.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    init(presenter: TodosPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        self.presenter.viewController = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        setupNavBar()
        setupSubviews()
        presenter.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataChange),
            name: NSNotification.Name("TodoDataChanged"),
            object: nil
        )
    }
    
    // MARK: - NavBar
    private func setupNavBar() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
    }
    
    @objc private func addTapped() {
        presenter.didTapAdd()
    }
    
    @objc private func handleDataChange() {
        presenter.viewDidLoad()
    }
    
    // MARK: - Layout
    private func setupSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(bottomBar)
        
        bottomBar.addSubview(countLabel)
        bottomBar.addSubview(addBottomButton)
        
        view.insertSubview(bottomBackground, belowSubview: bottomBar)
        
        bottomBackground.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(bottomBar.snp.bottom)
            make.bottom.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.equalToSuperview().inset(20)
        }
        
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(56)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }
        
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(bottomBarHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        countLabel.snp.makeConstraints { make in
            make.centerX.equalTo(bottomBar)
            make.centerY.equalTo(bottomBar).offset(6)
        }
        
        addBottomButton.snp.makeConstraints { make in
            make.centerY.equalTo(countLabel)
            make.trailing.equalTo(bottomBar).inset(16)
            make.width.equalTo(68)
            make.height.equalTo(44)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - TodosViewProtocol
extension TodosViewController: TodosViewProtocol {
    func showTodos(_ todos: [CDTodo]) {
        self.todos = todos
        tableView.reloadData()
        
        let count = todos.count
        let taskWord: String
        
        switch count % 10 {
        case 1 where count % 100 != 11:
            taskWord = "Задача"
        case 2...4 where !(12...14).contains(count % 100):
            taskWord = "Задачи"
        default:
            taskWord = "Задач"
        }
        
        countLabel.text = "\(count) \(taskWord)"
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension TodosViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as? TodoCell else {
            return UITableViewCell()
        }
        
        let todo = todos[indexPath.row]
        cell.configure(with: todo)
        cell.delegate = self
        return cell
    }
    
    func didTapCheckbox(for todo: CDTodo) {
        presenter.toggleCompleted(todo: todo)
        
        if let index = todos.firstIndex(of: todo) {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.didSelect(todo: todos[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let todo = todos[indexPath.row]
            presenter.didRequestDelete(todo: todo)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Удалить"
    }
    
    // Контекстное меню
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let todo = todos[indexPath.row]
        if let cell = tableView.cellForRow(at: indexPath) as? TodoCell {
            cell.contentView.backgroundColor = UIColor(white: 0.2, alpha: 1)
            cell.hideCheckbox()
        }
        
        return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { [weak self] _ in
            
            let edit = UIAction(title: "Редактировать", image: UIImage(named: "edit.context.menu")) { _ in
                self?.presenter.didSelect(todo: todo)
            }
            
            let share = UIAction(title: "Поделиться", image: UIImage(named: "export.context.menu")) { _ in
                self?.presenter.didTapShare(todo)
            }
            
            let delete = UIAction(title: "Удалить", image: UIImage(named: "trash.context.menu"), attributes: .destructive) { _ in
                self?.presenter.didRequestDelete(todo: todo)
            }
            
            return UIMenu(children: [edit, share, delete])
        }
    }
    
    func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        animator?.addCompletion {
            if let indexPath = configuration.identifier as? IndexPath {
                if let cell = tableView.cellForRow(at: indexPath) as? TodoCell {
                    cell.showCheckbox()
       
                    UIView.animate(withDuration: 0.5) {
                        cell.contentView.backgroundColor = .black
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.backgroundColor = .black
        
        if let todoCell = cell as? TodoCell {
            todoCell.showCheckbox()
        }
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willDisplayMenuFor configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionAnimating?
    ) {
        guard let cell = interaction.view as? TodoCell else { return }
        
        animator?.addAnimations {
            cell.animateCheckboxAppearance()
        }
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willEndFor configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionAnimating?
    ) {
        guard let cell = interaction.view as? TodoCell else { return }
        
        animator?.addAnimations {
            cell.animateCheckboxDisappearance()
        }
    }
}

// MARK: - UISearchBarDelegate
extension TodosViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter.search(query: searchText)
        
        if searchText.isEmpty {
            if let microphoneImage = UIImage(systemName: "mic.fill") {
                searchBar.showsBookmarkButton = true
                let tintedMicrophoneImage = microphoneImage.withTintColor(
                    .lightGray,
                    renderingMode: .alwaysOriginal
                )
                searchBar.setImage(tintedMicrophoneImage, for: .bookmark, state: .normal)
            }
        } else {
            searchBar.showsBookmarkButton = false
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        presenter.search(query: searchBar.text ?? "")
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if searchBar.text?.isEmpty == true {
            if let microphoneImage = UIImage(systemName: "mic.fill") {
                searchBar.showsBookmarkButton = true
                let tintedMicrophoneImage = microphoneImage.withTintColor(
                    .lightGray,
                    renderingMode: .alwaysOriginal
                )
                searchBar.setImage(tintedMicrophoneImage, for: .bookmark, state: .normal)
            }
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsBookmarkButton = false
    }
}

