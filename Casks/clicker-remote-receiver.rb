cask("clicker-remote-receiver") do
  version("1.10")
  sha256("88763a4fb888c1f595b5862a38e19b12d5426f62b135e81c8b6f5607e8a257aa")

  url("https://github.com/douinc/clicker/releases/download/v#{version}/ClickerRemoteReceiver-#{version}.dmg")
  name("Clicker Remote Receiver")
  desc("Presentation remote control - Mac receiver for iOS ClickerRemote app")
  homepage("https://github.com/douinc/clicker")

  livecheck do
    url(:url)
    strategy(:github_latest)
  end

  depends_on(macos: ">= :sonoma")

  app("ClickerRemoteReceiver.app")

  postflight do
    # Open Accessibility privacy pane so user can grant permission
    system_command(
      "/usr/bin/open",
      args: ["x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"],
      sudo: false
    )
  end

  zap(
    trash: [
      "~/Library/Preferences/com.dou.clicker-mac.plist",
      "~/Library/Application Support/ClickerRemoteReceiver"
    ]
  )
end