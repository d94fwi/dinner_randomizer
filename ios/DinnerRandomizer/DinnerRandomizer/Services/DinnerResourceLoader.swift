import Foundation
import UIKit

enum DinnerResourceError: LocalizedError {
    case missingDinnerData
    case unreadableImagePath(String)

    var errorDescription: String? {
        switch self {
        case .missingDinnerData:
            return "Could not find data/dinners.json in the app bundle."
        case .unreadableImagePath(let path):
            return "Could not find bundled image at \(path)."
        }
    }
}

struct DinnerResourceLoader {
    let bundle: Bundle
    private let fileManager: FileManager

    init(bundle: Bundle = .main, fileManager: FileManager = .default) {
        self.bundle = bundle
        self.fileManager = fileManager
    }

    func loadDinners() throws -> [Dinner] {
        guard let url = bundle.url(forResource: "dinners", withExtension: "json", subdirectory: "data") else {
            throw DinnerResourceError.missingDinnerData
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Dinner].self, from: data)
    }

    func imageURL(for path: String?) -> URL? {
        if
            let path,
            let url = resourceURL(for: path)
        {
            return url
        }

        return fallbackImageURL()
    }

    func image(for path: String?) -> UIImage? {
        guard let url = imageURL(for: path) else {
            return nil
        }

        return UIImage(contentsOfFile: url.path)
    }

    func requireImageURL(for path: String) throws -> URL {
        guard let url = resourceURL(for: path) else {
            throw DinnerResourceError.unreadableImagePath(path)
        }

        return url
    }

    private func resourceURL(for path: String) -> URL? {
        let cleanedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !cleanedPath.isEmpty,
            !cleanedPath.hasPrefix("/"),
            !cleanedPath.contains("://"),
            let resourceURL = bundle.resourceURL
        else {
            return nil
        }

        let url = resourceURL.appendingPathComponent(cleanedPath)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    private func fallbackImageURL() -> URL? {
        guard let resourceURL = bundle.resourceURL else {
            return nil
        }

        let url = resourceURL.appendingPathComponent("assets/dinner-table.jpg")
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
}
