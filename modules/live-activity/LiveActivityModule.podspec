require "json"

Pod::Spec.new do |s|
  s.name         = "LiveActivityModule"
  s.version      = "1.0.0"
  s.summary      = "React Native bridge to iOS Live Activities (ActivityKit)"
  s.homepage     = "https://github.com/Vishamberlalcahwla/react-native-live-activities"
  s.license      = "MIT"
  s.authors      = "Vishamber Lal"
  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/Vishamberlalcahwla/react-native-live-activities.git" }
  s.source_files = "ios/**/*.{h,m,mm,swift}"
  s.swift_version = "5.9"
  # Weak-linked so the app still launches on iOS versions without ActivityKit
  s.weak_frameworks = "ActivityKit"

  # Adds React-Core and the New Architecture dependencies
  install_modules_dependencies(s)
end
