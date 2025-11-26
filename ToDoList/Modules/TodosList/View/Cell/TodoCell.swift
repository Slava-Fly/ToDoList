//
//  TodoCell.swift
//  ToDoList
//
//  Created by Славка Корн on 24.11.2025.
//

import UIKit
import SnapKit

protocol TodoCellDelegate: AnyObject {
    func didTapCheckbox(for todo: CDTodo)
}

final class TodoCell: UITableViewCell {
    // MARK: - Properties
    private let checkbox = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let detailsLabel = UILabel()
    private let dateLabel = UILabel()
    
    private var todo: CDTodo?
    private var titleLeadingConstraint: Constraint?
    private var highlightAnimator: UIViewPropertyAnimator?
    
    weak var delegate: TodoCellDelegate?
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Configuration
    func configure(with todo: CDTodo) {
        self.todo = todo
        
        titleLabel.attributedText = nil
        titleLabel.textColor = .white
        titleLabel.text = ""
        
        titleLabel.text = todo.title
        detailsLabel.text = todo.details ?? "Найти время для расслабления перед сном: посмотреть фильм или послушать музыку"
        dateLabel.text = DateFormatter.shortDate.string(from: todo.createdAt ?? Date())
        
        updateCheckboxUI()
        updateTextStyle()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black
        
        checkbox.tintColor = .yellow
        checkbox.imageView?.contentMode = .scaleAspectFit
        checkbox.addTarget(self, action: #selector(didTapCheckbox), for: .touchUpInside)
        
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        detailsLabel.textColor = .white
        detailsLabel.numberOfLines = 2
        detailsLabel.font = .systemFont(ofSize: 12, weight: .regular)
        
        dateLabel.textColor = .lightGray
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        
        contentView.addSubview(checkbox)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailsLabel)
        contentView.addSubview(dateLabel)
        
        checkbox.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalTo(titleLabel)
            make.width.equalTo(24)
            make.height.equalTo(48)
        }
        
        titleLabel.snp.makeConstraints { make in
            titleLeadingConstraint = make.leading.equalTo(checkbox.snp.trailing).offset(8).constraint
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(12)
        }
        
        detailsLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(detailsLabel.snp.bottom).offset(6)
            make.bottom.equalToSuperview().inset(12)
        }
    }
    
    // MARK: - UI Updates
    private func updateCheckboxUI() {
        guard let todo = todo else { return }
        
        if todo.completed {
            let image = UIImage(named: "check.selected")
            checkbox.setImage(image, for: .normal)
        } else {
            let image = UIImage(named: "check.unselected")
            checkbox.setImage(image, for: .normal)
        }
    }
    
    private func updateTextStyle() {
        guard let todo = todo else { return }
        
        if todo.completed {
            titleLabel.textColor = .lightGray
            let attributed = NSAttributedString(
                string: todo.title ?? "",
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.lightGray
                ]
            )
            titleLabel.attributedText = attributed
            
            detailsLabel.textColor = .lightGray
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = todo.title
            titleLabel.textColor = .white
            
            detailsLabel.textColor = .white
        }
    }
    
    // MARK: - Actions
    @objc private func didTapCheckbox() {
        guard let todo else { return }
        delegate?.didTapCheckbox(for: todo)
        todo.completed.toggle()
        
        updateCheckboxUI()
        updateTextStyle()
    }
    
    func hideCheckbox() {
        checkbox.isHidden = true
        
        titleLeadingConstraint?.deactivate()
        titleLabel.snp.makeConstraints { make in
            titleLeadingConstraint = make.leading.equalToSuperview().inset(16).constraint
        }
        
        layoutIfNeeded()
    }
    
    func showCheckbox() {
        checkbox.isHidden = false
        
        titleLeadingConstraint?.deactivate()
        titleLabel.snp.makeConstraints { make in
            titleLeadingConstraint = make.leading.equalTo(checkbox.snp.trailing).offset(12).constraint
        }
        
        layoutIfNeeded()
    }
    
    // MARK: - Animations
    func animateCheckboxAppearance() {
        checkbox.alpha = 0
        checkbox.isHidden = false

        showCheckbox()
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.checkbox.alpha = 1
            self.layoutIfNeeded()
        }
    }
    
    func animateCheckboxDisappearance() {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.checkbox.alpha = 0
            self.layoutIfNeeded()
        } completion: { _ in
            self.hideCheckbox()
        }
    }
    
    private func animateHighlight(_ highlight: Bool) {
        // Останавливаем предыдущую анимацию, если есть
        highlightAnimator?.stopAnimation(true)
        
        // Создаем новый аниматор
        highlightAnimator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 0.8) {
            if highlight {
                self.contentView.backgroundColor = UIColor(white: 0.15, alpha: 1)
                self.contentView.layer.cornerRadius = 12
            } else {
                self.contentView.backgroundColor = .black
                self.contentView.layer.cornerRadius = 0
            }
        }
        
        highlightAnimator?.startAnimation()
    }
}
