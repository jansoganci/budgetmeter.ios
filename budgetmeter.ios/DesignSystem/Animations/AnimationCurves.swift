//
//  AnimationCurves.swift
//  BudgetMeter
//
//  Design System v4 — Standard animation curves and durations
//

import SwiftUI

// MARK: - Animation System

/// Standard animation curves for consistent motion design
enum AnimationCurve {

    // MARK: - Spring Animations

    /// Quick spring - 0.3s (buttons, toggles, quick feedback)
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Medium spring - 0.6s (cards, reveals, navigation)
    static let mediumSpring = Animation.spring(response: 0.6, dampingFraction: 0.75)

    /// Bar chart spring - 0.8s (bar chart animations)
    static let chartSpring = Animation.spring(response: 0.8, dampingFraction: 0.7)

    /// Progress spring - 1.2s (progress bar fills, value counts)
    static let progressSpring = Animation.spring(response: 1.2, dampingFraction: 0.7)

    /// Slow spring - 1.5s (hero elements, circular progress, health score)
    static let slowSpring = Animation.spring(response: 1.5, dampingFraction: 0.7)

    // MARK: - v4 semantic aliases

    static let buttonPress = quickSpring
    static let cardReveal = mediumSpring
    static let paceUpdate = progressSpring
    static let heroReveal = slowSpring
    static let chartBar = chartSpring

    // MARK: - Ease Animations

    /// Quick ease - 0.3s (quick feedback)
    static let quickEase = Animation.easeInOut(duration: 0.3)

    /// Medium ease - 0.6s (content changes, navigation)
    static let mediumEase = Animation.easeOut(duration: 0.6)

    // MARK: - Staggered Delays

    /// Standard stagger delay per item (0.05s)
    static let staggerDelay: Double = 0.05
}

// MARK: - Haptic Feedback

/// Haptic feedback generator wrapper
enum Haptics {

    /// Light impact - Card press/touch down, toggle switches
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact - Button tap confirmation
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact - Major actions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Success notification - Goal reached, successful save
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Error notification - Invalid input, failed action
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Warning notification - Budget exceeded, approaching limit
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Selection feedback - Picker change, selection
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Animated Value Helper

extension View {
    /// Animates a value from 0 to target with spring animation
    /// - Parameters:
    ///   - value: Binding to the animated value
    ///   - target: Target value to animate to
    ///   - duration: Animation response time (default: 1.2s)
    func animateOnAppear(value: Binding<Double>, target: Double, duration: Double = 1.2) -> some View {
        self.onAppear {
            withAnimation(.spring(response: duration, dampingFraction: 0.8)) {
                value.wrappedValue = target
            }
        }
    }
}

// MARK: - Press Effect Modifier

extension View {
    /// Adds iOS-style press effect (scale down on press)
    /// - Parameters:
    ///   - isPressed: Binding to pressed state
    ///   - scale: Scale when pressed (default: 0.98)
    ///   - haptic: Whether to trigger haptic feedback (default: true)
    func pressEffect(isPressed: Binding<Bool>, scale: CGFloat = 0.98, haptic: Bool = true) -> some View {
        self
            .scaleEffect(isPressed.wrappedValue ? scale : 1.0)
            .animation(AnimationCurve.quickSpring, value: isPressed.wrappedValue)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressed.wrappedValue = pressing
                if pressing && haptic {
                    Haptics.light()
                }
            }, perform: {})
    }
}

// MARK: - Reduce Motion Support

extension View {
    /// Applies animation only if Reduce Motion is disabled
    /// - Parameter animation: The animation to apply
    func reducedMotion(_ animation: Animation?) -> some View {
        self.modifier(ReducedMotionModifier(animation: animation))
    }
}

private struct ReducedMotionModifier: ViewModifier {
    let animation: Animation?
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? .none : animation, value: UUID())
    }
}
