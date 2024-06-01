//
//  GalleryView.swift
//  Machine Security System
//
//  Created by Almahdi Morris on 31/5/24.
//
import SwiftUI
import QuickLook

struct GalleryView: View {
    @ObservedObject var viewModel = GalleryViewModel()
    @State private var isPreviewing = false
    @State private var isShowingVideo = false
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    viewModel.selectFiles()
                }) {
                    Label("Add Files", systemImage: "plus")
                }
                .padding()
                
                Spacer()
                
                Picker("Sort by", selection: $viewModel.sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
            }
            
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                        ForEach(viewModel.sortedFiles.indices, id: \.self) { index in
                            VStack {
                                if let image = viewModel.sortedFiles[index].previewImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(height: 100)
                                }
                                Text(viewModel.sortedFiles[index].name)
                                    .font(.caption)
                            }
                            .background(viewModel.sortedFiles[index].type == .video ? Color.blue.opacity(0.3) : Color.green.opacity(0.3))
                            .cornerRadius(10)
                            .onTapGesture {
                                if viewModel.sortedFiles[index].type == .video {
                                    viewModel.selectedVideoURL = viewModel.sortedFiles[index].url
                                    isShowingVideo = true
                                } else {
                                    viewModel.previewFile(at: index)
                                    isPreviewing = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Gallery")
        .onAppear {
            viewModel.loadFiles()
        }
        .fullScreenCover(isPresented: $isPreviewing) {
            if let index = viewModel.previewFileIndex {
                QLPreviewControllerWrapper(files: viewModel.files, currentIndex: index)
            }
        }
        .fullScreenCover(isPresented: $isShowingVideo) {
            if let videoURL = viewModel.selectedVideoURL {
                VideoViewControllerWrapper(videoURL: $viewModel.selectedVideoURL)
            }
        }
    }
}

struct QLPreviewControllerWrapper: UIViewControllerRepresentable {
    var files: [MediaFile]
    var currentIndex: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        previewController.currentPreviewItemIndex = currentIndex
        return previewController
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // No updates needed
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        var parent: QLPreviewControllerWrapper

        init(_ parent: QLPreviewControllerWrapper) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return parent.files.count
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.files[index].url as QLPreviewItem
        }
    }
}
