import Foundation

enum MetadataHelpers {
    static func parseCommentKeyValueLines(from text: String) -> [String: String] {
        var dict: [String: String] = [:]
        text.enumerateLines { line, _ in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix(";") else { return }

            let body = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
            guard let range = body.range(of: " = ") else { return }

            let key = String(body[..<range.lowerBound]).trimmingCharacters(in: .whitespaces).lowercased()
            let value = String(body[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !key.isEmpty {
                dict[key] = value
            }
        }
        return dict
    }

    static func pick(_ keys: [String], from map: [String: String]) -> String? {
        for key in keys {
            let normalized = key.lowercased()
            if let value = map[normalized], let cleaned = normalizeSettingValue(value) {
                return cleaned
            }
        }
        return nil
    }

    static func parseNozzleDiameter(from map: [String: String]) -> String? {
        if let value = pick(["nozzle_diameter"], from: map) {
            return value
        }
        if let variant = pick(["printer_variant"], from: map) {
            if Self.looksNumeric(variant) {
                return variant
            }
        }
        return nil
    }

    static func looksNumeric(_ value: String) -> Bool {
        let cleaned = value.replacingOccurrences(of: "mm", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned) != nil
    }

    static func parseNozzleTemperature(from map: [String: String]) -> String? {
        pick(["first_layer_temperature", "temperature", "nozzle_temperature"], from: map)
    }

    static func parseBedTemperature(from map: [String: String]) -> String? {
        pick(["first_layer_bed_temperature", "bed_temperature"], from: map)
    }

    static func parseLayerHeight(from map: [String: String]) -> String? {
        pick(["layer_height"], from: map)
    }

    static func parsePerimeters(from map: [String: String]) -> String? {
        pick(["perimeters"], from: map)
    }

    static func parseInfillPattern(from map: [String: String]) -> String? {
        pick(["fill_pattern", "infill_pattern"], from: map)
    }

    static func parseInfillDensity(from map: [String: String]) -> String? {
        pick(["fill_density", "infill_density"], from: map)
    }

    private static func normalizeSettingValue(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Multi-extruder values are often comma-separated. Prefer the first value for overview display.
        let first = trimmed.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? trimmed
        let cleaned = first.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        if cleaned.caseInsensitiveCompare("nil") == .orderedSame {
            return nil
        }
        return cleaned
    }
}
