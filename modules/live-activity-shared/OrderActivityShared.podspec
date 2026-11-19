Pod::Spec.new do |s|
  s.name          = "OrderActivityShared"
  s.version       = "1.0.0"
  s.summary       = "ActivityAttributes shared by the app and the Live Activity widget extension"
  s.homepage      = "https://github.com/Vishamberlalcahwla/react-native-live-activities"
  s.license       = "MIT"
  s.authors       = "Vishamber Lal"
  s.platforms     = { :ios => "15.1" }
  s.source        = { :git => "https://github.com/Vishamberlalcahwla/react-native-live-activities.git" }
  s.source_files  = "ios/**/*.swift"
  s.swift_version = "5.9"
  s.weak_frameworks = "ActivityKit"
  # Extension-safe: no React dependency, no UIApplication.shared
  s.pod_target_xcconfig = { "APPLICATION_EXTENSION_API_ONLY" => "YES" }
end
