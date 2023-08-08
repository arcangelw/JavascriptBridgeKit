//
//  JavascriptBridgeKit.swift
//
//
//  Created by 吴哲 on 2023/8/7.
//

import AnyCodable
import Foundation

/// 回调消息类型
enum MessageType: String, Codable {
    /// 回调消息
    case callback
    /// 事件消息
    case event

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        if let messageType = MessageType(rawValue: rawValue) {
            self = messageType
        } else {
            throw DecodingError.typeMismatch(MessageType.self, .init(codingPath: [], debugDescription: "MessageType not exist rawValue: \(rawValue)"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// 发送消息体
struct SendMessage: Decodable {
    /// 模块名称
    let module: String
    /// 方法名称
    let method: String
    /// 参数
    let data: [Any]

    private enum CodingKeys: String, CodingKey {
        case module
        case method
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        module = try container.decode(String.self, forKey: .module)
        method = try container.decode(String.self, forKey: .method)
        let anyDatas = try container.decode([AnyDecodable].self, forKey: .data)
        data = anyDatas.map { data -> Any in
            switch data.value {
            case let dictionary as [String: String]:
                guard dictionary.keys.contains("callbackId"), dictionary.count == 1 else {
                    return dictionary
                }
                return SendMessageCallBack(callbackId: dictionary["callbackId"]!)
            case let value:
                return value
            }
        }
    }
}

/// 发送消息体中回调方法id
public struct SendMessageCallBack {
    /// 回调方法id
    public let callbackId: String
}

/// 回调消息体
struct CallbackMessage: Encodable {
    /// 回调类型
    let messageType: MessageType
    /// 回调方法id
    let callbackId: String?
    /// 回调事件名称
    let eventName: String?
    /// 回调数据
    let data: [Any]

    private enum CodingKeys: String, CodingKey {
        case messageType
        case callbackId
        case eventName
        case data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messageType, forKey: .messageType)
        try container.encode(callbackId, forKey: .callbackId)
        try container.encode(eventName, forKey: .eventName)
        try container.encode(data.map(AnyEncodable.init(_:)), forKey: .data)
    }
}

struct SyncResult: Encodable {
    let value: Any?
    private enum CodingKeys: String, CodingKey {
        case value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(AnyEncodable(value), forKey: .value)
    }
}
