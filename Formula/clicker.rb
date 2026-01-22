# Homebrew Cask for ClickerRemoteReceiver Mac App
# This file should be placed in your homebrew-tap repository
# Users install via: brew install --cask douinc/tap/Clickerremotereceiver

cask("Clickerremotereceiver") do
  version("1.0.0")
  # Update with actual SHA256 after first release
  sha256(:no_check)

  url("https://github.com/douinc/clicker/releases/download/v#{version}/ClickerRemoteReceiver.dmg")
  name("ClickerRemoteReceiver")
  desc("Presentation remote control - Mac receiver for iOS ClickerRemote app")
  homepage("https://github.com/douinc/clicker")

  livecheck do
    url(:url)
    strategy(:github_latest)
  end

  depends_on(macos: ">= :sonoma")

  app("ClickerRemoteReceiver.app")

  zap(
    trash: [
      "~/Library/Preferences/com.dou.clicker-mac.plist",
      "~/Library/Application Support/ClickerRemoteReceiver"
    ]
  )
end
