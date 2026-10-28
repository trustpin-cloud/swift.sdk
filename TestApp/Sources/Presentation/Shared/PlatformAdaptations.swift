import SwiftUI

// The sample builds for every TestApp destination (device sign-off, spec 008
// T26). These helpers replace the iOS-only SwiftUI and UIKit APIs the cards
// used, so each view stays free of `#if os(...)` noise.

extension Color {
    /// Card background (was `Color(.systemGray6)`, UIKit only).
    static let sampleCard = Color.gray.opacity(0.12)
    /// Inner panel background (was `Color(.systemGray5)`).
    static let samplePanel = Color.gray.opacity(0.22)
    /// Inset surface on a card (was `Color(.systemBackground)`).
    static var sampleSurface: Color {
        #if os(iOS) || os(visionOS)
        return Color(.systemBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.black.opacity(0.15)
        #endif
    }
}

extension View {
    /// No automatic capitalisation where a software keyboard exists.
    @ViewBuilder
    func sampleNoAutocapitalization() -> some View {
        #if os(iOS) || os(visionOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    /// Rounded border where the platform offers it; plain on tvOS and watchOS.
    @ViewBuilder
    func sampleTextFieldStyle() -> some View {
        #if os(tvOS) || os(watchOS)
        self.textFieldStyle(.plain)
        #else
        self.textFieldStyle(.roundedBorder)
        #endif
    }

    /// Inline navigation title where the modifier exists.
    @ViewBuilder
    func sampleTitleDisplayMode() -> some View {
        #if os(macOS) || os(tvOS)
        self
        #else
        self.navigationBarTitleDisplayMode(.automatic)
        #endif
    }

    /// Tap handling where tap gestures exist (tvOS 15 has none; focus-based).
    @ViewBuilder
    func sampleOnTap(perform action: @escaping () -> Void) -> some View {
        #if os(tvOS)
        self
        #else
        self.onTapGesture(perform: action)
        #endif
    }
}

/// A single-column navigation container for each tab. On macOS a
/// `NavigationView` is a split view: its only child becomes the sidebar and
/// the detail column stays empty, so macOS gets a `NavigationStack` (the
/// sample's macOS floor is 15). Elsewhere `NavigationView` with the stack
/// style, because the sample still runs on iOS 15.
struct SampleNavigation<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        #if os(macOS)
        NavigationStack(root: content)
        #else
        NavigationView(content: content)
            .navigationViewStyle(StackNavigationViewStyle())
        #endif
    }
}
