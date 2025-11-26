//
//  DataFormatter.swift
//  ToDoList
//
//  Created by Славка Корн on 25.11.2025.
//

import Foundation

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yy"
        return f
    }()
}
