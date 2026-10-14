import Foundation

/// Prints the HERON title with a left-to-right color gradient.
/// The art is stored inside the code, so it works on any Mac.
/// No figlet or lolcat needed.
enum Banner {

    // The title art. To change it, replace these lines.
    private static let art = [
        "  ▓▓   ▒▓░ ▓▓▓▓▓▓▓ ░▓▓▓▓▓▓▒  ░▓▓▓▓▓▒  ░▓▓░  ▓▓",
        "  ██   ▒█░ ▓█░     ░█▒   ██ ░█▓   ░██ ░███░ ▓█",
        "  ██▓▓▓██░ ▓█▓▓▓▓▒ ░██▓██▓░ ▒█▒    ▓█░░█▒▓█▒▓█",
        "  ██   ▒█░ ▓█░     ░█▒ ░▓█░ ░█▓░  ▒█▓ ░█▒ ▒███",
        "  ▓▓   ▒▓░ ▒▓▓▓▓▓▓░░▓▒   ▒▓░ ░▒▓▓▓▓▒  ░▓░  ░▓▓"
    ]

    private static let tagline = "  fast concurrent link checker — By: Akar Jaza"

    private static let stops: [(r: Double, g: Double, b: Double)] = [
        (80, 170, 255),
        (110, 255, 170),
        (190, 255, 70),
        (245, 170, 50)
    ]

    private static func color(at t: Double) -> (r: Int, g: Int, b: Int) {
        let scaled = t * Double(stops.count - 1)
        let i = min(Int(scaled), stops.count - 2)
        let f = scaled - Double(i)
        let a = stops[i]
        let b = stops[i + 1]
        return (
            Int(a.r + (b.r - a.r) * f),
            Int(a.g + (b.g - a.g) * f),
            Int(a.b + (b.b - a.b) * f)
        )
    }

    private static func escape(for c: (r: Int, g: Int, b: Int)) -> String {
        let colorTerm = ProcessInfo.processInfo.environment["COLORTERM"] ?? ""

        if colorTerm == "truecolor" || colorTerm == "24bit" {
            return "\u{1B}[38;2;\(c.r);\(c.g);\(c.b)m"
        }

        let code = 16 + 36 * (c.r * 5 / 255) + 6 * (c.g * 5 / 255) + (c.b * 5 / 255)
        return "\u{1B}[38;5;\(code)m"
    }

    static func show() {
        let env = ProcessInfo.processInfo.environment

        let useColor = isatty(STDOUT_FILENO) == 1 && env["NO_COLOR"] == nil

        let width = art.map { $0.count }.max() ?? 1

        print()
        for line in art {
            guard useColor else {
                print(line)
                continue
            }

            var out = ""
            for (column, char) in line.enumerated() {
                if char == " " {
                    out.append(" ")
                    continue
                }
                let t = Double(column) / Double(max(width - 1, 1))
                out += escape(for: color(at: t)) + String(char)
            }
            print(out + "\u{1B}[0m")
        }

        print(useColor ? "\u{1B}[2m\(tagline)\u{1B}[0m" : tagline)
        print()
    }
}
