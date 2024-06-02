//
//  SwiftDataEventStore.swift
//  EssentialNostr
//
//  Created by Jericho Hasselbush on 6/1/24.
//

import Foundation
import SwiftData

@available(macOS 14, *)
public class SwiftDataEventStore: EventStore {
    public static func modelConfig(inMemory: Bool = false) -> ModelConfiguration {
        ModelConfiguration(for: SDEvent.self, isStoredInMemoryOnly: inMemory)
    }

    public static func modelConfig(url: URL) -> ModelConfiguration {
        let schema = Schema([SDEvent.self])
        return ModelConfiguration(schema: schema, url: url)
    }

    private static var theContainer: ModelContainer?
    public static func container(configuration: ModelConfiguration) -> ModelContainer {
        if theContainer == nil {
            theContainer = try! ModelContainer(for: SDEvent.self, configurations: configuration)
        }
        return theContainer!
    }

    private let container: ModelContainer
    public init(container: ModelContainer) {
        self.container = container
    }

    @MainActor public func deleteCachedEvents(completion: @escaping DeletionCompletion) {
        do {
//            let predicate = #Predicate<SDEvent> { _ in true }
//            try container.mainContext.delete(model: SDEvent.self, where: predicate)
//              The above should work, but it isn't... need to look why
            let events = try container.mainContext.fetch(FetchDescriptor<SDEvent>())

            for event in events {
                container.mainContext.delete(event)
            }
            completion(nil)
        } catch {
            completion(error)
        }
    }

    @MainActor public func insert(_ events: [EssentialNostr.LocalEvent], completion: @escaping InsertionCompletion) {
        let sdEvents = events.toSwiftData()
        for event in sdEvents { container.mainContext.insert(event) }
        try! container.mainContext.save()
        completion(nil)
    }

    @MainActor public func retrieve(completion: @escaping RetrievalCompletion) {
        let sdEvents = FetchDescriptor<SDEvent>()
        do {
            let events = try container.mainContext.fetch(sdEvents)
            let found = events.map(\.local)
            completion(.success(found))
        } catch {
            completion(.failure(error))
        }
    }
}

@Model
class SDEvent {
    public let id: String
    public let publickey: String
    public let created: Date
    public let kind: UInt16
    public let tags: [[String]]
    public let content: String
    public let signature: String

    public init(id: String, publicKey: String, created: Date, kind: UInt16, tags: [[String]], content: String, signature: String) {
        self.id = id
        self.publickey = publicKey
        self.created = created
        self.kind = kind
        self.tags = tags
        self.content = content
        self.signature = signature
    }

    var local: LocalEvent {
        LocalEvent(id: id, publicKey: publickey, created: created, kind: kind, tags: tags, content: content, signature: signature)
    }
}

extension Array where Element == LocalEvent {
    fileprivate func toSwiftData() -> [SDEvent] {
        map {
            SDEvent(id: $0.id, publicKey: $0.publickey, created: $0.created, kind: $0.kind, tags: $0.tags, content: $0.content, signature: $0.signature)
        }
    }
}
