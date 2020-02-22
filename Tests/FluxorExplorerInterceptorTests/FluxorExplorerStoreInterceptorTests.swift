//
//  FluxorExplorerInterceptorTests.swift
//  FluxorTests
//
//  Created by Morten Bjerg Gregersen on 15/11/2019.
//  Copyright © 2019 MoGee. All rights reserved.
//

import Fluxor
import FluxorExplorerSnapshot
@testable import FluxorExplorerInterceptor
import MultipeerConnectivity
import XCTest

class FluxorExplorerInterceptorTests: XCTestCase {
    var storeInterceptor: FluxorExplorerInterceptor<State>!
    var localPeerID: MCPeerID!
    var otherPeerID: MCPeerID!
    var session: MCSession!

    override func setUp() {
        super.setUp()
        storeInterceptor = FluxorExplorerInterceptor(displayName: "MyDevice", advertiserType: TestAdvertiser.self)
        localPeerID = MCPeerID(displayName: "MyDevice")
        otherPeerID = MCPeerID(displayName: "OtherDevice")
        session = MCSession(peer: otherPeerID, securityIdentity: nil, encryptionPreference: .none)
    }

    func testPublicInitializer() {
        // Given
        let publicStoreInterceptor = FluxorExplorerInterceptor<State>(displayName: "MyDevice")
        // Then
        XCTAssertFalse(publicStoreInterceptor.advertiser is TestAdvertiser)
    }

    func testInternalInitializer() {
        // Given
        let testAdvertiser = storeInterceptor!.advertiser as! TestAdvertiser
        // Then
        XCTAssertTrue(testAdvertiser.didStartAdvertisingPeer)
    }

    func testAdvertiserInvitation() {
        // Given
        let acceptedExpectation = expectation(description: debugDescription)
        // When
        var sessionFromInvitation: MCSession?
        storeInterceptor!.advertiser(storeInterceptor!.advertiser, didReceiveInvitationFromPeer: otherPeerID, withContext: nil) { accepted, session in
            XCTAssertTrue(accepted)
            sessionFromInvitation = session
            acceptedExpectation.fulfill()
        }
        // Then
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(storeInterceptor!.session, sessionFromInvitation)
    }

    func testDefaultPeerDidDisconnect() {
        // When
        storeInterceptor!.session(session, peer: otherPeerID, didChange: MCSessionState.notConnected)
        // Then
        XCTAssertTrue(true) // Nothing explodes (log statement is printed to console)
    }

    func testCustomPeerDidDisconnect() {
        // Given
        let disconnectExpectation = expectation(description: debugDescription)
        storeInterceptor.peerDidDisconnect = { disconnectedPeerID in
            XCTAssertEqual(self.otherPeerID, disconnectedPeerID)
            disconnectExpectation.fulfill()
        }
        // When
        storeInterceptor!.session(session, peer: otherPeerID, didChange: MCSessionState.notConnected)
        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testUnusedMandatorySessionDelegateCalls() {
        // When
        storeInterceptor!.session(session, didReceive: Data(), fromPeer: otherPeerID)
        storeInterceptor!.session(session, didReceive: InputStream(), withName: "Some name", fromPeer: otherPeerID)
        storeInterceptor!.session(session, didStartReceivingResourceWithName: "Some resource", fromPeer: otherPeerID, with: Progress())
        storeInterceptor!.session(session, didFinishReceivingResourceWithName: "Some resource", fromPeer: otherPeerID, at: nil, withError: nil)
        // Then
        XCTAssertTrue(true) // Nothing explodes
    }

    func testSendSnapshotLaterWhenSessionIsConnected() {
        // Given
        XCTAssertNil(storeInterceptor.session)
        XCTAssertEqual(storeInterceptor.unsentSnapshots.count, 0)
        // When
        let action = TestAction()
        storeInterceptor.actionDispatched(action: action, oldState: State(), newState: State())
        // Then
        XCTAssertEqual(storeInterceptor.unsentSnapshots.count, 1)

        // Given
        let mockSession = MCSessionSubClass(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none, connectedPeers: [otherPeerID])
        storeInterceptor.session = mockSession
        let rawData = try! JSONEncoder().encode(storeInterceptor.unsentSnapshots[0])
        // When
        storeInterceptor.session(storeInterceptor.session!, peer: otherPeerID, didChange: .connected)
        // Then
        let sentData = mockSession.sentData!
        XCTAssertEqual(sentData.data, rawData)
        XCTAssertEqual(sentData.toPeers, [otherPeerID])
        XCTAssertEqual(sentData.mode, .reliable)
        XCTAssertEqual(storeInterceptor.unsentSnapshots.count, 0)
    }

    func testDefaultDidFailSendingSnapshot() {
        // Given
        let snapshot = FluxorExplorerSnapshot(action: TestAction(), oldState: State(), newState: State())
        let mockSession = MCSessionSubClass(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none, connectedPeers: [otherPeerID])
        mockSession.shouldFailSendingData = true
        storeInterceptor.session = mockSession
        // When
        storeInterceptor.send(snapshot: snapshot)
        // Then
        XCTAssertTrue(true) // Nothing explodes (log statement is printed to console)
    }

    func testCustomDidFailSendingSnapshot() {
        // Given
        let snapshot = FluxorExplorerSnapshot(action: TestAction(), oldState: State(), newState: State())
        let mockSession = MCSessionSubClass(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none, connectedPeers: [otherPeerID])
        mockSession.shouldFailSendingData = true
        storeInterceptor.session = mockSession
        let didFailSendingExpectation = expectation(description: debugDescription)
        storeInterceptor.didFailSendingSnapshot = { failingSnapshot in
            XCTAssertEqual(snapshot, failingSnapshot)
            didFailSendingExpectation.fulfill()
        }
        // When
        storeInterceptor.send(snapshot: snapshot)
        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }
}

struct TestAction: Action, Equatable {}
struct State: Encodable {}

class TestAdvertiser: MCNearbyServiceAdvertiser {
    var didStartAdvertisingPeer = false

    override func startAdvertisingPeer() {
        didStartAdvertisingPeer = true
    }
}

class MCSessionSubClass: MCSession {
    private(set) var sentData: (data: Data, toPeers: [MCPeerID], mode: MCSessionSendDataMode)?
    private let _connectedPeers: [MCPeerID]
    var shouldFailSendingData = false

    override var connectedPeers: [MCPeerID] { _connectedPeers }

    public init(peer myPeerID: MCPeerID, securityIdentity identity: [Any]?, encryptionPreference: MCEncryptionPreference, connectedPeers: [MCPeerID]) {
        _connectedPeers = connectedPeers
        super.init(peer: myPeerID, securityIdentity: identity, encryptionPreference: encryptionPreference)
    }

    override func send(_ data: Data, toPeers peerIDs: [MCPeerID], with mode: MCSessionSendDataMode) throws {
        if shouldFailSendingData {
            throw MCError(.unknown)
        } else {
            sentData = (data, peerIDs, mode)
        }
    }
}
