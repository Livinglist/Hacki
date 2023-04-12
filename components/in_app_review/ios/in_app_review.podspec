#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint in_app_review.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'in_app_review'
  s.version          = '0.2.0'
  s.summary          = 'Flutter plugin for showing the In-App Review/System Rating pop up.'
  s.description      = <<-DESC
  Flutter plugin for showing the In-App Review/System Rating pop up..
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Britannio Jarrett' => 'britanniojarrett@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
