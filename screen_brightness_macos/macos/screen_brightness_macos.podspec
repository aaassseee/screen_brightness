#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint screen_brightness_macos.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'screen_brightness_macos'
  s.version          = '0.1.0'
  s.summary          = 'The macOS federated plugin implementation of the screen_brightness.'
  s.description      = <<-DESC
The macOS federated plugin implementation of the screen_brightness.
                       DESC
  s.homepage         = 'https://github.com/aaassseee/screen_brightness'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jack Liu' => 'ywp033319@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
