import Foundation
import SwiftData

@Model
final class LearningProgress {
    @Attribute(.unique) var contentID: UUID
    var contentKindRawValue: String
    var firstSeenAt: Date
    var lastSeenAt: Date
    var timesSeen: Int
    var knownCount: Int
    var reviewCount: Int
    var pronunciationAttempts: Int
    var statusRawValue: String
    var consecutiveKnown: Int = 0
    var lastAssessmentAt: Date? = nil
    var nextReviewAt: Date? = nil

    init(contentID: UUID, contentKind: LearningItemKind, now: Date = .now) {
        self.contentID = contentID
        contentKindRawValue = contentKind.rawValue
        firstSeenAt = now
        lastSeenAt = now
        timesSeen = 1
        knownCount = 0
        reviewCount = 0
        pronunciationAttempts = 0
        statusRawValue = LearningStatus.seen.rawValue
        consecutiveKnown = 0
        lastAssessmentAt = nil
        nextReviewAt = nil
    }

    var contentKind: LearningItemKind {
        get { LearningItemKind(rawValue: contentKindRawValue) ?? .word }
        set { contentKindRawValue = newValue.rawValue }
    }

    var status: LearningStatus {
        get { LearningStatus(rawValue: statusRawValue) ?? .new }
        set { statusRawValue = newValue.rawValue }
    }

    func recordSeen(at date: Date = .now) {
        lastSeenAt = date
        timesSeen += 1
        if status == .new {
            status = .seen
        }
    }

    func recordKnown(at date: Date = .now) {
        lastSeenAt = date
        lastAssessmentAt = date
        knownCount += 1
        consecutiveKnown += 1
        status = consecutiveKnown >= 3 ? .known : .learning
        nextReviewAt = Calendar.current.date(
            byAdding: .day,
            value: reviewIntervalDays,
            to: date
        )
    }

    func recordReview(at date: Date = .now) {
        lastSeenAt = date
        lastAssessmentAt = date
        reviewCount += 1
        consecutiveKnown = 0
        status = .review
        nextReviewAt = date
    }

    func recordPronunciationAttempt(at date: Date = .now) {
        pronunciationAttempts += 1
        lastSeenAt = date
    }

    func isDue(at date: Date = .now) -> Bool {
        status == .review || nextReviewAt.map { $0 <= date } == true
    }

    private var reviewIntervalDays: Int {
        switch consecutiveKnown {
        case 0...1: 1
        case 2: 3
        case 3: 7
        case 4: 14
        default: 30
        }
    }
}

enum LearningStatus: String, Codable, CaseIterable {
    case new
    case seen
    case learning
    case known
    case review
}
