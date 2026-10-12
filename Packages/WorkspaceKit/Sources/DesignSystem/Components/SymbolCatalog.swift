import Foundation

/// A curated set of SF Symbols for the appearance picker, with search keywords.
nonisolated public enum SymbolCatalog {
    /// A symbol and the words it can be found by.
    public struct Entry: Hashable, Sendable, Identifiable {
        public let name: String
        public let keywords: [String]
        public var id: String { name }
    }

    /// All selectable symbols.
    public static let entries: [Entry] = rawEntries.map { Entry(name: $0.0, keywords: $0.1.split(separator: " ").map(String.init)) }

    private static let rawEntries: [(String, String)] = [
        ("hammer.fill", "build tool code"), ("wrench.and.screwdriver.fill", "tools fix repair"),
        ("checkmark.seal.fill", "test verify approve"), ("paintbrush.pointed.fill", "design paint art"),
        ("gearshape.2.fill", "settings ops operations"), ("star.fill", "favourite priority"),
        ("flag.fill", "flag milestone"), ("bolt.fill", "fast energy power"), ("flame.fill", "hot urgent fire"),
        ("sparkles", "magic ai assistant"), ("lightbulb.fill", "idea think"), ("brain.head.profile", "think plan"),
        ("ladybug.fill", "bug debug"), ("ant.fill", "bug insect"), ("curlybraces", "code json"),
        ("chevron.left.forwardslash.chevron.right", "code html markup"), ("terminal.fill", "terminal shell cli"),
        ("server.rack", "server backend infra"), ("cloud.fill", "cloud sync"), ("icloud.and.arrow.up.fill", "upload deploy"),
        ("network", "network api web"), ("globe", "web internet world"), ("link", "link url"),
        ("lock.fill", "security lock privacy"), ("key.fill", "key password auth"), ("shield.lefthalf.filled", "security shield"),
        ("cpu.fill", "chip performance"), ("memorychip.fill", "memory ram"), ("speedometer", "performance speed"),
        ("gauge.with.dots.needle.67percent", "metrics gauge"), ("chart.bar.fill", "chart analytics stats"),
        ("chart.line.uptrend.xyaxis", "growth chart trend"), ("chart.pie.fill", "pie chart"),
        ("doc.text.fill", "document text"), ("doc.on.doc.fill", "copy documents"), ("folder.fill", "folder files"),
        ("archivebox.fill", "archive box"), ("tray.full.fill", "inbox tray"), ("paperplane.fill", "send ship release"),
        ("envelope.fill", "email mail"), ("bubble.left.and.bubble.right.fill", "chat discuss feedback"),
        ("phone.fill", "call phone"), ("video.fill", "video meeting"), ("person.fill", "person user"),
        ("person.2.fill", "team people"), ("person.3.fill", "group team"), ("figure.walk", "accessibility walk"),
        ("accessibility", "accessibility a11y"), ("hand.raised.fill", "hand stop raise"), ("hand.thumbsup.fill", "approve like"),
        ("eye.fill", "review look watch"), ("magnifyingglass", "search find audit"), ("calendar", "calendar date schedule"),
        ("clock.fill", "time clock"), ("alarm.fill", "alarm reminder"), ("timer", "timer countdown"),
        ("hourglass", "wait time"), ("bell.fill", "notification bell"), ("pin.fill", "pin"),
        ("bookmark.fill", "bookmark save"), ("tag.fill", "tag label"), ("list.bullet", "list items"),
        ("checklist", "checklist todo"), ("square.grid.2x2.fill", "grid layout"), ("rectangle.split.3x1.fill", "board columns"),
        ("iphone", "iphone mobile device"), ("ipad", "ipad tablet"), ("laptopcomputer", "laptop mac"),
        ("desktopcomputer", "desktop computer"), ("applewatch", "watch"), ("keyboard.fill", "keyboard type"),
        ("printer.fill", "print"), ("camera.fill", "camera photo"), ("photo.fill", "photo image"),
        ("music.note", "music audio"), ("mic.fill", "microphone voice"), ("speaker.wave.2.fill", "sound speaker"),
        ("film.fill", "film movie"), ("book.fill", "book docs read"), ("graduationcap.fill", "learn study"),
        ("pencil", "edit write"), ("scissors", "cut trim"), ("ruler.fill", "measure ruler"),
        ("paintpalette.fill", "palette colour"), ("wand.and.stars", "magic polish"), ("cube.fill", "cube 3d package"),
        ("shippingbox.fill", "package box ship"), ("cart.fill", "cart shop"), ("creditcard.fill", "payment card"),
        ("banknote.fill", "money finance"), ("gift.fill", "gift present"), ("trophy.fill", "trophy win award"),
        ("rosette", "award badge"), ("target", "goal target"), ("scope", "focus scope"),
        ("map.fill", "map plan route"), ("location.fill", "location"), ("airplane", "travel flight launch"),
        ("car.fill", "car drive"), ("tram.fill", "transit"), ("house.fill", "home house"),
        ("building.2.fill", "office company"), ("leaf.fill", "eco nature"), ("sun.max.fill", "sun day"),
        ("moon.fill", "night moon"), ("cloud.rain.fill", "weather rain"), ("snowflake", "freeze cold"),
        ("drop.fill", "water drop"), ("heart.fill", "health love"), ("cross.case.fill", "first aid health"),
        ("pills.fill", "medicine"), ("dumbbell.fill", "fitness gym"), ("sportscourt.fill", "sport"),
        ("gamecontroller.fill", "game play"), ("puzzlepiece.fill", "puzzle extension plugin"), ("cup.and.saucer.fill", "coffee break"),
        ("fork.knife", "food lunch"), ("arrow.triangle.2.circlepath", "sync refresh repeat"),
        ("arrow.uturn.backward", "undo revert"), ("arrow.up.right", "launch open"), ("trash.fill", "delete trash"),
    ]

    /// Symbols whose name or keywords contain `query`.
    public static func search(_ query: String) -> [Entry] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return entries }
        return entries.filter { entry in
            entry.name.contains(query) || entry.keywords.contains { $0.hasPrefix(query) }
        }
    }

    /// A spoken name for a symbol, e.g. "paintbrush pointed" for `paintbrush.pointed.fill`.
    public static func spokenName(for symbol: String) -> String {
        symbol.split(separator: ".").filter { $0 != "fill" }.joined(separator: " ")
    }
}
