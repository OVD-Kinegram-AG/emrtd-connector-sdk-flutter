#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint emrtd.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'emrtd'
  s.version          = '0.0.1'
  s.summary          = 'Kinegram eMRTD Connector'
  s.description      = <<-DESC
The Kinegram eMRTD Connector enables your Flutter app to read and verify
electronic passports / id cards (a.ka. eMRTDs).
                       DESC
  s.homepage         = 'http://www.kinegram.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'OVD Kinegram AG' => 'digitalsolutions@kinegram.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'KinegramEmrtdConnector', '~> 2.1.0'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'emrtd_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
