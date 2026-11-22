class Barestats < Formula
  desc "Ultra-lightweight, near-zero-overhead native system telemetry overlay for macOS, Linux, and Windows"
  homepage "https://github.com/chakrank/BareStats"
  version "1.4.0"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    url "https://github.com/chakrank/BareStats/releases/download/v#{version}/barestats-#{version}-macOS.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000" # Updated automatically on release

    def install
      if File.directory?("BareStats.app")
        bin.install "BareStats.app/Contents/MacOS/BareStats" => "barestats"
      elsif File.exist?("barestats")
        bin.install "barestats"
      end
    end
  end

  on_linux do
    url "https://github.com/chakrank/BareStats/releases/download/v#{version}/barestats-#{version}-linux-x86_64.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000" # Updated automatically on release

    def install
      bin.install "barestats"
      if File.exist?("barestats.desktop")
        (share/"applications").install "barestats.desktop"
      end
      if File.exist?("barestats.png")
        (share/"icons/hicolor/512x512/apps").install "barestats.png"
      end
      if File.exist?("barestats.svg")
        (share/"icons/hicolor/scalable/apps").install "barestats.svg"
      end
      share.install Dir["share/*"] if Dir.exist?("share")
    end
  end

  test do
    assert_match "BareStats v#{version}", shell_output("#{bin}/barestats --help")
    system "#{bin}/barestats", "--help"
  end
end
