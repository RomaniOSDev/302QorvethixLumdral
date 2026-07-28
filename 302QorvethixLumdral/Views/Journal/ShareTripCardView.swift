import SwiftUI

struct ShareTripCardView: View {
    let trip: Trip

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location.north.line.fill")
                    .foregroundStyle(Color("AppAccent"))
                Text("TRIP LOG")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
                Spacer()
                if trip.visited {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color("AppPrimary"))
                }
            }

            Text(trip.destination.uppercased())
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(trip.country)
                .font(.title3)
                .foregroundStyle(Color("AppPrimary"))

            Text(dateFormatter.string(from: trip.date))
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Color("AppTextSecondary"))

            if !trip.note.isEmpty {
                Text(trip.note)
                    .font(.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(4)
            }

            if trip.budgetTotal > 0 {
                Text(BudgetFormat.string(trip.budgetTotal))
                    .font(.system(.headline, design: .monospaced).weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
            }

            Spacer(minLength: 0)

            Text("Logged in journal")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("AppTextSecondary").opacity(0.7))
        }
        .padding(24)
        .frame(width: 320, height: 420, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color("AppSurface"), Color("AppBackground")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color("AppTextSecondary").opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

enum TripShareHelper {
    @MainActor
    static func renderImage(for trip: Trip) -> UIImage? {
        let view = ShareTripCardView(trip: trip)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
