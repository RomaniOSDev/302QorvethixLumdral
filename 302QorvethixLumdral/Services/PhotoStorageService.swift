import UIKit

enum PhotoStorageService {
    private static var root: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TripPhotos", isDirectory: true)
    }

    static func directory(for tripId: String) -> URL {
        let dir = root.appendingPathComponent(tripId, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func save(data: Data, tripId: String) -> String? {
        guard let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.72) else { return nil }
        let name = UUID().uuidString + ".jpg"
        let url = directory(for: tripId).appendingPathComponent(name)
        do {
            try jpeg.write(to: url, options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func load(tripId: String, fileName: String) -> UIImage? {
        let url = directory(for: tripId).appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(tripId: String, fileName: String) {
        let url = directory(for: tripId).appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    static func deleteAll(tripId: String) {
        let dir = root.appendingPathComponent(tripId, isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
    }
}
