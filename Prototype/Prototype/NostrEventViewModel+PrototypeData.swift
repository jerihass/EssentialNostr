//
//  Created by Jericho Hasselbush on 6/5/24.
//

import Foundation

extension NostrEventViewModel {
    static var prototypeEvents: [NostrEventViewModel] {
        generateNostrEventViewModels()
    }
}

private func generateRandomString(length: Int) -> String {
    let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map { _ in characters.randomElement()! })
}

private func generateRandomDate() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yy-MM-dd"
    let randomTimeInterval = TimeInterval(arc4random_uniform(365) * 86400) // Random number of days up to a year
    let randomDate = Date().addingTimeInterval(randomTimeInterval)
    return dateFormatter.string(from: randomDate)
}

private func generateRandomTime() -> String {
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm:ss"
    let randomTimeInterval = TimeInterval(arc4random_uniform(86400)) // Random number of seconds in a day
    let randomTime = Date().addingTimeInterval(randomTimeInterval)
    return timeFormatter.string(from: randomTime)
}

private func generateRandomContent() -> String {
    let sampleSentences = [
        "Just finished a great book!",
        "Exploring the new city.",
        "Had a fantastic dinner at a local restaurant.",
        "Learning Swift programming.",
        "Working on a new project idea.",
        "Met some old friends today.",
        "Trying out a new recipe.",
        "Went for a morning run.",
        "Watching a classic movie tonight.",
        "Planning a trip for the weekend.",
        "The weather was perfect for a picnic.",
        "Discovered a hidden gem in the neighborhood.",
        "Spent the afternoon at the museum.",
        "Joined a local sports club.",
        "Reading a fascinating article on technology.",
        "Started a new hobby in painting.",
        "Volunteered at a community event.",
        "Had a productive workday.",
        "Catching up on some much-needed sleep.",
        "Enjoyed a peaceful day at the park."
    ]

    let numberOfSentences = Int.random(in: 1...10)
    var content = ""
    for _ in 1...numberOfSentences {
        if let sentence = sampleSentences.randomElement() {
            content += sentence + " "
        }
    }
    return content.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func generateNostrEventViewModels() -> [NostrEventViewModel] {
    var events = [NostrEventViewModel]()

    for _ in 1...10 {
        let npub = "npub" + generateRandomString(length: 28) // "npub" + 28 random characters
        let content = generateRandomContent()
        let date = generateRandomDate()
        let time = generateRandomTime()
        events.append(NostrEventViewModel(npub: npub, content: content, date: date, time: time))
    }

    return events
}
