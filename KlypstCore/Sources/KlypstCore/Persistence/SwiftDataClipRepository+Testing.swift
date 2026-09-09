import Foundation
import SwiftData

extension SwiftDataClipRepository {
    /// Test support: rewrites `lastUsedAt` for the given clips.
    public func _backdate(ids: [UUID], to date: Date) throws {
        let descriptor = FetchDescriptor<ClipRecord>(predicate: #Predicate { ids.contains($0.id) })
        for record in try modelContext.fetch(descriptor) {
            record.lastUsedAt = date
        }
        try modelContext.save()
    }
}
