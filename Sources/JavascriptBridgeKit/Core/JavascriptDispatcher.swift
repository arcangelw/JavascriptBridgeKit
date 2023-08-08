//
//  JavascriptBridgeKit.swift
//
//
//  Created by 吴哲 on 2023/8/10.
//

import Foundation

final class JavascriptDispatcher {
    let module: String
    private let queue: DispatchQueue?
    private(set) weak var target: JavascriptBridgeExport?
    private(set) var retainTarget: JavascriptBridgeExport!

    init(_ target: JavascriptBridgeExport, for module: String, on queue: DispatchQueue?, retainTarget: Bool) {
        self.module = module
        self.queue = queue
        self.target = target
        if retainTarget {
            self.retainTarget = target
        }
    }

    func javascriptSyncCall(_ sendMessage: SendMessage, completionHandler: @escaping (String?) -> Void) {
        if let queue = queue {
            queue.async {
                completionHandler(self.syncCall(sendMessage))
            }
        } else {
            completionHandler(syncCall(sendMessage))
        }
    }

    func javascriptCall(_ sendMessage: SendMessage) {
        guard let target = target else { return }
        let sel = NSSelectorFromString(sendMessage.method)
        if let queue = queue {
            queue.async {
                do { try invoke(sel, of: target) } catch {}
            }
        } else {
            do { try invoke(sel, of: target) } catch {}
        }
    }

    private func syncCall(_ sendMessage: SendMessage) -> String? {
        let sel = NSSelectorFromString(sendMessage.method)
        guard let target = target else { return nil }
        do {
            let value = try invoke(sel, of: target, with: sendMessage.data)
            let result = SyncResult(value: value)
            let data = try JSONEncoder().encode(result)
            return String(decoding: data, as: UTF8.self)
        } catch {
            return nil
        }
    }
}
