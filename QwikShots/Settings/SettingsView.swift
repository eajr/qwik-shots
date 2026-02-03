import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var isRecordingHotkey = false
    @State private var tempKeyCombo: KeyCombo

    private let backgrounds = BackgroundCatalog.load()

    init() {
        _tempKeyCombo = State(initialValue: SettingsManager.shared.keyCombo)
    }

    var body: some View {
        Form {
            Section("Global Hotkey") {
                HStack {
                    Text("Capture Screenshot")
                    Spacer()
                    HotKeyRecorderView(keyCombo: $tempKeyCombo, isRecording: $isRecordingHotkey)
                        .frame(width: 150, height: 28)
                        .onChange(of: tempKeyCombo) { _, newValue in
                            settings.updateHotkey(newValue)
                        }
                }

                Text("Click the field and press your desired key combination.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Default Screenshot Style") {
                Picker("Background", selection: $settings.defaultBackgroundID) {
                    ForEach(backgrounds) { option in
                        Text(option.name).tag(option.id)
                    }
                }

                SettingsSlider(title: "Padding", value: $settings.defaultPadding, range: 0...200)
                SettingsSlider(title: "Corner Radius", value: $settings.defaultCornerRadius, range: 0...80)

                Toggle("Drop Shadow", isOn: $settings.defaultShadowEnabled)

                Group {
                    SettingsSlider(title: "Shadow Opacity", value: $settings.defaultShadowOpacity, range: 0...0.6)
                    SettingsSlider(title: "Shadow Blur", value: $settings.defaultShadowRadius, range: 0...48)
                    SettingsSlider(title: "Shadow Offset", value: $settings.defaultShadowOffsetY, range: -24...24)
                }
                .disabled(!settings.defaultShadowEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 420)
        .fixedSize()
    }
}

// Separate slider for settings to avoid coupling with PreviewView's LabeledSlider
private struct SettingsSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(valueDescription)
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }

    private var valueDescription: String {
        if range.upperBound <= 1.0 {
            return String(format: "%.2f", value)
        }
        return String(format: "%.0f", value)
    }
}
