//
//  Shard.swift
//  LotULib
//
//  Created by Jari Koopman on 29/09/2018.
//

import Foundation
import WebSocket
import CNIOZlib

fileprivate let ZlibSuffix: Bytes = [0x0, 0x0, 0xFF, 0xFF]

class Shard: GatewayClient {
    var ackMissed = 0
    
    var buffer = Bytes()
    
    let id: UInt8
    
    let heartbeatQueue: DispatchQueue
    
    var isBufferComplete: Bool {
        guard buffer.count >= 4 else {
            return false
        }
        let suff = buffer.suffix(4)
        return suff.elementsEqual(ZlibSuffix)
    }
    
    var isReconnecting = false
    
    var lastSequence: Int?
    
    var sessionId: String?
    
    var socket: WebSocket?
    
    let handler: DiscordHandler
    
    var worker: Worker = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    var socketUrl: String?
    
    var stream = z_stream()
    
    init(id: UInt8, handler: DiscordHandler) {
        self.id = id
        self.handler = handler
        self.heartbeatQueue = DispatchQueue(label: "LotULib.DiscordHandler.Shard.\(id).heartbeater")
        
        stream.avail_in = 0
        stream.next_in = nil
        stream.total_out = 0
        stream.zalloc = nil
        stream.zfree = nil
        
        inflateInit2_(&stream, MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
    }
    
    deinit {
        inflateEnd(&stream)
        
        do {
            try worker.syncShutdownGracefully()
        } catch {
            print("Graceful shutdown of worker for shard \(id) failed")
        }
    }
    
    func handle(_ data: Data) {
        print("Got some data!")
        buffer.append(contentsOf: data)
        
        guard isBufferComplete else {
            return
        }
        
        let deflated = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: buffer.count)
        
        _ = deflated.initialize(from: buffer)
        
        defer {
            deflated.deallocate()
        }
        
        stream.next_in = deflated.baseAddress
        stream.avail_in = UInt32(deflated.count)
        
        var inflated = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: deflated.count * 2)
        
        defer {
            inflated.deallocate()
        }
        
        stream.total_out = 0
        
        var status: Int32 = 0
                
        while true {
            stream.next_out = inflated.baseAddress?.advanced(by: Int(stream.total_out))
            stream.avail_out = UInt32(inflated.count) - UInt32(stream.total_out)
            
            status = inflate(&stream, Z_SYNC_FLUSH)
            
            if status == Z_BUF_ERROR && stream.avail_in == 0 {
                inflated.realloc(size: inflated.count + min(inflated.count * 2, maxBuff))
                continue
            } else if status != Z_OK {
                break
            }
        }
        
        let result = String(bytesNoCopy: inflated.baseAddress!, length: Int(stream.total_out), encoding: .utf8, freeWhenDone: false)
        
        guard let text = result else {
            return
        }
        if !text.isEmpty {
            buffer.removeAll()
        }
        print("Converted binary to \(text)")
        handle(text)
    }
    
    func handle(_ text: String) {
        print(text)
    }
    
    func heartbeat(after interval: Int) {
        guard let socket = socket else { return }
        guard !socket.isClosed else {
            print("Heartbeating from closed shard \(id)")
            return
        }
        guard ackMissed < 2 else {
            print("Shard \(id) did not get HEARTBEAT_ACK. Reconnecting...")
            reconnect()
            return
        }
        ackMissed += 1
        
        heartbeat()
        
        heartbeatQueue.asyncAfter(deadline: .now() + .milliseconds(interval)) { [ weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.heartbeat(after: interval)
        }
    }
    
    func heartbeat() {
        let heartbeat = GatewayPayload<Int?>(d: lastSequence, op: .heartbeat, s: nil, t: nil)
        send(heartbeat)
    }
    
    func handle(_ error: Error) {
        print(error.localizedDescription)
        if let errorCode = error as? WebSocketErrorCode {
            handle(errorCode)
        }
    }
    
    func handle(_ errorCode: WebSocketErrorCode) {
        if case .normalClosure = errorCode {
            print("Shard \(id) reconnecting...")
            reconnect()
        }
        
        guard case let .unknown(code) = errorCode else {
            print("Gateway error: \(errorCode)")
            return
        }
        
        if let code = GatewayErrorCode(rawValue: Int(code)) {
            switch code {
            case .authenticationFailed:
                print("Authentication for shard \(id) failed")
            case .invalidShard:
                print("Shard \(id) has invalid shard info")
            case .shardingRequired:
                print("Shard \(id) requires more shards")
            default:
                print("Gateway shut down. Reconnecting shard \(id)")
                reconnect()
            }
        } else {
            print("Gateway error: \(errorCode)")
        }
    }
    
    func identify() {
        #if os(macOS)
        let os = "macOS"
        #elseif os(Linux)
        let os = "Linux"
        #endif
        
        struct IdentifyPayload: Codable {
            public let token: String
            public let properties: Properties
            public let compress: Bool?
            public let large_treshold: Int
            public let shard: [UInt8]
            
            init(token: String, properties: Properties, compress: Bool? = nil, largeTreshold: Int, shard: [UInt8]) {
                self.token = token
                self.properties = properties
                self.compress = compress
                self.large_treshold = largeTreshold
                self.shard = shard
            }
            
            public struct Properties: Codable {
                public let os: String
                public let browser: String
                public let device: String
                
                init(os: String, browser: String, device: String) {
                    self.os = os
                    self.browser = browser
                    self.device = device
                }
                
                enum CodingKeys: String, CodingKey {
                    case os = "$os"
                    case browser = "$browser"
                    case device = "$device"
                }
            }
        }

        
        let d = IdentifyPayload(token: handler.token, properties: .init(os: os, browser: "LotULib", device: "LotULib"), compress: false, largeTreshold: 250, shard: [id, handler.sharder.shardCount])
        
        let payload = GatewayPayload(d: d, op: .identify, s: nil, t: nil)
        self.send(payload)
    }
        
    func send<T: Codable>(_ payload: GatewayPayload<T>) {
        do {
            let data = try DiscordHandler.encoder.encode(payload)
            socket?.send(data)
        } catch {
            print("Unable to send \(payload.op) data on shard \(id). Error: \(error.localizedDescription)")
        }
    }
    
    func reconnect() {
        if let socket = socket, !socket.isClosed {
            disconnect()
        }
        
        guard let host = self.socketUrl else {
            print("Shard \(id) has no host to connect to. Shutting down shard")
            return
        }
        
        if sessionId != nil { isReconnecting = true }
        connect(to: host)
    }
}

