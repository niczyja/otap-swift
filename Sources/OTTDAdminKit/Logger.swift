
import Foundation
import os.log

///
/// Example:
///     `let logger = Logger()`
///     `let trace = logger`
///
///   possible calls:
///      logger.debug/info/warn/error
///      trace(1,2,3)
///      trace(1, nil)
///      trace(.once, "Multiple calls...")
///
final class Logger: @unchecked Sendable {
    public let osLog: OSLog
    let showsMeta = true

    private var onceMarkers = Set<String>()

    init(subsystem: String, category: String) {
        osLog = OSLog(subsystem: subsystem, category: category)
    }

    /// debug – useful only during debugging
    public func debug(_ message: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        logMessage(message(), type: .debug, file: file, function: function, line: line)
    }

    /// info – helpful but not essential for troubleshooting
    public func info(_ message: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        logMessage(message(), type: .info, file: file, function: function, line: line)
    }

    /// warn (default) – essential for troubleshooting
    public func warn(_ message: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        logMessage(message(), type: .default, file: file, function: function, line: line)
    }

    /// error – expected errors
    public func error(_ message: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        logMessage(message(), type: .error, file: file, function: function, line: line)
    }

    /// fault – unexpected errors, assumptions that weren’t true, potential bugs
    public func fault(_ message: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        logMessage(message(), type: .fault, file: file, function: function, line: line)
    }

    private func logMessage(_ message: @autoclosure () -> String, type: OSLogType, file: String, function: String, line: UInt) {
        if showsMeta {
            // [WindowController:49] loadContent() | loading...
            let baseFilename = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
            os_log("[%{public}s:%{public}d] %{public}s | %{public}s", log: osLog, type: type, baseFilename, line, function, message())
        } else {
            // loading...
            os_log("%{public}s", log: osLog, type: type, message())
        }
    }
}

extension Logger {
    enum LoggingOptions {
        case once
        case `if`(Bool)

        // Feature?
        //  case onChange(() -> AnyHashable)
    }

    func callAsFunction(_ option: LoggingOptions, _ items: Any?..., file: String = #fileID, function: String = #function, line: UInt = #line) {
        switch option {
        case .once:
            let marker = "\(file):\(line)"
            if onceMarkers.contains(marker) {
                return
            }
            onceMarkers.insert(marker)

        case let .if(condition):
            if condition == false {
                return
            }
            // Feature?
            //  case let .onChange(changeCallback):
            //      let callMarker = "\(file):\(line)"
            //      let newValue = changeCallback()
            //      let oldValue: AnyHashable = changeTrack[callMarker]
            //      if oldValue == newValue {
            //          return
            //      }
            //      changeTrack[callMarker] = newValue
        }
        handleCallAsFunction(items, file: file, function: function, line: line)
    }

    /// Use the class instance like a function just like print().
    func callAsFunction(_ items: Any?..., file: String = #fileID, function: String = #function, line: UInt = #line) {
        handleCallAsFunction(items, file: file, function: function, line: line)
    }

    private func handleCallAsFunction(_ items: [Any?], file: String = #fileID, function: String = #function, line: UInt = #line) {
        let message: () -> String = {
            var buff = TextBuffer()
            // needs a loop, since there is no way to change an array into variadic call
            for item in items.dropLast() {
                print(item ?? "<nil>", terminator: " ", to: &buff)
            }
            if let last = items.last {
                print(last ?? "<nil>", terminator: "", to: &buff)
            }

            return buff.contents
        }

        logMessage(message(), type: .debug, file: file, function: function, line: line)
    }

    // Inspired by https://nshipster.com/textoutputstream/
    private struct TextBuffer: TextOutputStream {
        var contents: String = ""
        mutating func write(_ string: String) {
            guard !string.isEmpty, string != "\n" else {
                return
            }
            contents.append(string)
        }
    }
}
