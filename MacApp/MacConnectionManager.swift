import Foundation
import MultipeerConnectivity
import Combine

// MARK: - Mac Connection Manager
class MacConnectionManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAdvertising = false
    @Published var connectedDevices: [MCPeerID] = []
    @Published var lastCommand: RemoteCommand?
    @Published var statusMessage = "Not running"
    
    // MARK: - Multipeer Properties
    private let myPeerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    
    // MARK: - Callback for keystroke
    var onCommandReceived: ((RemoteCommand) -> Void)?
    
    // MARK: - Initialization
    override init() {
        self.myPeerID = MCPeerID(displayName: Host.current().localizedName ?? "Mac")
        super.init()
        setupSession()
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
    func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: RemoteServiceConfig.serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        isAdvertising = true
        statusMessage = "Waiting for iPhone to connect..."
        print("📡 Started advertising as: \(myPeerID.displayName)")
    }
    
    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isAdvertising = false
        statusMessage = "Stopped"
        print("🛑 Stopped advertising")
    }
    
    func disconnect() {
        session?.disconnect()
        connectedDevices.removeAll()
        statusMessage = "Disconnected"
    }
}

// MARK: - MCSessionDelegate
extension MacConnectionManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ Connected to: \(peerID.displayName)")
                if !self.connectedDevices.contains(peerID) {
                    self.connectedDevices.append(peerID)
                }
                self.statusMessage = "Connected to \(peerID.displayName)"
                
            case .connecting:
                print("🔄 Connecting to: \(peerID.displayName)")
                self.statusMessage = "Connecting to \(peerID.displayName)..."
                
            case .notConnected:
                print("❌ Disconnected from: \(peerID.displayName)")
                self.connectedDevices.removeAll { $0 == peerID }
                if self.connectedDevices.isEmpty {
                    self.statusMessage = "Waiting for iPhone to reconnect..."
                    // Ensure we're still advertising for reconnection
                    if self.advertiser == nil {
                        self.startAdvertising()
                    }
                } else {
                    self.statusMessage = "Connected to \(self.connectedDevices.count) device(s)"
                }
                
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Decode the command
        guard let commandString = String(data: data, encoding: .utf8),
              let command = RemoteCommand(rawValue: commandString) else {
            print("⚠️ Failed to decode command")
            return
        }
        
        print("📥 Received command: \(command.rawValue) from \(peerID.displayName)")
        
        DispatchQueue.main.async {
            self.lastCommand = command
            self.onCommandReceived?(command)
        }
    }
    
    // Required delegate methods (not used but must be implemented)
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MacConnectionManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📨 Received invitation from: \(peerID.displayName)")
        // Auto-accept invitations (you could add UI for manual approval)
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Failed to start advertising: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isAdvertising = false
            self.statusMessage = "Error: \(error.localizedDescription)"
        }
    }
}
