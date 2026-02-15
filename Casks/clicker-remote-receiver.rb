cask "clicker-remote-receiver" do
  version "1.2"
  sha256 "c93cc1b685318f5fa61d7bfb8f7e5a7896c6400e22268b7097535b5bf8ab3dc3"

  url "https://github.com/douinc/clicker/releases/download/v#{version}/ClickerRemoteReceiver-#{version}.dmg"
  name "Clicker Remote Receiver"
  desc "Presentation remote control - Mac receiver for iOS ClickerRemote app"
  homepage "https://github.com/douinc/clicker"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "ClickerRemoteReceiver.app"

  postflight do
    # Request accessibility permission on first install
    system_command "/usr/bin/osascript",
                   args: ["-e", 'tell application "System Preferences" to reveal anchor "Privacy_Accessibility" of pane id "com.apple.preference.security"'],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.dou.clicker-mac.plist",
    "~/Library/Application Support/ClickerRemoteReceiver",
  ]
end
