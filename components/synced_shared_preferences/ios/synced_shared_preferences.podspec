#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint synced_shared_preferences.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'synced_shared_preferences'
  s.version          = '0.0.1'
  s.summary          = 'Shared preferences that is synced using iCloud.'
  s.description      = <<-DESC
Shared preferences that is synced using iCloud.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
