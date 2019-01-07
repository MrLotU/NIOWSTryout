//
//  Sharder.swift
//  LotULib
//
//  Created by Jari Koopman on 29/09/2018.
//

extension DiscordHandler {
    static let GatewayVersion: UInt8 = 6
    
    static let GatewayEncoding: String = "json"
    
    static let GatewayCompression: String = "zlib-stream"
}

class Sharder {
    var shardCount: UInt8 = 0
    
    var shardHosts = [UInt8: String]()
    
    var shards = [Shard]()
    
    func spawn(_ id: UInt8, on host: String, handledBy handler: DiscordHandler) {
        var host = "\(host)?v=\(DiscordHandler.GatewayVersion)"
        
        host += "&encoding=\(DiscordHandler.GatewayEncoding)"
        
        // check for encoding
        host += "&compress=\(DiscordHandler.GatewayCompression)"
        
        shardHosts[id] = host
        
        print("Spawning shard \(id) with connection to \(host)")
        
        let shard = Shard(id: id, handler: handler)
        shard.connect(to: host)
        shards.append(shard)
    }
    
    func disconnect() {
        shards.forEach { $0.disconnect() }
    }
}
