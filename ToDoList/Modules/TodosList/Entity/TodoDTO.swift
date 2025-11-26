//
//  TodoDTO.swift
//  ToDoList
//
//  Created by Славка Корн on 19.11.2025.
//

import Foundation

struct TodosResponse: Codable {
    let todos: [TodoDTO]
    let total: Int
    let skip: Int
    let limit: Int
}

struct TodoDTO: Codable {
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
}

