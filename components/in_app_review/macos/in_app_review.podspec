#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint in_app_review.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'in_app_review'
  s.version          = '0.2.0'
  s.summary          = 'Flutter plugin for showing the In-App Review/System Rating pop up.'
  s.description      = <<-DESC
  Flutter plugin for showing the In-App Review/System Rating pop up.
                       DESC
  s.homepage         = 'https://github.com/britannio/in_app_review'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Britannio Jarrett' => 'britanniojarrett@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
