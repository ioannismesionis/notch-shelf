import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct NotchShelfRootView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)

            if store.isExpanded {
                ExpandedShelfView(store: store, actions: actions)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                CollapsedPillView(store: store, actions: actions)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: store.isExpanded ? 24 : 19, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: store.isExpanded ? 24 : 19, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.32), radius: 18, x: 0, y: 12)
        .animation(.easeInOut(duration: 0.16), value: store.isExpanded)
        .onHover(perform: actions.setHovering)
    }
}

private struct CollapsedPillView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions

    var body: some View {
        Button(action: actions.toggleExpanded) {
            HStack(spacing: 9) {
                Image(systemName: "rectangle.topthird.inset.filled")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text(store.isPinned ? "NotchShelf pinned" : "NotchShelf")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.white)

                if !store.files.isEmpty {
                    Text("\(store.files.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 20, height: 20)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ExpandedShelfView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions
    @State private var isDropTarget = false

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 13) {
            header

            LazyVGrid(columns: columns, spacing: 10) {
                InfoTile(
                    icon: "app.connected.to.app.below.fill",
                    title: "Active",
                    value: store.activeApplicationName
                )

                InfoTile(
                    icon: "display",
                    title: "Display",
                    value: store.currentScreenName
                )

                InfoTile(
                    icon: "doc.on.clipboard",
                    title: "Clipboard",
                    value: store.clipboardPreview
                )

                InfoTile(
                    icon: "clock",
                    title: "Now",
                    value: Date.now.formatted(date: .omitted, time: .shortened)
                )
            }

            fileShelf
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dropDestination(for: URL.self) { urls, _ in
            actions.addFiles(urls)
            return true
        } isTargeted: { isTargeted in
            isDropTarget = isTargeted
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.topthird.inset.filled")
                    .font(.system(size: 15, weight: .semibold))
                Text("NotchShelf")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)

            Spacer()

            IconButton(
                systemName: store.isPinned ? "pin.fill" : "pin",
                label: store.isPinned ? "Unpin" : "Pin",
                action: actions.togglePinned
            )

            IconButton(systemName: "minus", label: "Collapse", action: actions.toggleExpanded)
        }
    }

    private var fileShelf: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("File shelf", systemImage: "tray.full")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                if !store.files.isEmpty {
                    Button("Clear", action: actions.clearFiles)
                        .font(.system(size: 11, weight: .semibold))
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.68))
                }
            }

            if store.files.isEmpty {
                VStack(spacing: 7) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Drop files here")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(isDropTarget ? Color.white : Color.white.opacity(0.58))
                .frame(maxWidth: .infinity, minHeight: 82)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isDropTarget ? Color.white.opacity(0.16) : Color.white.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(isDropTarget ? 0.34 : 0.1), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(store.files) { item in
                            FileChip(
                                item: item,
                                open: { actions.openFile(item) },
                                reveal: { actions.revealFile(item) }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(minHeight: 82)
            }
        }
    }
}

private struct InfoTile: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.56))
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(height: 58)
        .background(Color.white.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct FileChip: View {
    let item: ShelfItem
    let open: () -> Void
    let reveal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                    .resizable()
                    .frame(width: 22, height: 22)

                Text(item.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack(spacing: 8) {
                Button(action: open) {
                    Image(systemName: "arrow.up.right.square")
                }
                .help("Open")

                Button(action: reveal) {
                    Image(systemName: "folder")
                }
                .help("Reveal in Finder")
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.78))
        }
        .padding(10)
        .frame(width: 148, height: 76)
        .background(Color.white.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct IconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 28, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.82))
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(label)
    }
}
