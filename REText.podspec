#
# Be sure to run `pod lib lint REText.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'REText'
  s.version          = '0.1.1'
  s.summary          = 'A modern Swift framework with enhanced text rendering'

  s.description      = <<-DESC
  A modern Swift framework with enhanced text rendering
                       DESC

  s.homepage         = 'https://github.com/reers/REText'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Asura19' => 'x.rhythm@qq.com' }
  s.source           = { :git => 'https://github.com/reers/REText.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  # s.tvos.deployment_target = "13.0"
  # s.visionos.deployment_target = "1.0"
  
  s.swift_versions = '6.0'

  s.source_files = 'Sources/**/*'

end
