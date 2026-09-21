#
# Be sure to run `pod lib lint AKPageFlipperCollectionView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AKPageFlipperCollectionView'
  s.version          = '0.1.4'
  s.summary          = 'A custom UICollectionView layout and control that provides realistic 3D page flipping transitions.'

  s.description      = <<-DESC
AKPageFlipperCollectionView is a high-performance, plug-and-play UICollectionView subclass and custom layout for iOS. It provides realistic 3D page-folding and page-flipping transition effects with support for both vertical and horizontal orientations.
                       DESC

  s.homepage         = 'https://github.com/AurangzaibKhan1994/AKPageFlipperCollectionView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'AurangzaibKhan1994' => 'aurangzaibasadkhan1994@gmail.com' }
  s.source           = { :git => 'https://github.com/AurangzaibKhan1994/AKPageFlipperCollectionView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '15.6'
  s.swift_version = '5.0'

  s.source_files = 'AKPageFlipperCollectionView/Classes/**/*', '**/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AKPageFlipperCollectionView' => ['AKPageFlipperCollectionView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
