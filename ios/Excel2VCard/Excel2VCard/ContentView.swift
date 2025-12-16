import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var contacts: [ContactRecord] = []
    @State private var originalCount: Int = 0
    @State private var showingDocumentPicker = false
    @State private var showingShareSheet = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var vcfData: Data?
    @State private var isProcessing = false
    
    let parser = ExcelParser()
    let exporter = ContactExporter()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if contacts.isEmpty {
                    // Initial state - file selection
                    VStack(spacing: 30) {
                        Image(systemName: "doc.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 10) {
                            Text("Excel转VCF工具")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("将Excel或CSV联系人转换为VCF格式")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📋 使用说明：")
                                .font(.headline)
                            Text("1. 点击下方按钮选择文件（.xlsx 或 .csv）")
                            Text("2. 自动识别姓名、电话等字段")
                            Text("3. 预览并导出联系人")
                            Text("4. 可直接写入通讯录或分享VCF文件")
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        Button(action: {
                            showingDocumentPicker = true
                        }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                Text("选择文件")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                } else {
                    // Preview state - show contacts
                    VStack(spacing: 15) {
                        // Header with counts
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("联系人预览")
                                    .font(.headline)
                                Text("总数：\(originalCount) → 去重后：\(contacts.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("重新选择") {
                                resetState()
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Contact list
                        List(contacts) { contact in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(contact.name)
                                    .font(.headline)
                                
                                if let phone = contact.phone {
                                    HStack {
                                        Image(systemName: "phone.fill")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text(phone)
                                            .font(.subheadline)
                                    }
                                }
                                
                                if let email = contact.email {
                                    HStack {
                                        Image(systemName: "envelope.fill")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text(email)
                                            .font(.subheadline)
                                    }
                                }
                                
                                if let company = contact.company {
                                    HStack {
                                        Image(systemName: "building.2.fill")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text(company)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                exportAsVCF()
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("分享VCF文件")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isProcessing)
                            
                            Button(action: {
                                writeToContactsApp()
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                    Text("直接写入通讯录")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isProcessing)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Excel2VCard")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(onFileSelected: handleFileSelection)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = vcfData {
                    ShareSheet(items: [data.temporaryFileURL()])
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    func handleFileSelection(_ url: URL) {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileExtension = url.pathExtension.lowercased()
                var parsedContacts: [ContactRecord] = []
                
                if fileExtension == "xlsx" {
                    parsedContacts = try parser.parseXLSX(url: url)
                } else if fileExtension == "csv" {
                    parsedContacts = try parser.parseCSV(url: url)
                } else {
                    throw ParserError.readFailed("不支持的文件格式")
                }
                
                DispatchQueue.main.async {
                    self.originalCount = parsedContacts.count // Before deduplication count is already deduped in parser
                    self.contacts = parsedContacts
                    self.isProcessing = false
                    
                    if parsedContacts.isEmpty {
                        showAlert(title: "提示", message: "文件中没有找到有效的联系人数据")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    showAlert(title: "错误", message: error.localizedDescription)
                }
            }
        }
    }
    
    func exportAsVCF() {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try exporter.generateVCF(contacts: contacts)
                
                DispatchQueue.main.async {
                    self.vcfData = data
                    self.isProcessing = false
                    self.showingShareSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    showAlert(title: "导出失败", message: error.localizedDescription)
                }
            }
        }
    }
    
    func writeToContactsApp() {
        isProcessing = true
        
        Task {
            do {
                try await exporter.writeToContacts(contacts: contacts)
                
                await MainActor.run {
                    isProcessing = false
                    showAlert(title: "成功", message: "已成功写入 \(contacts.count) 个联系人到通讯录")
                    resetState()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    showAlert(title: "写入失败", message: error.localizedDescription)
                }
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    func resetState() {
        contacts = []
        originalCount = 0
        vcfData = nil
    }
}

// Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onFileSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType(filenameExtension: "xlsx")!,
            UTType(filenameExtension: "csv")!
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onFileSelected: onFileSelected)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFileSelected: (URL) -> Void
        
        init(onFileSelected: @escaping (URL) -> Void) {
            self.onFileSelected = onFileSelected
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Access security-scoped resource
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            onFileSelected(url)
        }
    }
}

// Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Helper extension to create temporary file URL
extension Data {
    func temporaryFileURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "contacts-\(Date().timeIntervalSince1970).vcf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try? write(to: fileURL)
        
        return fileURL
    }
}
