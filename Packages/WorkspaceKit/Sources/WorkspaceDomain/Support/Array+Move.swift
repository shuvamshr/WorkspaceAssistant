import Foundation

extension Array {
    /// Moves the elements at `offsets` so they start at `destination`, matching SwiftUI's `onMove` semantics.
    /// Out-of-range offsets are ignored and the destination is clamped.
    mutating func moveElements(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        let valid = offsets.filter { indices.contains($0) }
        guard !valid.isEmpty else { return }
        let destination = Swift.min(Swift.max(destination, 0), count)
        let moving = valid.map { self[$0] }
        let insertAt = destination - valid.count(where: { $0 < destination })
        var remaining = enumerated().filter { !valid.contains($0.offset) }.map(\.element)
        remaining.insert(contentsOf: moving, at: insertAt)
        self = remaining
    }
}
