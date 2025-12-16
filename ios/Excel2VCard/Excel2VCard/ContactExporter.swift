import Foundation
import Contacts
import ContactsUI

enum ExportError: LocalizedError {
    case vcfGenerationFailed
    case contactsPermissionDenied
    case contactsSaveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .vcfGenerationFailed:
            return "生成VCF文件失败"
        case .contactsPermissionDenied:
            return "没有访问通讯录的权限"
        case .contactsSaveFailed(let message):
            return "保存到通讯录失败：\(message)"
        }
    }
}

class ContactExporter {
    
    // Generate VCF data from contacts
    func generateVCF(contacts: [ContactRecord]) throws -> Data {
        var cnContacts: [CNContact] = []
        
        for contact in contacts {
            let cnContact = CNMutableContact()
            
            // Name
            let nameParts = contact.name.components(separatedBy: " ")
            if nameParts.count >= 2 {
                cnContact.familyName = nameParts[0]
                cnContact.givenName = nameParts.dropFirst().joined(separator: " ")
            } else {
                cnContact.givenName = contact.name
            }
            
            // Phone
            if let phone = contact.phone, !phone.isEmpty {
                let phoneNumber = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone))
                cnContact.phoneNumbers = [phoneNumber]
            }
            
            // Email
            if let email = contact.email, !email.isEmpty {
                let emailAddress = CNLabeledValue(label: CNLabelHome, value: email as NSString)
                cnContact.emailAddresses = [emailAddress]
            }
            
            // Company
            if let company = contact.company, !company.isEmpty {
                cnContact.organizationName = company
            }
            
            // Title
            if let title = contact.title, !title.isEmpty {
                cnContact.jobTitle = title
            }
            
            cnContacts.append(cnContact.copy() as! CNContact)
        }
        
        // Generate VCF data
        guard let vcfData = try? CNContactVCardSerialization.data(with: cnContacts) else {
            throw ExportError.vcfGenerationFailed
        }
        
        return vcfData
    }
    
    // Request contacts permission
    func requestContactsPermission() async -> Bool {
        let store = CNContactStore()
        
        do {
            let granted = try await store.requestAccess(for: .contacts)
            return granted
        } catch {
            return false
        }
    }
    
    // Write contacts directly to Contacts app
    func writeToContacts(contacts: [ContactRecord]) async throws {
        let store = CNContactStore()
        
        // Check permission
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status != .authorized {
            let granted = await requestContactsPermission()
            if !granted {
                throw ExportError.contactsPermissionDenied
            }
        }
        
        // Save contacts
        let saveRequest = CNSaveRequest()
        
        for contact in contacts {
            let cnContact = CNMutableContact()
            
            // Name
            let nameParts = contact.name.components(separatedBy: " ")
            if nameParts.count >= 2 {
                cnContact.familyName = nameParts[0]
                cnContact.givenName = nameParts.dropFirst().joined(separator: " ")
            } else {
                cnContact.givenName = contact.name
            }
            
            // Phone
            if let phone = contact.phone, !phone.isEmpty {
                let phoneNumber = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone))
                cnContact.phoneNumbers = [phoneNumber]
            }
            
            // Email
            if let email = contact.email, !email.isEmpty {
                let emailAddress = CNLabeledValue(label: CNLabelHome, value: email as NSString)
                cnContact.emailAddresses = [emailAddress]
            }
            
            // Company
            if let company = contact.company, !company.isEmpty {
                cnContact.organizationName = company
            }
            
            // Title
            if let title = contact.title, !title.isEmpty {
                cnContact.jobTitle = title
            }
            
            saveRequest.add(cnContact, toContainerWithIdentifier: nil)
        }
        
        do {
            try store.execute(saveRequest)
        } catch {
            throw ExportError.contactsSaveFailed(error.localizedDescription)
        }
    }
}
