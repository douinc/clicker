import Foundation
import MultipeerConnectivity
import WatchConnectivity
import Combine

// MARK: - iPhone Connection Manager
class iPhoneConnectionManager: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var isSearching = false
    @Published var availableMacs: [MCPeerID] = []
    @Published var connectedMac: MCPeerID?
    @Published var statusMessage = "Not connected"

    // MARK: - Multipeer Properties
    private let myPeerID: MCPeerID
    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?

    // MARK: - Reconnection & Keepalive
    private var lastConnectedMacName: String?
    private var reconnectTimer: Timer?
    private var keepaliveTimer: Timer?
    private let keepaliveInterval: TimeInterval = 3.0  // Send keepalive every 3 seconds
    private let reconnectDelay: TimeInterval = 1.0     // Wait 1 second before reconnecting

    // MARK: - Haptic Feedback
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Watch Connectivity
    private var watchSession: WCSession?

    // MARK: - Initialization
    override init() {
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        setupSession()
        setupWatchConnectivity()
        feedbackGenerator.prepare()
        startBrowsing()
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            watchSession = WCSession.default
            watchSession?.delegate = self
            watchSession?.activate()
            print("📱 WatchConnectivity activated")
        }
    }

    private func updateWatchWithConnectionStatus() {
        guard let watchSession = watchSession,
              watchSession.activationState == .activated,
              watchSession.isPaired,
              watchSession.isWatchAppInstalled else { return }

        do {
            try watchSession.updateApplicationContext(["connectedToMac": isConnected])
            print("📱 Sent connection status to watch: \(isConnected)")
        } catch {
            print("📱 Failed to update watch context: \(error.localizedDescription)")
        }
    }
    
    private func setupSession() {
        session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session?.delegate = self
    }
    
    // MARK: - Public Methods
    func startBrowsing() {
        browser = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: RemoteServiceConfig.serviceType
        )
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        isSearching = true
        statusMessage = "Searching for Mac..."
        print("🔍 Started browsing for Macs")
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isSearching = false
        print("🛑 Stopped browsing")
    }

    // MARK: - Keepalive
    private func startKeepalive() {
        stopKeepalive()
        keepaliveTimer = Timer.scheduledTimer(withTimeInterval: keepaliveInterval, repeats: true) { [weak self] _ in
            self?.sendKeepalive()
        }
        print("💓 Started keepalive timer")
    }

    private func stopKeepalive() {
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil
    }

    private func sendKeepalive() {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        guard let data = RemoteCommand.keepalive.rawValue.data(using: .utf8) else { return }

        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("💓 Sent keepalive")
        } catch {
            print("⚠️ Keepalive failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Auto Reconnect
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectDelay, repeats: false) { [weak self] _ in
            self?.attemptReconnect()
        }
    }

    private func attemptReconnect() {
        guard !isConnected else { return }

        // Recreate session for fresh connection
        setupSession()

        // Restart browsing if not already
        if browser == nil {
            startBrowsing()
        }

        // Try to reconnect to the last known Mac
        if let macName = lastConnectedMacName,
           let mac = availableMacs.first(where: { $0.displayName == macName }) {
            print("🔄 Attempting to reconnect to \(macName)")
            statusMessage = "Reconnecting to \(macName)..."
            connectTo(mac)
        } else {
            print("🔄 Waiting for Mac to reappear...")
            statusMessage = "Reconnecting..."
        }
    }
    
    func connectTo(_ peer: MCPeerID) {
        guard let browser = browser, let session = session else { return }
        
        print("📤 Inviting: \(peer.displayName)")
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        statusMessage = "Connecting to \(peer.displayName)..."
    }
    
    func disconnect() {
        // Clear last connected Mac to prevent auto-reconnect
        lastConnectedMacName = nil
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        stopKeepalive()
        session?.disconnect()
        connectedMac = nil
        isConnected = false
        statusMessage = "Disconnected"
        startBrowsing()
    }
    
    // MARK: - Send Commands
    func sendCommand(_ command: RemoteCommand) {
        guard let session = session, !session.connectedPeers.isEmpty else {
            print("⚠️ Not connected to any Mac")
            return
        }
        
        guard let data = command.rawValue.data(using: .utf8) else { return }
        
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            feedbackGenerator.impactOccurred()
            print("📤 Sent command: \(command.rawValue)")
        } catch {
            print("❌ Failed to send command: \(error.localizedDescription)")
        }
    }
    
    // Convenience methods
    func nextSlide() {
        sendCommand(.nextSlide)
    }
    
    func previousSlide() {
        sendCommand(.previousSlide)
    }
}

// MARK: - MCSessionDelegate
extension iPhoneConnectionManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ Connected to: \(peerID.displayName)")
                self.connectedMac = peerID
                self.isConnected = true
                self.lastConnectedMacName = peerID.displayName
                self.statusMessage = "Connected to \(peerID.displayName)"
                self.reconnectTimer?.invalidate()
                self.reconnectTimer = nil
                self.startKeepalive()
                self.updateWatchWithConnectionStatus()
                // Keep browsing active for faster reconnection on hotspot
                self.isSearching = false

            case .connecting:
                print("🔄 Connecting to: \(peerID.displayName)")
                self.statusMessage = "Connecting..."

            case .notConnected:
                print("❌ Disconnected from: \(peerID.displayName)")
                if self.connectedMac == peerID || self.lastConnectedMacName == peerID.displayName {
                    self.connectedMac = nil
                    self.isConnected = false
                    self.stopKeepalive()
                    self.updateWatchWithConnectionStatus()
                    // Auto-reconnect if we had a previous connection
                    if self.lastConnectedMacName != nil {
                        self.statusMessage = "Connection lost, reconnecting..."
                        self.scheduleReconnect()
                    } else {
                        self.statusMessage = "Disconnected"
                    }
                }

            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Mac could send data back (e.g., slide number, notes)
        // Not used in basic version
    }
    
    // Required delegate methods
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceBrowserDelegate
extension iPhoneConnectionManager: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🔍 Found Mac: \(peerID.displayName)")
        DispatchQueue.main.async {
            if !self.availableMacs.contains(peerID) {
                self.availableMacs.append(peerID)
            }
            // Auto-reconnect to last known Mac if we're disconnected
            if !self.isConnected,
               let lastMacName = self.lastConnectedMacName,
               peerID.displayName == lastMacName {
                print("🔄 Found previous Mac, auto-reconnecting...")
                self.connectTo(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("👋 Lost Mac: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.availableMacs.removeAll { $0 == peerID }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Failed to start browsing: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isSearching = false
            self.statusMessage = "Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - WCSessionDelegate (Watch Connectivity)
extension iPhoneConnectionManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("📱 WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("📱 WCSession activated: \(activationState.rawValue)")
            DispatchQueue.main.async {
                self.updateWatchWithConnectionStatus()
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 WCSession deactivated, reactivating...")
        session.activate()
    }

    // Handle messages from Apple Watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let command = message["command"] as? String else {
            replyHandler(["error": "Invalid command", "connectedToMac": isConnected])
            return
        }

        print("📱 Received command from watch: \(command)")

        // Relay command to Mac
        if let remoteCommand = RemoteCommand(rawValue: command) {
            DispatchQueue.main.async {
                self.sendCommand(remoteCommand)
            }
        }

        // Reply with current connection status
        replyHandler(["success": true, "connectedToMac": isConnected])
    }
}
