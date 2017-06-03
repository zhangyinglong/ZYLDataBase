#
# Be sure to run `pod lib lint ZYLDataBase.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZYLDataBase'
  s.version          = '0.1.0'
  s.summary          = 'ORM机制的sqlite数据库.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
使用run-time实现ORM机制的sqlite数据库，支持加密
                       DESC

  s.homepage         = 'https://github.com/zhangyinglong/ZYLDataBase'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhangyinglong' => 'zyl04401@gmail.com' }
  s.source           = { :git => 'https://github.com/zhangyinglong/ZYLDataBase.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.module_name  = 'ZYLDataBase'
  s.requires_arc          = true
  s.ios.deployment_target = '8.0'
  s.compiler_flags = '-DSQLITE_HAS_CODEC'
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
  s.user_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }

  s.source_files = 'ZYLDataBase/**/*.{h,m}'
  s.public_header_files = 'ZYLDataBase/Database.h','ZYLDataBase/DatabaseServiece.h','ZYLDataBase/BaseModel.h'
  s.vendored_libraries = 'ZYLDataBase/**/*.a'
  s.libraries = 'z', 'sqlite3'

  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
