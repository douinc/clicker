import Foundation
import MultipeerConnectivity
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
    
    // MARK: - Haptic Feedback
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // MARK: - Initialization
    override init() {
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        setupSession()
        feedbackGenerator.prepare()
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
    
    func connectTo(_ peer: MCPeerID) {
        guard let browser = browser, let session = session else { return }
        
        print("📤 Inviting: \(peer.displayName)")
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        statusMessage = "Connecting to \(peer.displayName)..."
    }
    
    func disconnect() {
        session?.disconnect()
        connectedMac = nil
        isConnected = false
        statusMessage = "Disconnected"
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
                self.statusMessage = "Connected to \(peerID.displayName)"
                self.stopBrowsing()
                
            case .connecting:
                print("🔄 Connecting to: \(peerID.displayName)")
                self.statusMessage = "Connecting..."
                
            case .notConnected:
                print("❌ Disconnected from: \(peerID.displayName)")
                if self.connectedMac == peerID {
                    self.connectedMac = nil
                    self.isConnected = false
                    self.statusMessage = "Disconnected"
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
