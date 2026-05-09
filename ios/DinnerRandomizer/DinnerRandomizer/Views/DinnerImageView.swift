import SwiftUI

struct DinnerImageView: View {
    let url: URL?
    let title: String

    var body: some View {
        GeometryReader { geometry in
            if
                let url,
                let image = UIImage(contentsOfFile: url.path)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .accessibilityLabel(title)
            } else {
                ZStack {
                    Color(.secondarySystemGroupedBackground)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .accessibilityLabel(title)
            }
        }
        .aspectRatio(1.9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
