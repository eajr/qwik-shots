import SwiftUI

struct PreviewView: View {
    @ObservedObject var viewModel: PreviewViewModel

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Color.black.opacity(0.04)
                Image(nsImage: viewModel.renderedImage)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
            }
            .frame(minWidth: 480, minHeight: 360)

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                Text("Edit")
                    .font(.headline)

                Picker("Background", selection: $viewModel.selectedBackgroundID) {
                    ForEach(viewModel.availableBackgrounds) { option in
                        Text(option.name).tag(option.id)
                    }
                }
                .onChange(of: viewModel.selectedBackgroundID) { _, _ in
                    viewModel.rebuildRenderedImage()
                }

                LabeledSlider(title: "Padding", value: $viewModel.padding, range: 0...200)
                LabeledSlider(title: "Corner Radius", value: $viewModel.cornerRadius, range: 0...80)

                Toggle("Drop Shadow", isOn: $viewModel.shadowEnabled)

                Group {
                    LabeledSlider(title: "Shadow Opacity", value: $viewModel.shadowOpacity, range: 0...0.6)
                    LabeledSlider(title: "Shadow Blur", value: $viewModel.shadowRadius, range: 0...48)
                    LabeledSlider(title: "Shadow Offset", value: $viewModel.shadowOffsetY, range: -24...24)
                }
                .disabled(!viewModel.shadowEnabled)

                Spacer()

                HStack {
                    Button("Copy") {
                        viewModel.copyToClipboard()
                    }
                    Button("Save…") {
                        viewModel.saveToFile()
                    }
                }
            }
            .padding(20)
            .frame(width: 280)
        }
    }
}

struct LabeledSlider: View {
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
