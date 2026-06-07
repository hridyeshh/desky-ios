import SwiftUI
import PhotosUI

/// Horizontal GIF gallery: pick GIFs from Photos, upload to the backend
/// (Cloudinary), and drag thumbnails onto screen slots.
struct GIFGalleryView: View {
    var viewModel: DeskViewModel

    @State private var pickerItem: PhotosPickerItem?
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("GIF GALLERY")
                    .font(.pressStart(8))
                    .foregroundColor(Theme.muted)
                Spacer()
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("ADD GIF")
                            .font(.pressStart(6))
                    }
                    .foregroundColor(Theme.amber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.amber.opacity(0.4), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 16)

            if let errorText {
                Text(errorText)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.pink)
                    .padding(.horizontal, 16)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if viewModel.isUploading {
                        uploadingCard
                    }
                    ForEach(viewModel.uploadedGifs, id: \.self) { url in
                        GIFThumbnailCard(url: url, onRemove: {
                            viewModel.removeGif(url: url)
                        })
                        .onDrag { NSItemProvider(object: url as NSString) }
                    }
                    if viewModel.uploadedGifs.isEmpty && !viewModel.isUploading {
                        emptyHint
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }

            Text("↑ DRAG A GIF ONTO A SCREEN SLOT")
                .font(.pressStart(6))
                .foregroundColor(Theme.dim)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await handlePick(newItem) }
        }
    }

    // MARK: - Pick handling

    private func handlePick(_ item: PhotosPickerItem) async {
        errorText = nil
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            errorText = "Could not read selected file"
            return
        }
        // Validate GIF magic bytes.
        let header = data.prefix(6)
        let gif87 = Data("GIF87a".utf8)
        let gif89 = Data("GIF89a".utf8)
        guard header == gif87 || header == gif89 else {
            errorText = "Selected file is not a GIF"
            return
        }
        await viewModel.uploadGif(data: data)
        pickerItem = nil
    }

    // MARK: - Subviews

    private var uploadingCard: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Theme.card)
            .frame(width: 84, height: 84)
            .overlay(ProgressView().tint(Theme.amber))
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1)
            )
    }

    private var emptyHint: some View {
        Text("No GIFs yet — tap ADD GIF")
            .font(.system(size: 11))
            .foregroundColor(Theme.dim)
            .frame(height: 84)
    }
}

/// A single GIF thumbnail loaded from a remote URL (first frame via AsyncImage).
struct GIFThumbnailCard: View {
    let url: String
    var onRemove: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(Theme.dim)
                default:
                    ProgressView().tint(Theme.muted)
                }
            }
            .frame(width: 84, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("GIF")
                .font(.pressStart(5))
                .foregroundColor(Theme.fg)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Theme.bg.opacity(0.8))
                .padding(5)
        }
        .frame(width: 84, height: 84)
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(Theme.purple.opacity(0.5), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.fg)
                        .padding(4)
                        .background(Theme.pink, in: Circle())
                }
                .buttonStyle(.plain)
                .offset(x: 5, y: -5)
            }
        }
    }
}
