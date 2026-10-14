import Foundation
import Darwin

enum Menu {

    static func choose(_ question: String, options: [String]) -> Int {
        var original = termios()

        guard isatty(STDIN_FILENO) == 1, tcgetattr(STDIN_FILENO, &original) == 0 else {
            return fallback(question, options)
        }

        var raw = original
        raw.c_lflag &= ~tcflag_t(ICANON | ECHO | ISIG)
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        print("\u{1B}[?25l", terminator: "")

        func restore() {
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
            print("\u{1B}[?25h", terminator: "")
            fflush(stdout)
        }

        var selected = 0

        func draw() {
            for (i, option) in options.enumerated() {
                let line = i == selected
                    ? "\u{1B}[1;36m  ▶ \(option)\u{1B}[0m"
                    : "    \u{1B}[2m\(option)\u{1B}[0m"
                print("\u{1B}[2K\r" + line)
            }
            fflush(stdout)
        }

        func redraw() {
            print("\u{1B}[\(options.count)A", terminator: "")
            draw()
        }

        print(question)
        draw()

        while true {
            switch readKey() {
            case .up:
                selected = (selected - 1 + options.count) % options.count
                redraw()

            case .down:
                selected = (selected + 1) % options.count
                redraw()

            case .enter:
                restore()
                return selected

            case .ctrlC:
                restore()
                print()
                exit(130)

            case .char(let c):
                let lower = (c >= 65 && c <= 90) ? c + 32 : c
                let index = Int(lower) - 97
                if lower >= 97, index < options.count {
                    selected = index
                    redraw()
                    restore()
                    return selected
                }

            case .other:
                continue
            }
        }
    }

    private enum Key {
        case up, down, enter, ctrlC, char(UInt8), other
    }

    private static func readKey() -> Key {
        var byte: UInt8 = 0
        guard read(STDIN_FILENO, &byte, 1) == 1 else { return .ctrlC }

        switch byte {
        case 3:
            return .ctrlC
        case 10, 13:
            return .enter
        case 27:
            var rest: [UInt8] = [0, 0]
            guard read(STDIN_FILENO, &rest[0], 1) == 1,
                  read(STDIN_FILENO, &rest[1], 1) == 1 else { return .other }
            if rest[0] == 91 {
                if rest[1] == 65 { return .up }
                if rest[1] == 66 { return .down }
            }
            return .other
        default:
            return .char(byte)
        }
    }


    private static func fallback(_ question: String, _ options: [String]) -> Int {
        print(question)
        for option in options {
            print("  \(option)")
        }

        while true {
            print("Type a letter or a number: ", terminator: "")
            fflush(stdout)

            guard let line = readLine() else { exit(1) }          
            let answer = line.trimmingCharacters(in: .whitespaces).lowercased()

            if let number = Int(answer), (1...options.count).contains(number) {
                return number - 1
            }
            if answer.count == 1, let ascii = answer.utf8.first,
               ascii >= 97, Int(ascii) - 97 < options.count {
                return Int(ascii) - 97
            }
            print("Please try again.")
        }
    }
    
    static func prompt(_ text: String) {
//        let cyanBold = "\u{1B}[1;36m"
        let orangeBold = "\u{1B}[1;33m"
        let reset = "\u{1B}[0m"
        
        print(
            "\(orangeBold)▸ \(text):\(reset) ",
            terminator: ""
        )
        
        fflush(stdout)
    }
}
