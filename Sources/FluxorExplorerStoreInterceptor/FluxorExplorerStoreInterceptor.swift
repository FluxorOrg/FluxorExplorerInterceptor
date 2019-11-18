//
//  FluxorExplorerStoreInterceptor.swift
//  Fluxor
//
//  Created by Morten Bjerg Gregersen on 15/11/2019.
//  Copyright © 2019 MoGee. All rights reserved.
//

import AnyCodable
import Fluxor
import FluxorExplorerSnapshot
import Foundation
import MultipeerConnectivity

public class FluxorExplorerStoreInterceptor<State: Encodable>: NSObject, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {
    private let serviceType = "fluxor-explorer"
    internal let localPeerID: MCPeerID
    internal var advertiser: MCNearbyServiceAdvertiser
    internal var session: MCSession?
    internal var unsentSnapshots = [FluxorExplorerSnapshot<State>]()

    public var peerDidDisconnect: (MCPeerID) -> Void = { peerID in
        print("FluxorExplorerStoreInterceptor - Peer did disconnect: \(peerID.displayName)")
    }

    public var didFailSendingSnapshot: (FluxorExplorerSnapshot<State>) -> Void = { snapshot in
        print("FluxorExplorerStoreInterceptor - Did fail sending snapshot: \(snapshot)")
    }

    public convenience init(displayName: String) {
        self.init(displayName: displayName, advertiserType: MCNearbyServiceAdvertiser.self)
    }

    internal init(displayName: String, advertiserType: MCNearbyServiceAdvertiser.Type) {
        localPeerID = MCPeerID(displayName: displayName)
        advertiser = advertiserType.init(peer: localPeerID, discoveryInfo: nil, serviceType: serviceType)
        super.init()
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }

    // MARK: - MCNearbyServiceAdvertiserDelegate

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                           withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        invitationHandler(true, session)
        self.session = session
    }

    // MARK: - MCSessionDelegate

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .notConnected {
            peerDidDisconnect(peerID)
        } else if state == .connected, session.connectedPeers.count > 0 {
            unsentSnapshots.forEach(send)
        }
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension FluxorExplorerStoreInterceptor: StoreInterceptor {
    public func actionDispatched(action: Action, newState: State) {
        let data = FluxorExplorerSnapshot(action: action, newState: newState)
        send(snapshot: data)
    }

    internal func send(snapshot: FluxorExplorerSnapshot<State>) {
        guard let session = session, session.connectedPeers.count > 0 else {
            unsentSnapshots.append(snapshot)
            return
        }
        do {
            let rawData = try JSONEncoder().encode(snapshot)
            try session.send(rawData, toPeers: session.connectedPeers, with: .reliable)
            if let dataIndex = unsentSnapshots.firstIndex(where: { $0 == snapshot }) {
                unsentSnapshots.remove(at: dataIndex)
            }
        } catch {
            didFailSendingSnapshot(snapshot)
        }
    }
}
