//
//  TodoDetailViewController.swift
//  ToDoList
//
//  Created by Славка Корн on 20.11.2025.
//

import UIKit
import SnapKit
import CoreData

final class TodoDetailViewController: UIViewController, TodoDetailView {
    // MARK: - Properties
    private let presenter: TodoDetailPresenter
    private let editingTodo: CDTodo?
    private let titlePlaceholder = "Название задачи"
    private let detailsPlaceholder = "Описание (необязательно)"
    
    private var hasSaved = false

    // MARK: - UI Components
    private let largeTitleEditor: UITextView = {
        let view = UITextView()
        view.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        view.textColor = .white
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        return view
    }()

    private let detailsField: UITextView = {
        let view = UITextView()
        view.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        view.textColor = .white
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .lightGray
        return label
    }()
    
    // MARK: - Init
    init(presenter: TodoDetailPresenter, editingTodo: CDTodo?) {
        self.presenter = presenter
        self.editingTodo = editingTodo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNav()
        populateIfNeeded()
        setupTextDelegates()
        setupKeyboardHandling()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (isMovingFromParent || isBeingDismissed) && !hasSaved {
            saveChanges()
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(largeTitleEditor)
        view.addSubview(detailsField)
        view.addSubview(dateLabel)

        largeTitleEditor.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(largeTitleEditor.snp.bottom).offset(4)
            make.leading.trailing.equalTo(largeTitleEditor)
            make.height.equalTo(16)
        }

        detailsField.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(16)
            make.leading.trailing.equalTo(largeTitleEditor)
            make.bottom.equalToSuperview().inset(16)
        }
    }
    
    private func setupNav() {
        var configure = UIButton.Configuration.plain()
        let boldConfiguration = UIImage.SymbolConfiguration(weight: .medium)
        configure.image = UIImage(systemName: "chevron.left", withConfiguration: boldConfiguration)
        configure.title = "Назад"
        configure.imagePadding = 6
        configure.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -8, bottom: 0, trailing: 0)
        
        let backButton = UIButton(configuration: configure)
        backButton.tintColor = .yellow
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    private func setupTextDelegates() {
        largeTitleEditor.delegate = self
        detailsField.delegate = self
    }

    @objc private func backTapped() {
        if !hasSaved {
            saveChanges()
        }
        
        dismiss()
    }

    // MARK: - Business Logic
    private func saveChanges() {
        // сохранение началось
        hasSaved = true
        
        var titleToSave = largeTitleEditor.text ?? ""
        var detailsToSave = detailsField.text

        if titleToSave == titlePlaceholder {
            titleToSave = ""
        }
        
        if detailsToSave == detailsPlaceholder {
            detailsToSave = nil
        }
        
        let trimmedTitle = titleToSave.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = detailsToSave?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Проверяем что заголовок не пустой и не равен плейсхолдеру
        guard !trimmedTitle.isEmpty else {
            hasSaved = false // Разрешаем повторное сохранение
            return
        }
        
        if let todo = editingTodo {
            if trimmedTitle != todo.title || trimmedDetails != todo.details {
                presenter.save(
                    original: editingTodo,
                    title: trimmedTitle,
                    details: trimmedDetails?.isEmpty == true ? nil : trimmedDetails,
                    completed: todo.completed
                )
                NotificationCenter.default.post(name: NSNotification.Name("TodoDataChanged"), object: nil)
            }
        } else {
            presenter.save(
                original: nil,
                title: trimmedTitle,
                details: trimmedDetails?.isEmpty == true ? nil : trimmedDetails,
                completed: false
            )
            NotificationCenter.default.post(name: NSNotification.Name("TodoDataChanged"), object: nil)
        }
    }
    
    private func populateIfNeeded() {
        if let todo = editingTodo, let created = todo.createdAt {
            largeTitleEditor.text = todo.title
            largeTitleEditor.textColor = .white
            dateLabel.text = DateFormatter.shortDate.string(from: created)

            // Если details нет, показываем текст ячейки как плейсхолдер
            if let details = todo.details, !details.isEmpty {
                detailsField.text = details
                detailsField.textColor = .white
            } else {
                detailsField.text = "Найти время для расслабления перед сном: посмотреть фильм или послушать музыку"
                detailsField.textColor = .white
            }

        } else {
            // Новая задача - стандартные плейсхолдеры
            largeTitleEditor.text = titlePlaceholder
            largeTitleEditor.textColor = .lightGray
            detailsField.text = detailsPlaceholder
            detailsField.textColor = .lightGray
        }
    }

    // MARK: - Keyboard Handling
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let height = keyboardFrame.height + 10

        UIView.animate(withDuration: duration) {
            self.detailsField.contentInset.bottom = height
            self.detailsField.verticalScrollIndicatorInsets.bottom = height
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        UIView.animate(withDuration: duration) {
            self.detailsField.contentInset.bottom = 0
            self.detailsField.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    @objc private func endEditing() {
        view.endEditing(true)
    }

    func dismiss() {
        navigationController?.popViewController(animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextViewDelegate
extension TodoDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Убираем плейсхолдер когда пользователь начинает печатать
        if textView == largeTitleEditor {
            if textView.text == titlePlaceholder && textView.textColor == .lightGray {
                // Пользователь начал печатать - убираем плейсхолдер
                textView.text = ""
                textView.textColor = .white
            }
        } else if textView == detailsField {
            if textView.text == detailsPlaceholder && textView.textColor == .lightGray {
                // Пользователь начал печатать - убираем плейсхолдер
                textView.text = ""
                textView.textColor = .white
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // Возвращаем плейсхолдер если поле пустое
        if textView == largeTitleEditor {
            if textView.text.isEmpty {
                textView.text = titlePlaceholder
                textView.textColor = .lightGray
            }
        } else if textView == detailsField {
            if textView.text.isEmpty {
                textView.text = detailsPlaceholder
                textView.textColor = .lightGray
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == largeTitleEditor && textView.text == titlePlaceholder {
            textView.text = ""
            textView.textColor = .white
        } else if textView == detailsField && textView.text == detailsPlaceholder {
            textView.text = ""
            textView.textColor = .white
        }
    }
}
