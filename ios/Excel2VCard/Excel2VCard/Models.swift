import Foundation

struct ContactRecord: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var phone: String?
    var email: String?
    var company: String?
    var title: String?
    
    // For deduplication key
    var dedupeKey: String {
        let normalizedPhone = normalizePhone(phone ?? "")
        return "\(name.lowercased())|\(normalizedPhone)"
    }
    
    // Normalize phone number for comparison
    private func normalizePhone(_ phone: String) -> String {
        var normalized = phone
        // Remove spaces
        normalized = normalized.replacingOccurrences(of: " ", with: "")
        // Remove +86
        normalized = normalized.replacingOccurrences(of: "+86", with: "")
        // Remove hyphens
        normalized = normalized.replacingOccurrences(of: "-", with: "")
        return normalized
    }
    
    static func == (lhs: ContactRecord, rhs: ContactRecord) -> Bool {
        return lhs.dedupeKey == rhs.dedupeKey
    }
}
