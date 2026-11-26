import SwiftUI

/// Bottom Color Selection Palette and Action Toolbar for Normal Coloring
public struct PaletteBarView: View {
    @Binding var selectedColor: Color
    @Binding var currentTool: ColoringViewModel.DrawingTool
    @Binding var brushSize: CGFloat
    let canUndo: Bool
    let canRedo: Bool
    let onToolSelected: (ColoringViewModel.DrawingTool) -> Void
    let onBrushSizeSelected: (CGFloat) -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onReset: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void

    public init(
        selectedColor: Binding<Color>,
        currentTool: Binding<ColoringViewModel.DrawingTool>,
        brushSize: Binding<CGFloat>,
        canUndo: Bool,
        canRedo: Bool,
        onToolSelected: @escaping (ColoringViewModel.DrawingTool) -> Void,
        onBrushSizeSelected: @escaping (CGFloat) -> Void,
        onUndo: @escaping () -> Void,
        onRedo: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onSave: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) {
        self._selectedColor = selectedColor
        self._currentTool = currentTool
        self._brushSize = brushSize
        self.canUndo = canUndo
        self.canRedo = canRedo
        self.onToolSelected = onToolSelected
        self.onBrushSizeSelected = onBrushSizeSelected
        self.onUndo = onUndo
        self.onRedo = onRedo
        self.onReset = onReset
        self.onSave = onSave
        self.onShare = onShare
    }

    public var body: some View {
        VStack(spacing: 10) {
            // 1. Tool Selection & Brush Size Selector
            ToolSelectorBarView(
                currentTool: $currentTool,
                brushSize: $brushSize,
                onToolSelected: onToolSelected,
                onBrushSizeSelected: onBrushSizeSelected
            )

            // 2. Action Toolbar (Undo, Redo, Reset, Share, Save)
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

/// Tool selection bar matching Android (Brush, Fill, Eraser + Brush size dots)
public struct ToolSelectorBarView: View {
    @Binding var currentTool: ColoringViewModel.DrawingTool
    @Binding var brushSize: CGFloat
    let onToolSelected: (ColoringViewModel.DrawingTool) -> Void
    let onBrushSizeSelected: (CGFloat) -> Void

    public init(
        currentTool: Binding<ColoringViewModel.DrawingTool>,
        brushSize: Binding<CGFloat>,
        onToolSelected: @escaping (ColoringViewModel.DrawingTool) -> Void,
        onBrushSizeSelected: @escaping (CGFloat) -> Void
    ) {
        self._currentTool = currentTool
        self._brushSize = brushSize
        self.onToolSelected = onToolSelected
        self.onBrushSizeSelected = onBrushSizeSelected
    }

    public var body: some View {
        HStack {
            // Mode selector chips: Brush, Fill, Eraser
            HStack(spacing: 8) {
                toolChip(tool: .brush, icon: "paintbrush.pointed.fill", title: "Brush")
                toolChip(tool: .fill, icon: "drop.fill", title: "Fill")
                toolChip(tool: .eraser, icon: "eraser.fill", title: "Eraser")
            }

            Spacer()

            // Brush size selector dots (visible for Brush and Eraser)
            if currentTool != .fill {
                HStack(spacing: 8) {
                    let sizes: [(CGFloat, CGFloat)] = [(14.0, 6.0), (28.0, 10.0), (50.0, 15.0)]
                    ForEach(sizes, id: \.0) { sizeVal, dotSize in
                        let isSelected = abs(brushSize - sizeVal) < 2.0
                        Button(action: {
                            HapticFeedback.light()
                            onBrushSizeSelected(sizeVal)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: isSelected ? 1.5 : 1)
                                    )

                                Circle()
                                    .fill(isSelected ? Color.blue : Color.secondary.opacity(0.7))
                                    .frame(width: dotSize, height: dotSize)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private func toolChip(tool: ColoringViewModel.DrawingTool, icon: String, title: String) -> some View {
        let isSelected = currentTool == tool
        return Button(action: {
            HapticFeedback.selection()
            onToolSelected(tool)
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(uiColor: .tertiarySystemFill))
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
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
        currentTool: .constant(.brush),
        brushSize: .constant(28.0),
        canUndo: true,
        canRedo: false,
        onToolSelected: { _ in },
        onBrushSizeSelected: { _ in },
        onUndo: {},
        onRedo: {},
        onReset: {},
        onSave: {},
        onShare: {}
    )
}
