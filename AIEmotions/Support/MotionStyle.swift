import SwiftUI

/// Motion directions used to audition the app's transitions in Debug builds.
/// Release builds use `paperLift`, which best matches the handmade card system.
enum MotionStyle: String, CaseIterable, Identifiable {
    case paperLift
    case ink
    case quiet

    static let storageKey = "motionStyle"
    static let defaultValue = MotionStyle.paperLift.rawValue

    var id: String { rawValue }

    static func selected(from storedValue: String) -> MotionStyle {
        #if DEBUG
        MotionStyle(rawValue: storedValue) ?? .paperLift
        #else
        .paperLift
        #endif
    }

    var title: String {
        switch self {
        case .paperLift: "Paper lift"
        case .ink: "Ink bloom"
        case .quiet: "Quiet slide"
        }
    }

    var summary: String {
        switch self {
        case .paperLift: "Tactile layers settle with a soft paper spring."
        case .ink: "Fast, centered reveals mimic ink meeting the page."
        case .quiet: "Short editorial slides keep attention on the words."
        }
    }

    var presentationAnimation: Animation {
        switch self {
        case .paperLift: .spring(response: 0.46, dampingFraction: 0.82)
        case .ink: .easeOut(duration: 0.24)
        case .quiet: .easeInOut(duration: 0.28)
        }
    }

    var replacementAnimation: Animation {
        switch self {
        case .paperLift: .spring(response: 0.38, dampingFraction: 0.86)
        case .ink: .easeOut(duration: 0.2)
        case .quiet: .easeInOut(duration: 0.22)
        }
    }

    var panelTransition: AnyTransition {
        switch self {
        case .paperLift:
            .asymmetric(
                insertion: .modifier(
                    active: MotionTransitionModifier(opacity: 0, scale: 0.92, y: 34, rotation: 1.5),
                    identity: MotionTransitionModifier()
                ),
                removal: .modifier(
                    active: MotionTransitionModifier(opacity: 0, scale: 0.97, y: 18, rotation: -0.5),
                    identity: MotionTransitionModifier()
                )
            )
        case .ink:
            .asymmetric(
                insertion: .modifier(
                    active: MotionTransitionModifier(opacity: 0, scale: 0.88),
                    identity: MotionTransitionModifier()
                ),
                removal: .opacity.combined(with: .scale(scale: 1.03))
            )
        case .quiet:
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }

    var revealTransition: AnyTransition {
        switch self {
        case .paperLift: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.96))
        case .ink: .opacity.combined(with: .scale(scale: 0.9))
        case .quiet: .move(edge: .bottom).combined(with: .opacity)
        }
    }

    var contentTransition: AnyTransition {
        switch self {
        case .paperLift: .opacity.combined(with: .scale(scale: 0.97))
        case .ink: .opacity.combined(with: .scale(scale: 1.02))
        case .quiet: .move(edge: .bottom).combined(with: .opacity)
        }
    }

    var dismissalDelay: Double {
        switch self {
        case .paperLift: 0.52
        case .ink: 0.26
        case .quiet: 0.3
        }
    }

    func panelTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : panelTransition
    }

    func revealTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : revealTransition
    }

    func contentTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : contentTransition
    }

    func animation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : presentationAnimation
    }

    func replacementAnimation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : replacementAnimation
    }
}

private struct MotionTransitionModifier: ViewModifier {
    var opacity = 1.0
    var scale = 1.0
    var y = 0.0
    var rotation = 0.0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(y: y)
            .rotationEffect(.degrees(rotation))
    }
}
