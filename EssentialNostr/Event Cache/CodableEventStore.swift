//
//  Created by Jericho Hasselbush on 5/31/24.
//

import Foundation

public class CodableEventStore: EventStore {
    private let queue = DispatchQueue(label: "\(CodableEventStore.self)Queue", qos: .userInitiated, attributes: .concurrent)
    private let storeURL: URL

    public init(storeURL: URL) {
        self.storeURL = storeURL
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        let storeURL = self.storeURL
        queue.async {
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.success([]))
            }
            do {
                let decoder = JSONDecoder()
                let codableEvents = try decoder.decode([CodableEvent].self, from: data)
                let events = codableEvents.map(\.local)
                completion(.success(events))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func insert(_ events: [LocalEvent], completion: @escaping InsertionCompletion) {
        let storeURL = self.storeURL
        var storedEvents: [LocalEvent]?

        self.retrieve { result in
            storedEvents = try? result.get()
        }

        queue.async(flags: .barrier) {
            var tempEvents = events
            tempEvents.insert(contentsOf: storedEvents ?? [], at: 0)

            do {
                let encoder = JSONEncoder()
                let codableEvents = tempEvents.map(CodableEvent.init)
                let data = try encoder.encode(codableEvents)
                try data.write(to: storeURL)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func deleteCachedEvents(completion: @escaping DeletionCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: storeURL.path()) else {
                return completion(.success(()))
            }
            do {
                try FileManager.default.removeItem(at: storeURL)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private struct CodableEvent: Codable {
        private let id: String
        private let publickey: String
        private let created: Date
        private let kind: UInt16
        private let tags: [[String]]
        private let content: String
        private let signature: String

        init(id: String, publicKey: String, created: Date, kind: UInt16, tags: [[String]], content: String, signature: String) {
            self.id = id
            self.publickey = publicKey
            self.created = created
            self.kind = kind
            self.tags = tags
            self.content = content
            self.signature = signature
        }

        init(_ event: LocalEvent) {
            id = event.id
            publickey = event.publickey
            created = event.created
            kind = event.kind
            tags = event.tags
            content = event.content
            signature = event.signature
        }

        var local: LocalEvent {
            LocalEvent(id: self.id, publicKey: self.publickey, created: self.created, kind: self.kind, tags: self.tags, content: self.content, signature: self.signature)
        }
    }
}
