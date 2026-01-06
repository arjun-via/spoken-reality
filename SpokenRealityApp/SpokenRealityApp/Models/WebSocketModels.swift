import Foundation

// MARK: - WebSocket Message Base

struct WebSocketMessage: Codable {
    let type: String
    let payload: [String: AnyCodable]
    let timestamp: Int64
    let messageId: String

    init(type: String, payload: [String: AnyCodable] = [:]) {
        self.type = type
        self.payload = payload
        self.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        self.messageId = UUID().uuidString
    }
}

// MARK: - Agent State

enum AgentState: String, Codable {
    case idle = "IDLE"
    case listening = "LISTENING"
    case interpreting = "INTERPRETING"
    case clarifying = "CLARIFYING"
    case planning = "PLANNING"
    case executing = "EXECUTING"
    case presenting = "PRESENTING"
    case error = "ERROR"
}

// MARK: - Outgoing Messages (Client → Server)

struct VoiceStartMessage {
    let projectId: String

    func toWebSocketMessage() -> WebSocketMessage {
        WebSocketMessage(
            type: "voice.start",
            payload: ["projectId": AnyCodable(projectId)]
        )
    }
}

struct VoiceChunkMessage {
    let audio: String  // Base64-encoded PCM data

    func toWebSocketMessage() -> WebSocketMessage {
        WebSocketMessage(
            type: "voice.chunk",
            payload: ["audio": AnyCodable(audio)]
        )
    }
}

struct VoiceEndMessage {
    func toWebSocketMessage() -> WebSocketMessage {
        WebSocketMessage(type: "voice.end")
    }
}

struct CommandMessage {
    let text: String
    let projectId: String

    func toWebSocketMessage() -> WebSocketMessage {
        WebSocketMessage(
            type: "command",
            payload: [
                "text": AnyCodable(text),
                "projectId": AnyCodable(projectId)
            ]
        )
    }
}

struct ProjectCreateMessage {
    let name: String

    func toWebSocketMessage() -> WebSocketMessage {
        WebSocketMessage(
            type: "project.create",
            payload: ["name": AnyCodable(name)]
        )
    }
}

struct ProjectOpenMessage {
    let projectId: String

    func toWebSocketMessage() -> WebSocketMessage {
        WebSocketMessage(
            type: "project.open",
            payload: ["projectId": AnyCodable(projectId)]
        )
    }
}

struct ProjectGetFilesMessage {
    let projectId: String

    func toWebSocketMessage() -> WebSocketMessage {
        WebSocketMessage(
            type: "project.getFiles",
            payload: ["projectId": AnyCodable(projectId)]
        )
    }
}

struct GitCommitMessage {
    let message: String
    let projectId: String

    func toWebSocketMessage() -> WebSocketMessage {
        WebSocketMessage(
            type: "git.commit",
            payload: [
                "message": AnyCodable(message),
                "projectId": AnyCodable(projectId)
            ]
        )
    }
}

// MARK: - Incoming Messages (Server → Client)

struct AgentStatePayload: Codable {
    let state: AgentState
    let message: String?
    let progress: Int?
}

struct TranscriptionPartialPayload: Codable {
    let text: String
}

struct TranscriptionFinalPayload: Codable {
    let text: String
}

struct AgentSpeakPayload: Codable {
    let text: String
    let audio: String?  // Base64-encoded audio for TTS
}

struct AgentClarifyPayload: Codable {
    let question: String
    let options: [String]?
}

struct PreviewReadyPayload: Codable {
    let url: String
}

struct CodeUpdatedPayload: Codable {
    let files: [CodeFile]

    struct CodeFile: Codable {
        let path: String
        let content: String
    }
}

struct BackendError: Codable, Equatable {
    let code: String
    let message: String
    let recoverable: Bool
    let suggestedAction: String?
}

// MARK: - Helper for Any Codable Value

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "AnyCodable value cannot be encoded"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
