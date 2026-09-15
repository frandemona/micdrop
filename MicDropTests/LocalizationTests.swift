import Foundation
import Testing
@testable import MicDrop

@Suite struct LocalizationTests {
    @Test(arguments: ["es", "fr", "de", "it", "pt-BR", "ja", "zh-Hans", "ko"])
    func languageIsBundledAndTranslated(_ language: String) throws {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        #expect(bundle.localizedString(forKey: "Microphone ON", value: nil, table: nil) != "Microphone ON")
        #expect(bundle.localizedString(forKey: "Can't mute: %@", value: nil, table: nil).contains("%@"))
    }
}
