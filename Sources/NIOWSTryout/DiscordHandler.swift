//
//  DiscordHandler.swift
//  LotULib
//
//  Created by Jari Koopman on 29/09/2018.
//

import Foundation
import NIO

open class DiscordHandler {
    
    let token: String
    
    lazy var sharder = Sharder()
    
    var blocker: EventLoopPromise<Void>?
    
    let worker = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
//    public let client: DiscordRESTClient
    
    static let decoder = JSONDecoder()
    
    static var decodingInfo: CodingUserInfoKey {
        return CodingUserInfoKey(rawValue: "handler")!
    }
    
    static let encoder = JSONEncoder()
    
//    internal var internalListeners = [DiscordEvent: [DiscordHandlerClosure]]()
//    public internal(set) var commands = [Command]()
//
//    public internal(set) var plugins = [Plugin]()
//
//    public let state: State
    
    public init(token: String) {
        self.token = token
//        self.client = DiscordRESTClient(self.worker, self.token)
//        self.state = State()
        
        DiscordHandler.decoder.userInfo[DiscordHandler.decodingInfo] = self
    }
    
    func block() {
        if blocker == nil {
            blocker = worker.eventLoop.newPromise(Void.self)
        }
        
        do {
            try blocker?.futureResult.wait()
        } catch {
            print("Unable to block")
        }
    }
    
    public func connect() {
        do {
//            try self.registerInternals()

//            let response: GatewayBotResponse = try client.execute(.GatewayBotGet).wait()
            
            let amountOfShards: UInt8 = 1
            sharder.shardCount = amountOfShards
            
            for i in 0 ..< amountOfShards {
                sharder.spawn(i, on: "wss://gateway.discord.gg", handledBy: self)
            }
            
            block()
        } catch {
            print(error.localizedDescription)
        }
    }
}
