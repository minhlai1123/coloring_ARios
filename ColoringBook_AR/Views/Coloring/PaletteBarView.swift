import SwiftUI

/// Bottom Color Selection Palette and Action Toolbar for Normal Coloring
public struct PaletteBarView: View {
    @Binding var selectedColor: Color
    let canUndo: Bool
    let canRedo: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onReset: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void

    public init(
        selectedColor: Binding<Color>,
        canUndo: Bool,
        canRedo: Bool,
        onUndo: @escaping () -> Void,
        onRedo: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onSave: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) {
        self._selectedColor = selectedColor
        self.canUndo = canUndo
        self.canRedo = canRedo
        self.onUndo = onUndo
        self.onRedo = onRedo
        self.onReset = onReset
        self.onSave = onSave
        self.onShare = onShare
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Action Toolbar (Undo, Redo, Reset, Share, Save)
            HStack(spacing: 18) {
                Button(action: {
                    HapticFeedback.light()
                    onUndo()
                }) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.title2)
                        .foregroundColor(canUndo ? .primary : .secondary.opacity(0.4))
                }
                .disabled(!canUndo)

                Button(action: {
                    HapticFeedback.light()
                    onRedo()
                }) {
                    Image(systemName: "arrow.uturn.forward.circle.fill")
                        .font(.title2)
                        .foregroundColor(canRedo ? .primary : .secondary.opacity(0.4))
                }
                .disabled(!canRedo)

                Button(action: {
                    HapticFeedback.medium()
                    onReset()
                }) {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Share Button (Native Share Sheet)
                Button(action: {
                    HapticFeedback.light()
                    onShare()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(Circle())
                }

                // Save to Photos Button
                Button(action: {
                    HapticFeedback.success()
                    onSave()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)

            Divider()

            // Horizontal Color Palette Swatches (ColorPicker + 18 colors)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // Native iOS Spectrum Color Picker
                    ZStack {
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .pink, .red]),
                                    center: .center
                                )
                            )
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(radius: 2)

                        ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                            .labelsHidden()
                            .opacity(0.015) // Tap targets the color picker natively
                            .frame(width: 36, height: 36)
                    }
                    .frame(width: 44, height: 44)

                    ForEach(ColorPalette.colors, id: \.self) { color in
                        ColorSwatchButton(
                            color: color,
                            isSelected: selectedColor == color,
                            onSelect: {
                                HapticFeedback.light()
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                    selectedColor = color
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: -4)
    }
}

/// Swatch Circle Button with active border indicator
private struct ColorSwatchButton: View {
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: isSelected ? 38 : 32, height: isSelected ? 38 : 32)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                if isSelected {
                    Circle()
                        .stroke(Color.primary, lineWidth: 3)
                        .frame(width: 44, height: 44)
                }
            }
            .frame(width: 46, height: 46)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Rounded corners helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    PaletteBarView(
        selectedColor: .constant(.red),
        canUndo: true,
        canRedo: false,
        onUndo: {},
        onRedo: {},
        onReset: {},
        onSave: {},
        onShare: {}
    )
}
