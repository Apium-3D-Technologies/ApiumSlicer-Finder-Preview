import SwiftUI
import CoreGraphics

struct QuickLookPreviewView: View {
    let metadata: PreviewMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            imageSection
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .background(Color.black.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Group {
                row(label: "Printer", value: metadata.printer)
                row(label: "Project Version", value: metadata.projectVersion)
                row(label: "Material Type", value: metadata.materialType)
                row(label: "Nozzle Diameter", value: withUnit(metadata.nozzleDiameter, unit: "mm"))
                row(label: "Nozzle Temperature", value: temperatureString(metadata.nozzleTemperature))
                row(label: "Bed Temperature", value: temperatureString(metadata.bedTemperature))
                row(label: "Layer Height", value: withUnit(metadata.layerHeight, unit: "mm"))
                row(label: "Perimeters", value: metadata.perimeters)
                row(label: "Infill Pattern", value: metadata.infillPattern)
                row(label: "Infill Density", value: metadata.infillDensity)
                if let printTime = metadata.printTime, !printTime.isEmpty {
                    row(label: "Print Time", value: printTime)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(minWidth: 560, minHeight: 420)
    }

    @ViewBuilder
    private var imageSection: some View {
        if let cgImage = metadata.previewImage {
            Image(decorative: cgImage, scale: 1.0)
                .resizable()
                .scaledToFit()
                .padding(12)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 36, weight: .medium))
                Text("No embedded preview image")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func row(label: String, value: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(label):")
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 150, alignment: .leading)
            Text(value?.isEmpty == false ? value! : "-")
                .font(.system(size: 13))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
    }

    private func withUnit(_ value: String?, unit: String) -> String? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        if raw.range(of: unit, options: .caseInsensitive) != nil {
            return raw
        }
        return "\(raw) \(unit)"
    }

    private func temperatureString(_ value: String?) -> String? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        let lower = raw.lowercased()
        if lower.contains("°c") || lower.contains(" c") || lower.contains("celsius") {
            return raw
        }
        return "\(raw) °C"
    }
}
