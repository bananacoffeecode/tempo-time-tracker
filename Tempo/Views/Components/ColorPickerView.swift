import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColorId: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CalendarColor.allCases) { calColor in
                        swatch(for: calColor)
                            .id(calColor.id)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
            // Only scroll on first appearance so the current color is visible;
            // never auto-scroll on tap, which felt jumpy.
            .onAppear { proxy.scrollTo(selectedColorId, anchor: .center) }
        }
    }

    private func swatch(for calColor: CalendarColor) -> some View {
        let selected = selectedColorId == calColor.id

        return Button {
            selectedColorId = calColor.id
        } label: {
            Circle()
                .fill(calColor.color)
                .frame(width: 24, height: 24)
                .overlay {
                    Circle()
                        .strokeBorder(.white, lineWidth: selected ? 2 : 0)
                        .padding(1)
                }
                .overlay {
                    // Subtle ring that grows in around the selected swatch.
                    Circle()
                        .strokeBorder(calColor.color, lineWidth: 2)
                        .padding(-3)
                        .opacity(selected ? 1 : 0)
                        .scaleEffect(selected ? 1 : 0.6)
                }
                .shadow(color: selected ? calColor.color.opacity(0.5) : .clear, radius: 4)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(calColor.label)
        .animation(.snappy(duration: 0.22), value: selected)
    }
}
