import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    var onWordLogged: (() -> Void)?

    private init() {
        openDatabase()
    }

    private func openDatabase() {
        let fileURL = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("JustDetector.sqlite")

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Logs (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, word TEXT, context TEXT)", nil, nil, nil) != SQLITE_OK {
            print("Error creating table: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
    }

    func logWord(date: Date, word: String, context: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // Date only
        let dateString = formatter.string(from: date)

        let insertQuery = "INSERT INTO Logs (date, word, context) VALUES (?, ?, ?)"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, insertQuery, -1, &stmt, nil) != SQLITE_OK {
            print("Error preparing insert: \(String(describing: sqlite3_errmsg(db)))")
            return
        }

        sqlite3_bind_text(stmt, 1, (dateString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (word as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (context as NSString).utf8String, -1, nil)

        if sqlite3_step(stmt) != SQLITE_DONE {
            print("Error inserting word into logs: \(String(describing: sqlite3_errmsg(db)))")
        } else {
            onWordLogged?()
        }

        sqlite3_finalize(stmt)
    }


    func countWords(for date: Date) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let query = "SELECT COUNT(*) FROM Logs WHERE date = '\(dateString)' AND word = 'just'"
        var queryStatement: OpaquePointer?

        var count = 0
        if sqlite3_prepare_v2(db, query, -1, &queryStatement, nil) == SQLITE_OK {
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(queryStatement, 0))
            }
        } else {
            print("SELECT statement could not be prepared: \(String(describing: sqlite3_errmsg(db)))")
        }

        sqlite3_finalize(queryStatement)
        return count
    }
}
