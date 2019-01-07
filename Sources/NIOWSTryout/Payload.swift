//
//  Payload.swift
//  LotULib
//
//  Created by Jari (LotU) on 28/10/2018.
//

import Foundation

internal struct GatewaySinData: Codable {
    public let op: OPCode
    
    public let s: Int?
    public let t: DiscordEvent?
}

internal struct GatewayData<T: Codable>: Codable {
    let d: T
}

internal struct GatewayPayload<T: Codable>: Codable {
    let d: T
    
    let op: OPCode
    
    let s: Int?
    
    let t: String?
}
