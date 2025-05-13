import SwiftUI
import PDFKit
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Main App Entry
@main
struct ImageToPDFConverterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var viewModel = ImageToPDFViewModel()
    @State private var showDocumentPicker = false
    @State private var showFileExporter = false
    @State private var pdfDocument: PDFDocument?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main Content Area
                if viewModel.images.isEmpty {
                    emptyStateView
                } else {
                    imageGridView
                }
                
                // Footer Controls
                footerControls
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showImagePicker) {
                ImagePicker(images: $viewModel.images, selectionLimit: 20)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(images: $viewModel.images)
            }
            .fileExporter(
                isPresented: $showFileExporter,
                document: pdfDocument,
                contentType: .pdf,
                defaultFilename: "Images.pdf"
            ) { result in
                switch result {
                case .success(let url):
                    viewModel.showAlert(title: "Success", message: "PDF saved successfully")
                case .failure(let error):
                    viewModel.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
            .alert(item: $viewModel.alertItem) { item in
                Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("OK")))
            }
            .confirmationDialog("Add Images", isPresented: $viewModel.showAddMenu) {
                Button("Take Photo") {
                    viewModel.sourceType = .camera
                    viewModel.checkCameraPermission()
                }
                Button("Choose from Library") {
                    viewModel.sourceType = .photoLibrary
                    viewModel.showImagePicker = true
                }
                Button("Import Files") {
                    showDocumentPicker = true
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Image to PDF")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: viewModel.showAddMenu) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            if !viewModel.images.isEmpty {
                HStack {
                    Text("\(viewModel.images.count) image(s) selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Clear All") {
                        viewModel.images.removeAll()
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
        .background(Color(.systemBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .opacity(0.5)
            
            Text("No Images Selected")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text("Tap the + button to add images from your library or take new photos")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: viewModel.showAddMenu) {
                Text("Add Images")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 30)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var imageGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), GridItem(.adaptive(minimum: 120))], spacing: 2) {
                ForEach(viewModel.images.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: viewModel.images[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 180)
                            .clipped()
                            .cornerRadius(4)
                            .shadow(radius: 2)
                        
                        Button(action: {
                            viewModel.images.remove(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(5)
                    }
                    .contextMenu {
                        Button {
                            viewModel.moveImageToFront(index: index)
                        } label: {
                            Label("Move to Front", systemImage: "arrow.up.to.line")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.images.remove(at: index)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.top, 10)
        }
    }
    
    private var footerControls: some View {
        VStack(spacing: 0) {
            Divider()
            
            if !viewModel.images.isEmpty {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        Button(action: {
                            viewModel.showSortOptions = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text("Sort")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            viewModel.showPageSizeOptions = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait")
                                Text("Page Size")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        pdfDocument = viewModel.generatePDF()
                        showFileExporter = true
                    }) {
                        HStack {
                            Image(systemName: "doc.plaintext")
                            Text("Generate PDF")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 15)
                .background(Color(.systemBackground))
                .confirmationDialog("Sort Images", isPresented: $viewModel.showSortOptions) {
                    Button("Oldest First") { viewModel.sortImages(by: .ascending) }
                    Button("Newest First") { viewModel.sortImages(by: .descending) }
                    Button("Cancel", role: .cancel) { }
                }
                .confirmationDialog("Page Size", isPresented: $viewModel.showPageSizeOptions) {
                    ForEach(PageSize.allCases, id: \.self) { size in
                        Button(size.rawValue) { viewModel.selectedPageSize = size }
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
        }
    }
}

// MARK: - View Model
class ImageToPDFViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    @Published var showImagePicker = false
    @Published var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Published var showAddMenu = false
    @Published var showSortOptions = false
    @Published var showPageSizeOptions = false
    @Published var selectedPageSize: PageSize = .a4
    @Published var alertItem: AlertItem?
    
    struct AlertItem: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    func showAlert(title: String, message: String) {
        alertItem = AlertItem(title: title, message: message)
    }
    
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showImagePicker = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showImagePicker = true
                    } else {
                        self.showAlert(title: "Camera Access Denied", message: "Please enable camera access in Settings to take photos.")
                    }
                }
            }
        case .denied, .restricted:
            showAlert(title: "Camera Access Denied", message: "Please enable camera access in Settings to take photos.")
        @unknown default:
            break
        }
    }
    
    func sortImages(by sortOrder: SortOrder) {
        // In a real app, you would sort based on creation date from PHAsset
        // For this example, we'll just reverse the array for demonstration
        if sortOrder == .descending {
            images.reverse()
        }
    }
    
    func moveImageToFront(index: Int) {
        guard images.indices.contains(index) else { return }
        let image = images.remove(at: index)
        images.insert(image, at: 0)
    }
    
    func generatePDF() -> PDFDocument {
        let pdfDocument = PDFDocument()
        let pageRect: CGRect
        
        switch selectedPageSize {
        case .a4:
            pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 at 72 dpi
        case .letter:
            pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter at 72 dpi
        case .auto:
            // Use the largest image size as page size
            let maxWidth = images.map { $0.size.width }.max() ?? 595.2
            let maxHeight = images.map { $0.size.height }.max() ?? 841.8
            pageRect = CGRect(x: 0, y: 0, width: maxWidth, height: maxHeight)
        }
        
        for image in images {
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
            let data = renderer.pdfData { context in
                context.beginPage()
                
                // Calculate aspect fit rect
                let imageAspect = image.size.width / image.size.height
                let pageAspect = pageRect.width / pageRect.height
                
                let drawingRect: CGRect
                
                if imageAspect > pageAspect {
                    // Image is wider than page
                    let height = pageRect.width / imageAspect
                    drawingRect = CGRect(
                        x: 0,
                        y: (pageRect.height - height) / 2,
                        width: pageRect.width,
                        height: height
                    )
                } else {
                    // Image is taller than page
                    let width = pageRect.height * imageAspect
                    drawingRect = CGRect(
                        x: (pageRect.width - width) / 2,
                        y: 0,
                        width: width,
                        height: pageRect.height
                    )
                }
                
                image.draw(in: drawingRect)
            }
            
            if let pdfPage = PDFPage(data: data) {
                pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
            }
        }
        
        return pdfDocument
    }
}

// MARK: - Enums
enum PageSize: String, CaseIterable {
    case a4 = "A4"
    case letter = "US Letter"
    case auto = "Auto (Image Size)"
}

enum SortOrder {
    case ascending
    case descending
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    var selectionLimit: Int
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = selectionLimit
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            let group = DispatchGroup()
            var newImages = [UIImage]()
            
            for result in results {
                group.enter()
                
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        if let image = image as? UIImage {
                            newImages.append(image)
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.parent.images.append(contentsOf: newImages)
            }
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                if let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.parent.images.append(image)
                    }
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
