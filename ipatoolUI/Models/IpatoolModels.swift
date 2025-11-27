import Foundation

struct IpatoolApp: Identifiable, Decodable, Hashable {
    let trackID: Int64?
    let bundleID: String?
    let name: String?
    let version: String?
    let price: Double?
    let artworkURL: URL?

    var id: UUID = UUID()

    enum CodingKeys: String, CodingKey {
        case trackID = "id"
        case bundleID
        case name
        case version
        case price
        case artworkUrl60
        case artworkUrl100
        case artworkUrl512
    }

    init(trackID: Int64?, bundleID: String?, name: String?, version: String?, price: Double?, artworkURL: URL?) {
        self.trackID = trackID
        self.bundleID = bundleID
        self.name = name
        self.version = version
        self.price = price
        self.artworkURL = artworkURL
        self.id = UUID()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackID = try container.decodeIfPresent(Int64.self, forKey: .trackID)
        bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        price = try container.decodeIfPresent(Double.self, forKey: .price)

        if let artwork512 = try container.decodeIfPresent(URL.self, forKey: .artworkUrl512) {
            artworkURL = artwork512
        } else if let artwork100 = try container.decodeIfPresent(URL.self, forKey: .artworkUrl100) {
            artworkURL = artwork100
        } else if let artwork60 = try container.decodeIfPresent(URL.self, forKey: .artworkUrl60) {
            artworkURL = artwork60
        } else {
            artworkURL = nil
        }
        id = UUID()
    }
}

struct SearchLogEvent: Decodable {
    let count: Int?
    let apps: [IpatoolApp]?
}

struct AuthLogEvent: Decodable {
    let email: String?
    let name: String?
    let success: Bool?
}

struct StatusLogEvent: Decodable {
    let success: Bool?
}

struct VersionsLogEvent: Decodable {
    let bundleID: String?
    let externalVersionIdentifiers: [String]?
    let success: Bool?
}

struct DownloadLogEvent: Decodable {
    let success: Bool?
    let purchased: Bool?
    let output: String?
}

struct VersionMetadataLogEvent: Decodable {
    let success: Bool?
    let externalVersionID: String?
    let displayVersion: String?
    let releaseDate: Date?
}

enum IpatoolError: LocalizedError, Identifiable {
    case executableNotFound
    case commandFailed(String)
    case decodingFailed
    case invalidInput(String)

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return String(localized: "error.executableNotFound")
        case .commandFailed(let message):
            return message
        case .decodingFailed:
            return String(localized: "error.decodingFailed")
        case .invalidInput(let details):
            return details
        }
    }
}
