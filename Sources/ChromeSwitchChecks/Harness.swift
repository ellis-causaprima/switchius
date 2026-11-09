import Foundation

/// Minimal assertion harness. Each `check` prints on failure; `finish()` exits non-zero if any failed.
enum Harness {
    static var failures = 0
    static var passes = 0

    static func check(_ condition: @autoclosure () -> Bool, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        if condition() {
            passes += 1
        } else {
            failures += 1
            print("FAIL \(file):\(line): \(message)")
        }
    }

    static func checkEqual<T: Equatable>(_ actual: T, _ expected: T, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
        check(actual == expected, "\(label): got \(actual), expected \(expected)", file: file, line: line)
    }

    static func checkThrows<E: Error & Equatable>(_ expected: E, _ label: String, file: StaticString = #filePath, line: UInt = #line, _ body: () throws -> Void) {
        do {
            try body()
            check(false, "\(label): expected \(expected) but nothing was thrown", file: file, line: line)
        } catch let error as E {
            checkEqual(error, expected, label, file: file, line: line)
        } catch {
            check(false, "\(label): threw unexpected \(error)", file: file, line: line)
        }
    }

    static func finish() -> Never {
        print(failures == 0 ? "OK: \(passes) checks passed" : "FAILED: \(failures) of \(passes + failures) checks failed")
        exit(failures == 0 ? 0 : 1)
    }
}
