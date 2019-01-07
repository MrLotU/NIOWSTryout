//
//  DispatchCodes.swift
//  LotULib
//
//  Created by Jari (LotU) on 27/10/2018.
//

import Foundation

public protocol DiscordGatewayType: Codable { }
protocol DiscordHandled {
    var handler: DiscordHandler! { get set }
}

public enum DiscordEvent: String, Codable {
    case hello = "HELLO"
    case ready = "READY"
    case resumed = "RESUMED"
    case invalidSession = "INVALID_SESSION"
    case channelCreate = "CHANNEL_CREATE"
    case channelUpdate = "CHANNEL_UPDATE"
    case channelDelete = "CHANNEL_DELETE"
    case channelPinsUpdate = "CHANNEL_PINS_UPDATE"
    case guildCreate = "GUILD_CREATE"
    case guildUpdate = "GUILD_UPDATE"
    case guildDelete = "GUILD_DELETE"
    case guildBanAdd = "GUILD_BAN_ADD"
    case guildBanRemove = "GUILD_BAN_REMOVE"
    case guildEmojisUpdate = "GUILD_EMOJIS_UPDATE"
    case guildIntegrationsUpdate = "GUILD_INTEGRATIONS_UPDATE"
    case guildMemberAdd = "GUILD_MEMBER_ADD"
    case guildMemberRemove = "GUILD_MEMBER_REMOVE"
    case guildMemberUpdate = "GUILD_MEMBER_UPDATE"
    case guildMembersChunk = "GUILD_MEMBERS_CHUNK"
    case guildRoleCreate = "GUILD_ROLE_CREATE"
    case guildRoleUpdate = "GUILD_ROLE_UPDATE"
    case guildRoleDelete = "GUILD_ROLE_DELETE"
    case messageCreate = "MESSAGE_CREATE"
    case messageUpdate = "MESSAGE_UPDATE"
    case messageDelete = "MESSAGE_DELETE"
    case messageDeleteBulk = "MESSAGE_DELETE_BULK"
    case messageReactionAdd = "MESSAGE_REACTION_ADD"
    case messageReactionRemove = "MESSAGE_REACTION_REMOVE"
    case messageReactionRemoveAll = "MESSAGE_REACTION_REMOVE_ALL"
    case presenceUpdate = "PRESENCE_UPDATE"
    case typingStart = "TYPING_START"
    case userUpdate = "USER_UPDATE"
    case voiceStateUpdate = "VOICE_STATE_UPDATE"
    case voiceServerUpdate = "VOICE_SERVER_UPDATE"
    case webhooksUpdate = "WEBHOOKS_UPDATE"
}

extension DiscordEvent: CaseIterable { }

class Empty: DiscordGatewayType {}
