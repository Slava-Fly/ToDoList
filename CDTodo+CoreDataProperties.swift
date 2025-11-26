//
//  CDTodo+CoreDataProperties.swift
//  ToDoList
//
//  Created by Славка Корн on 18.11.2025.
//
//

import Foundation
import CoreData


extension CDTodo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTodo> {
        return NSFetchRequest<CDTodo>(entityName: "CDTodo")
    }

    @NSManaged public var title: String?
    @NSManaged public var userId: Int64
    @NSManaged public var details: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var completed: Bool
    @NSManaged public var id: Int64

}

extension CDTodo : Identifiable {

}
