import Foundation
import CoreXLSX

enum ParserError: LocalizedError {
    case noValidColumns
    case readFailed(String)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .noValidColumns:
            return "文件中没有找到可识别的列"
        case .readFailed(let message):
            return "读取文件失败：\(message)"
        case .noData:
            return "文件中没有数据"
        }
    }
}

class ExcelParser {
    
    // Header mapping keywords (Chinese and English)
    private let nameKeywords = ["姓名", "Name", "name", "名字", "联系人", "Full Name"]
    private let phoneKeywords = ["电话", "Phone", "phone", "手机号", "手机", "Mobile", "mobile", "Tel", "tel"]
    private let emailKeywords = ["邮箱", "Email", "email", "邮件", "Mail", "mail"]
    private let companyKeywords = ["公司", "Company", "company", "单位", "组织", "Org", "org"]
    private let titleKeywords = ["职位", "Title", "title", "职务", "Position", "position"]
    
    // Parse XLSX file
    func parseXLSX(url: URL) throws -> [ContactRecord] {
        guard let file = XLSXFile(filepath: url.path) else {
            throw ParserError.readFailed("无法打开XLSX文件")
        }
        
        // Get first worksheet
        guard let worksheetPath = try file.parseWorksheetPaths().first else {
            throw ParserError.noData
        }
        
        let worksheet = try file.parseWorksheet(at: worksheetPath)
        let sharedStrings = try file.parseSharedStrings()
        
        // Get all rows
        guard let rows = worksheet.data?.rows, !rows.isEmpty else {
            throw ParserError.noData
        }
        
        // First row is header
        let headerRow = rows[0]
        let headers = headerRow.cells.map { cell -> String in
            cell.stringValue(sharedStrings) ?? ""
        }
        
        // Map headers to field indices
        let headerMap = mapHeaders(headers)
        
        guard headerMap["name"] != nil else {
            throw ParserError.noValidColumns
        }
        
        // Parse data rows
        var contacts: [ContactRecord] = []
        
        for row in rows.dropFirst() {
            let values = row.cells.map { cell -> String in
                cell.stringValue(sharedStrings) ?? ""
            }
            
            guard let nameIndex = headerMap["name"],
                  nameIndex < values.count,
                  !values[nameIndex].trimmingCharacters(in: .whitespaces).isEmpty else {
                continue
            }
            
            let name = values[nameIndex].trimmingCharacters(in: .whitespaces)
            let phone = headerMap["phone"].flatMap { $0 < values.count ? values[$0] : nil }?.trimmingCharacters(in: .whitespaces)
            let email = headerMap["email"].flatMap { $0 < values.count ? values[$0] : nil }?.trimmingCharacters(in: .whitespaces)
            let company = headerMap["company"].flatMap { $0 < values.count ? values[$0] : nil }?.trimmingCharacters(in: .whitespaces)
            let title = headerMap["title"].flatMap { $0 < values.count ? values[$0] : nil }?.trimmingCharacters(in: .whitespaces)
            
            let contact = ContactRecord(
                name: name,
                phone: phone?.isEmpty == false ? phone : nil,
                email: email?.isEmpty == false ? email : nil,
                company: company?.isEmpty == false ? company : nil,
                title: title?.isEmpty == false ? title : nil
            )
            
            contacts.append(contact)
        }
        
        if contacts.isEmpty {
            throw ParserError.noData
        }
        
        return deduplicateContacts(contacts)
    }
    
    // Parse CSV file
    func parseCSV(url: URL) throws -> [ContactRecord] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw ParserError.noData
        }
        
        // Parse header
        let headers = parseCSVLine(lines[0])
        let headerMap = mapHeaders(headers)
        
        guard headerMap["name"] != nil else {
            throw ParserError.noValidColumns
        }
        
        // Parse data rows
        var contacts: [ContactRecord] = []
        
        for line in lines.dropFirst() {
            let values = parseCSVLine(line)
            
            guard let nameIndex = headerMap["name"],
                  nameIndex < values.count,
                  !values[nameIndex].trimmingCharacters(in: .whitespaces).isEmpty else {
                continue
            }
            
            let name = values[nameIndex].trimmingCharacters(in: .whitespaces)
            let phone = headerMap["phone"].flatMap { $0 < values.count ? values[$0] : nil }?.trimmingCharacters(in: .whitespaces)
            let email = headerMap["email"].flatMap { $0 < values.count ? values[$0] : nil }?.trimmingCharacters(in: .whitespaces)
            let company = headerMap["company"].flatMap { $0 < values.count ? values[$0] : nil }?.trimmingCharacters(in: .whitespaces)
            let title = headerMap["title"].flatMap { $0 < values.count ? values[$0] : nil }?.trimmingCharacters(in: .whitespaces)
            
            let contact = ContactRecord(
                name: name,
                phone: phone?.isEmpty == false ? phone : nil,
                email: email?.isEmpty == false ? email : nil,
                company: company?.isEmpty == false ? company : nil,
                title: title?.isEmpty == false ? title : nil
            )
            
            contacts.append(contact)
        }
        
        if contacts.isEmpty {
            throw ParserError.noData
        }
        
        return deduplicateContacts(contacts)
    }
    
    // Simple CSV line parser
    private func parseCSVLine(_ line: String) -> [String] {
        return line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    // Map headers to field names
    private func mapHeaders(_ headers: [String]) -> [String: Int] {
        var map: [String: Int] = [:]
        
        for (index, header) in headers.enumerated() {
            let trimmed = header.trimmingCharacters(in: .whitespaces)
            
            if nameKeywords.contains(where: { trimmed.contains($0) }) {
                map["name"] = index
            } else if phoneKeywords.contains(where: { trimmed.contains($0) }) {
                map["phone"] = index
            } else if emailKeywords.contains(where: { trimmed.contains($0) }) {
                map["email"] = index
            } else if companyKeywords.contains(where: { trimmed.contains($0) }) {
                map["company"] = index
            } else if titleKeywords.contains(where: { trimmed.contains($0) }) {
                map["title"] = index
            }
        }
        
        return map
    }
    
    // Deduplicate contacts by name + normalized phone
    private func deduplicateContacts(_ contacts: [ContactRecord]) -> [ContactRecord] {
        var seen = Set<String>()
        var deduped: [ContactRecord] = []
        
        for contact in contacts {
            if !seen.contains(contact.dedupeKey) {
                seen.insert(contact.dedupeKey)
                deduped.append(contact)
            }
        }
        
        return deduped
    }
}
