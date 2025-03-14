require 'json'
package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name         = "react-native-image-crop-view"
  s.version      = package['version']
  s.summary      = package['description']
  s.license      = package['license']
  s.authors      = package['author']
  s.homepage     = package['repository']['url']
  s.platform     = :ios, "13.0"
  s.source       = { :git => package['repository']['url'], :tag => "v#{s.version}" }
  s.source_files = "**/*.{h,m,mm,swift}"
  
  s.dependency "React-Core"
  s.dependency "TOCropViewController"
  
  s.swift_version = '5.0'
end