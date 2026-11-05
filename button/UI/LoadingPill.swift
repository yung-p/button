import SwiftUI

// A pill-shaped loading bar: grey track, red fill growing left to right.
struct LoadingPill: View {
    let progress: Double // 0...1, handed in from outside (e.g. transcriber.loadProgress). "let" = this view only reads it

    private let width: CGFloat = 140
    private let height: CGFloat = 28

    var body: some View {
        ZStack(alignment: .leading) { // Layers views on top of each other, all lined up on the left edge
            Rectangle()
                .fill(Color.gray.opacity(0.2)) // The empty track behind the fill

            Rectangle()
                .fill(Color.red)
                .frame(width: width * progress) // The fill: 0% wide at progress 0, full width at progress 1
        }
        .frame(width: width, height: height)
        .clipShape(Capsule()) // Cut both layers into a pill shape (rounded ends)
        .animation(.easeOut(duration: 0.3), value: progress) // When progress jumps, slide smoothly to the new width instead of snapping
    }
}

#Preview { // Shows the pill 40% full in Xcode's canvas
    LoadingPill(progress: 0.4)
}
