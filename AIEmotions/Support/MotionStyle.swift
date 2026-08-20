import SwiftUI

/// Tactile motion that matches the app's handmade paper card system.
struct MotionStyle {
    static let paperLift = MotionStyle()

    let dismissalDelay = 0.52

    private var presentationAnimation: Animation {
        .spring(response: 0.46, dampingFraction: 0.82)
    }

    private var replacementAnimation: Animation {
        .spring(response: 0.38, dampingFraction: 0.86)
    }

    private var panelTransition: AnyTransition {
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
    }

    private var revealTransition: AnyTransition {
        .move(edge: .top)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.96))
    }

    private var contentTransition: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.97))
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
