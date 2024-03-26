//
//  JavascriptBridgeRuntime.swift
//
//
//  Created by 吴哲 on 2023/8/10.
//

import Foundation
import ObjectiveC

@objc
private protocol NSMethodSignatureProtocol {
    static func signature(objCTypes: UnsafePointer<CChar>!) -> NSMethodSignatureProtocol?
    var numberOfArguments: UInt { get }
    func getArgumentType(atIndex idx: UInt) -> UnsafePointer<CChar>
    var frameLength: UInt { get }
    func isOneway() -> ObjCBool
    var methodReturnType: UnsafePointer<CChar> { get }
    var methodReturnLength: UInt { get }
}

private var NSMethodSignature: NSMethodSignatureProtocol.Type = {
    class_addProtocol(objc_lookUpClass("NSMethodSignature"), NSMethodSignatureProtocol.self)
    return objc_lookUpClass("NSMethodSignature") as! NSMethodSignatureProtocol.Type
}()

@objc
private protocol NSInvocationProtocol {
    static func invocation(methodSignature: NSMethodSignatureProtocol) -> NSInvocationProtocol
    var methodSignature: NSMethodSignatureProtocol { get }
    func retainArguments()
    var argumentsRetained: ObjCBool { get }
    unowned(unsafe) var target: AnyObject? { get set }
    var selector: Selector { get set }
    func getReturnValue(_ retLoc: UnsafeMutableRawPointer)
    func setReturnValue(_ retLoc: UnsafeMutableRawPointer)
    func getArgument(_ argumentLocation: UnsafeMutableRawPointer, atIndex idx: Int)
    func setArgument(_ argumentLocation: UnsafeMutableRawPointer, atIndex idx: Int)
    func invoke()
    func invoke(target: Any)
    func invokeUsingIMP(_ imp: IMP)
}

private var NSInvocation: NSInvocationProtocol.Type = {
    class_addProtocol(objc_lookUpClass("NSInvocation"), NSInvocationProtocol.self)
    return objc_lookUpClass("NSInvocation") as! NSInvocationProtocol.Type
}()

// See: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
private enum ObjCType: CChar {
    case char = 0x63 // 'c'
    case int = 0x69 // 'i'
    case short = 0x73 // 's'
    case long = 0x6C // 'l'
    case longlong = 0x71 // 'q'
    case uchar = 0x43 // 'C'
    case uint = 0x49 // 'I'
    case ushort = 0x53 // 'S'
    case ulong = 0x4C // 'L'
    case ulonglong = 0x51 // 'Q'
    case float = 0x66 // 'f'
    case double = 0x64 // 'd'
    case bool = 0x42 // 'B'
    case void = 0x76 // 'v'
    case string = 0x2A // '*'
    case object = 0x40 // '@'
    case clazz = 0x23 // '#'
    case selector = 0x3A // ':'
    case pointer = 0x5E // '^'
    case unknown = 0x3F // '?'

    init(code: UnsafePointer<CChar>) {
        var val = code.pointee
        while
            val == 0x72 || // 'r' const
            val == 0x6E || // 'n' in
            val == 0x4E || // 'N' inout
            val == 0x6F || // 'o' out
            val == 0x4F || // 'O' bycopy
            val == 0x52 || // 'R' byref
            val == 0x56 // 'V' oneway
        {
            // cutoff useless prefix
            val = code.successor().pointee
        }
        guard let type = ObjCType(rawValue: val) else {
            fatalError("Unknown ObjC type code: \(String(cString: code))")
        }
        self = type
    }

    func loadValue(from pointer: UnsafeRawPointer) -> Any! {
        switch self {
        case .char: return pointer.load(as: CChar.self)
        case .int: return pointer.load(as: CInt.self)
        case .short: return pointer.load(as: CShort.self)
        case .long: return pointer.load(as: Int32.self)
        case .longlong: return pointer.load(as: CLongLong.self)
        case .uchar: return pointer.load(as: CUnsignedChar.self)
        case .uint: return pointer.load(as: CUnsignedInt.self)
        case .ushort: return pointer.load(as: CUnsignedShort.self)
        case .ulong: return pointer.load(as: UInt32.self)
        case .ulonglong: return pointer.load(as: CUnsignedLongLong.self)
        case .float: return pointer.load(as: CFloat.self)
        case .double: return pointer.load(as: CDouble.self)
        case .bool: return pointer.load(as: CBool.self)
        case .void: return ()
        case .string: return pointer.load(as: UnsafePointer<CChar>.self)
        case .object: return pointer.load(as: AnyObject?.self)
        case .clazz: return pointer.load(as: AnyClass?.self)
        case .selector: return pointer.load(as: Selector?.self)
        case .pointer: return pointer.load(as: OpaquePointer.self)
        case .unknown:
            #if DEBUG
                fatalError("Unknown ObjC type")
            #else
                return nil
            #endif
        }
    }
}

private extension NSNumber {
    func value(as type: ObjCType) -> CVarArg? {
        switch type {
        case .bool: return boolValue
        case .char: return int8Value
        case .int: return int32Value
        case .short: return int16Value
        case .long: return int32Value
        case .longlong: return int64Value
        case .uchar: return uint8Value
        case .uint: return uint32Value
        case .ushort: return uint16Value
        case .ulong: return uint32Value
        case .ulonglong: return uint64Value
        case .float: return floatValue
        case .double: return doubleValue
        default: return nil
        }
    }
}

private extension Selector {
    enum Family: CChar {
        case none = 0x00
        case alloc = 0x61
        case copy = 0x63
        case mutableCopy = 0x6D
        case `init` = 0x69
        case new = 0x6E
    }

    static var prefixes: [[CChar]] = [
        /* alloc */ [0x61, 0x6C, 0x6C, 0x6F, 0x63],
        /* copy */ [0x63, 0x6F, 0x70, 0x79],
        /* mutableCopy */ [0x6D, 0x75, 0x74, 0x61, 0x62, 0x6C, 0x65, 0x43, 0x6F, 0x70, 0x79],
        /* init */ [0x69, 0x6E, 0x69, 0x74],
        /* new */ [0x6E, 0x65, 0x77],
    ]

    var family: Family {
        // See: http://clang.llvm.org/docs/AutomaticReferenceCounting.html#id34
        var sel = unsafeBitCast(self, to: UnsafePointer<Int8>.self)
        while sel.pointee == 0x5F {
            sel += 1
        } // skip underscore '_'
        for prefixe in Selector.prefixes {
            let lowercase = CChar(0x61) ... CChar(0x7A)
            let length = prefixe.count
            if strncmp(sel, prefixe, length) == 0 && !lowercase.contains(sel.advanced(by: length).pointee) {
                return Family(rawValue: sel.pointee)!
            }
        }
        return .none
    }

    var returnsRetained: Bool {
        return family != .none
    }
}

// Additional Swift types which can be represented in C type.
public extension CVarArg {
    var _cVarArgEncoding: [Int] {
        return _encodeBitsAsWords(self)
    }
}

extension UnicodeScalar: CVarArg {}
extension Selector: CVarArg {}
extension UnsafeRawPointer: CVarArg {}
extension UnsafeMutableRawPointer: CVarArg {}
extension UnsafeBufferPointer: CVarArg {}
extension UnsafeMutableBufferPointer: CVarArg {}

// MARK: - Invocation

private enum InvocationError: Swift.Error {
    case doesNotRecognize(target: AnyObject, selector: Selector)
    case tooManyArguments(target: AnyObject, selector: Selector)
    case unableToConvertArgument(index: UInt, argument: Any, ocType: ObjCType)
}

extension InvocationError: CustomDebugStringConvertible, CustomStringConvertible {
    var description: String {
        switch self {
        case let .doesNotRecognize(target, selector):
            return "Unrecognized selector -[\(target) \(selector)]"
        case let .tooManyArguments(target, selector):
            return "Too many arguments for calling -[\(type(of: target)) \(selector)]"
        case let .unableToConvertArgument(index, argument, ocType):
            return "Unable to convert argument \(index) from Swift type \(type(of: argument)) to ObjC type '\(ocType)'"
        }
    }

    var debugDescription: String {
        description
    }
}

@discardableResult
func invoke(_ selector: Selector, of target: AnyObject, with arguments: [Any?] = [], on thread: Thread? = nil, waitUntilDone wait: Bool = true) throws -> Any! {
    guard
        let method = class_getInstanceMethod(type(of: target), selector),
        let sig = NSMethodSignature.signature(objCTypes: method_getTypeEncoding(method))
    else {
        throw InvocationError.doesNotRecognize(target: target, selector: selector)
    }
    let inv = NSInvocation.invocation(methodSignature: sig)

    // Setup arguments
    #if DEBUG
        precondition(arguments.count + 2 <= method_getNumberOfArguments(method),
                     "Too many arguments for calling -[\(type(of: target)) \(selector)]")
    #else
        if arguments.count + 2 > method_getNumberOfArguments(method) {
            throw InvocationError.tooManyArguments(target: target, selector: selector)
        }
    #endif
    var args = [[Int]](repeating: [], count: arguments.count)
    for index in 0 ..< arguments.endIndex {
        if let arg: Any = arguments[index] {
            let code = sig.getArgumentType(atIndex: UInt(index + 2))
            let octype = ObjCType(code: code)
            if octype == .object {
                let obj: AnyObject = _bridgeAnythingToObjectiveC(arg)
                _autorelease(obj)
                args[index] = _encodeBitsAsWords(obj)
            } else if octype == .clazz, let cls = arg as? AnyClass {
                args[index] = _encodeBitsAsWords(cls)
            } else if octype == .float, let float = arg as? Float {
                // prevent to promot float type to double
                args[index] = _encodeBitsAsWords(float)
            } else if var val = arg as? CVarArg {
                if (type(of: arg) as? AnyClass)?.isSubclass(of: NSNumber.self) == true {
                    // argument is an NSNumber object
                    if let numberValue = (arg as! NSNumber).value(as: octype) {
                        val = numberValue
                    }
                } else if let value = arg as? String {
                    // string to number
                    let decimal = NSDecimalNumber(string: value)
                    if let numberValue = (decimal == .notANumber ? .zero : decimal).value(as: octype) {
                        val = numberValue
                    }
                }
                args[index] = val._cVarArgEncoding
            } else {
                let octype = String(cString: code)
                #if DEBUG
                    fatalError("Unable to convert argument \(index) from Swift type \(type(of: arg)) to ObjC type '\(octype)'")
                #else
                    throw InvocationError.unableToConvertArgument(index: index, argument: arg, ocType: octype)
                #endif
            }
        } else {
            // nil
            args[index] = [Int(0)]
        }

        args[index].withUnsafeBufferPointer {
            inv.setArgument(UnsafeMutablePointer(mutating: $0.baseAddress!), atIndex: index + 2)
        }
    }

    if selector.family == .`init` {
        // Self should be consumed for method belongs to init famlily
        _ = Unmanaged.passRetained(target)
    }
    inv.selector = selector

    if thread == nil || (thread == Thread.current && wait) {
        inv.invoke(target: target)
    } else {
        let selector = #selector(NSInvocationProtocol.invoke(target:))
        inv.retainArguments()
        (inv as AnyObject).perform(selector, on: thread!, with: target, waitUntilDone: wait)
        guard wait else { return () }
    }
    let octype = ObjCType(code: sig.methodReturnType)
    guard octype != .void else { return () }
    // Fetch the return value
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(sig.methodReturnLength))
    inv.getReturnValue(buffer)
    defer {
        if octype == .object, selector.returnsRetained {
            // To balance the retained return value
            let obj = UnsafeRawPointer(buffer).load(as: AnyObject.self)
            Unmanaged.passUnretained(obj).release()
        }
        buffer.deallocate()
    }
    return octype.loadValue(from: buffer)
}

// MARK: - Get Methods

typealias ProtocolSelectors = (syncSelectors: Set<Selector>, asyncSelectors: Set<Selector>)

private var selectorsCache: [NSValue: ProtocolSelectors] = [:]

func instanceMethods(_ target: Any, on aProtocol: Protocol? = nil) -> ProtocolSelectors {
    var targetClass: AnyClass? = object_getClass(target)
    let key = NSValue(nonretainedObject: targetClass)
    if let selectors = selectorsCache[key] {
        return selectors
    }
    var syncSelectors = Set<Selector>()
    var asyncSelectors = Set<Selector>()
    while targetClass != nil {
        var count: UInt32 = 0
        if let protocolList = class_copyProtocolList(targetClass, &count) {
            for idx in 0 ..< Int(count) {
                let pro = protocolList.advanced(by: idx).pointee
                if aProtocol == nil || protocol_conformsToProtocol(pro, aProtocol!) {
                    let methods = instanceMethods(forProtocol: pro)
                    syncSelectors.formUnion(methods.syncSelectors)
                    asyncSelectors.formUnion(methods.asyncSelectors)
                }
            }
        }
        targetClass = class_getSuperclass(targetClass)
    }
    let selectors: ProtocolSelectors = (syncSelectors, asyncSelectors)
    selectorsCache[key] = selectors
    return selectors
}

private func instanceMethods(forProtocol aProtocol: Protocol) -> ProtocolSelectors {
    var syncSelectors = Set<Selector>()
    var asyncSelectors = Set<Selector>()
    for (req, inst) in [(true, true), (false, true)] {
        var count: UInt32 = 0
        guard let methodList = protocol_copyMethodDescriptionList(aProtocol.self, req, inst, &count) else {
            continue
        }
        for idx in 0 ..< Int(count) {
            let desc = methodList.advanced(by: idx).pointee
            guard
                let sel = desc.name,
                let sig = NSMethodSignature.signature(objCTypes: desc.types)
            else { continue }
            let objcType = ObjCType(code: sig.methodReturnType)
            if case .void = objcType {
                asyncSelectors.insert(sel)
            } else {
                syncSelectors.insert(sel)
            }
        }
        free(methodList)
    }
    return (syncSelectors, asyncSelectors)
}
