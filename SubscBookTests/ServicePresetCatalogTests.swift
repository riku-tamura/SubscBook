import Foundation
import Testing
@testable import SubscBook

@Suite("サービス名の候補")
struct ServicePresetCatalogTests {
    @Test("英字は大文字小文字・全角半角を区別しない", arguments: ["net", "NET", "ｎｅｔ", "Ｎｅｔ"])
    func caseAndWidthInsensitive(query: String) {
        #expect(ServicePresetCatalog.suggestions(for: query).map(\.name).contains("Netflix"))
    }

    @Test("読みはひらがな・カタカナどちらでも引ける", arguments: ["ねっとふ", "ネットフ"])
    func kanaInsensitive(query: String) {
        #expect(ServicePresetCatalog.suggestions(for: query).first?.name == "Netflix")
    }

    @Test("前方一致を部分一致より先に並べる")
    func prefixFirst() {
        let names = ServicePresetCatalog.suggestions(for: "music", limit: 10).map(\.name)
        let appleMusic = names.firstIndex(of: "Apple Music")
        let youTubeMusic = names.firstIndex(of: "YouTube Music Premium")
        #expect(appleMusic != nil && youTubeMusic != nil)
        #expect(ServicePresetCatalog.suggestions(for: "you").first?.name.hasPrefix("YouTube") == true)
    }

    @Test("件数の上限")
    func limit() {
        #expect(ServicePresetCatalog.suggestions(for: "a", limit: 3).count == 3)
    }

    @Test("空文字・完全一致は候補を出さない")
    func emptyAndExactMatch() {
        #expect(ServicePresetCatalog.suggestions(for: "").isEmpty)
        #expect(ServicePresetCatalog.suggestions(for: "   ").isEmpty)
        #expect(!ServicePresetCatalog.suggestions(for: "Netflix").map(\.name).contains("Netflix"))
    }

    @Test("表記ゆれを吸収して完全一致のプリセットを探す")
    func presetNamed() {
        #expect(ServicePresetCatalog.preset(named: "netflix")?.category == .video)
        #expect(ServicePresetCatalog.preset(named: "Ｓｐｏｔｉｆｙ")?.category == .music)
        #expect(ServicePresetCatalog.preset(named: "知らないサービス") == nil)
    }

    @Test("プリセット名は重複しない")
    func uniqueNames() {
        let names = ServicePresetCatalog.all.map { ServicePresetCatalog.normalize($0.name) }
        #expect(Set(names).count == names.count)
    }
}
