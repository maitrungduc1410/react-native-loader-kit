require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

if ENV["RCT_NEW_ARCH_ENABLED"] == "0"
  raise "react-native-loader-kit 5 requires the New Architecture (RCT_NEW_ARCH_ENABLED is '0'). " \
        "For the old architecture, install react-native-loader-kit@v4-lts."
end

# The vendored LoaderKit Swift sources need iOS 15.
min_ios_version = [min_ios_version_supported, "15.0"].max_by { |version| Gem::Version.new(version) }

Pod::Spec.new do |s|
  s.name         = "LoaderKit"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version }
  s.source       = { :git => "https://github.com/maitrungduc1410/react-native-loader-kit.git", :tag => "#{s.version}" }
  s.swift_version = "5.9"

  s.source_files = "ios/**/*.{h,m,mm,swift}"
  s.private_header_files = "ios/**/*.h"
  s.frameworks   = "QuartzCore"

  install_modules_dependencies(s)
end
