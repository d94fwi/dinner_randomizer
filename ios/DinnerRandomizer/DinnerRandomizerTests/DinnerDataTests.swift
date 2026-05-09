import XCTest
@testable import DinnerRandomizer

final class DinnerDataTests: XCTestCase {
    private var loader: DinnerResourceLoader {
        DinnerResourceLoader(bundle: Bundle.main)
    }

    func testBundledDinnerDataDecodes() throws {
        let dinners = try loader.loadDinners()
        XCTAssertEqual(dinners.count, 100)
    }

    func testDinnerIdsAreUnique() throws {
        let dinners = try loader.loadDinners()
        let ids = dinners.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testEveryDinnerHasABundledImage() throws {
        let dinners = try loader.loadDinners()
        let missingImages = dinners.filter { ($0.image ?? "").isEmpty }
        XCTAssertTrue(missingImages.isEmpty, "Missing image fields: \(missingImages.map(\.id))")

        let missingFiles = dinners.compactMap { dinner -> String? in
            guard let image = dinner.image else {
                return dinner.id
            }

            return (try? loader.requireImageURL(for: image)) == nil ? dinner.id : nil
        }

        XCTAssertTrue(missingFiles.isEmpty, "Missing image files: \(missingFiles)")
    }

    func testTranslationsAreComplete() throws {
        let dinners = try loader.loadDinners()

        for language in [AppLanguage.sv, .no, .pl] {
            let incomplete = dinners.filter { dinner in
                guard let translation = dinner.translations?[language.rawValue] else {
                    return true
                }

                return translation.name?.isEmpty != false ||
                    translation.description?.isEmpty != false ||
                    translation.mainIngredients?.isEmpty != false ||
                    translation.notes == nil
            }

            XCTAssertTrue(incomplete.isEmpty, "Incomplete \(language.rawValue) translations: \(incomplete.map(\.id))")
        }
    }
}
