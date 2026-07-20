import SwiftUI

struct TimePickerView: View {
    @Binding var date: Date
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker.toggle()
        } label: {
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPicker, arrowEdge: .bottom) {
            VStack(spacing: 0) {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.stepperField)
                .labelsHidden()
                .padding()

                Divider()

                Button("Done") { showPicker = false }
                    .padding(10)
            }
        }
    }
}
