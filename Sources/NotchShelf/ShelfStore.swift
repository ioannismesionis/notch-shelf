import AppKit
import Combine

final class ShelfStore: ObservableObject {
    @Published var isExpanded = false
    @Published var isPinned = false
    @Published var files: [ShelfItem] = []
    @Published var clipboardPreview = "Clipboard empty"
    @Published var activeApplicationName = "No active app"
    @Published var currentScreenName = "Main display"

    func refresh() {
        activeApplicationName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "No active app"

        let rawClipboard = NSPasteboard.general.string(forType: .string) ?? ""
        let trimmedClipboard = rawClipboard
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedClipboard.isEmpty {
            clipboardPreview = "Clipboard empty"
        } else if trimmedClipboard.count > 68 {
            clipboardPreview = String(trimmedClipboard.prefix(68)) + "..."
        } else {
            clipboardPreview = trimmedClipboard
        }
    }

    func addFiles(_ urls: [URL]) {
        let newItems = urls
            .filter { $0.isFileURL }
            .map(ShelfItem.init)
            .filter { item in !files.contains(where: { $0.url == item.url }) }

        files.insert(contentsOf: newItems, at: 0)
        files = Array(files.prefix(8))
    }

    func clearFiles() {
        files.removeAll()
    }
}

struct ShelfItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL

    var name: String {
        url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
    }

    var location: String {
        url.deletingLastPathComponent().path
    }
}
