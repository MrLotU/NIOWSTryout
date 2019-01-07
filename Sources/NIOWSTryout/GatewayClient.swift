//
//  GatewayClient.swift
//  LotULib
//
//  Created by Jari Koopman on 29/09/2018.
//


import WebSocket

protocol GatewayClient: class {
    var socket: WebSocket? { get set }
    
    var worker: Worker { get set }
    
    var socketUrl: String? { get set }
    
    func connect(to socketUrl: String)
    
    func disconnect()
    
    func handle(_ data: Data)
    
    func handle(_ errorCode: WebSocketErrorCode)
    
    func handle(_ text: String)
    
    func handle(_ error: Error)
    
    func reconnect()
}

extension GatewayClient {
    
    func connect(to socketUrl: String) {
        guard let url = URL(string: socketUrl), let host = url.host else {
            print("Invalid gateway url \(socketUrl)")
            return
        }
        
        self.socketUrl = socketUrl
        
        let path = url.path.isEmpty ? "/" : url.path
        
        let socket = HTTPClient.webSocket(scheme: .wss, hostname: host, port: url.port, path: path, maxFrameSize: 1 << 18, on: worker)
        
        socket.whenSuccess { [weak self] ws in
            guard let strongSelf = self else {
                return
            }
            
            ws.onText { _, text in
                strongSelf.handle(text)
            }
            
            ws.onBinary { _, data in
                strongSelf.handle(data)
            }
            
            ws.onCloseCode { code in
                strongSelf.handle(code)
            }
            
            ws.onError { _, error in
                strongSelf.handle(error)
            }
            
            strongSelf.socket = ws
            
            print("Gateway connected")
        }
        
        DispatchQueue.main.async {
            do {
                _ = try socket.wait()
            } catch {
                print("Failed to connect to gateway. \(error)")
            }
        }
    }
    
    func disconnect() {
        socket?.close()
        socket = nil
    }
}
