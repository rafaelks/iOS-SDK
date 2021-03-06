#
#  Be sure to run `pod spec lint SharethroughSDK.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "SharethroughSDK"
  s.version      = "4.0.0"
  s.summary      = "SharethroughSDK for adding native ads to your app"

  s.description  = <<-DESC
                   The SharethroughSDK is the best way to monetize your app with native ads.
                   Sharethrough offers premium brand content to monetize your feeds.
                   DESC

  s.homepage     = "http://developers.sharethrough.com/"
  s.license      = {
    :type => 'Commercial',
    :text => <<-LICENSE
      ©2014 Sharethrough, Inc. All rights reserved.
    LICENSE
  }
  s.author             = { "Sharethrough Engineering" => "engineers@sharethrough.com" }
  s.social_media_url   = "https://twitter.com/SharethroughEng"
  s.source = {
    :http => "https://github.com/sharethrough/iOS-SDK/releases/download/v4.0.0/SharethroughSDK.framework.zip"
  }
  s.platform           = :ios, "8.0"
  s.preserve_paths     = "SharethroughSDK.framework"

  s.vendored_frameworks = "SharethroughSDK.framework"

  s.requires_arc = true
  s.frameworks = "MediaPlayer", "AdSupport", "CoreGraphics", "UIKit", "Foundation", "AVKit", "AVFoundation", "CoreMedia", "AVKit", "AVFoundation", "CoreMedia"
  s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '"$(PODS_ROOT)/SharethroughSDK"' }
end
