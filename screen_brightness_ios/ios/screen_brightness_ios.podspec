#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint screen_brightness_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'screen_brightness_ios'
  s.version          = '0.1.0'
  s.summary          = 'The iOS federated plugin implementation of the screen_brightness.'
  s.description      = <<-DESC
The iOS federated plugin implementation of the screen_brightness.
                       DESC
  s.homepage         = 'https://github.com/aaassseee/screen_brightness'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jack Liu' => 'ywp033319@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
