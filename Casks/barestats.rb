cask "barestats" do
  version "1.4.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000" # Updated automatically on release

  url "https://github.com/chakrank/BareStats/releases/download/v#{version}/barestats-#{version}-macOS.dmg"
  name "BareStats"
  desc "Ultra-lightweight, near-zero-overhead native system telemetry overlay for macOS, Linux, and Windows"
  homepage "https://github.com/chakrank/BareStats"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "BareStats.app"
  binary "#{appdir}/BareStats.app/Contents/MacOS/BareStats", target: "barestats"

  zap trash: [
    "~/Library/Application Support/BareStats",
    "~/Library/Logs/BareStats",
  ]
end
