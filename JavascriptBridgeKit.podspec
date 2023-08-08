Pod::Spec.new do |s|
  s.name             = 'JavascriptBridgeKit'
  s.version          = '0.1.0'
  s.summary          = 'A short description of AJSBridge.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/arcangelw/JavascriptBridgeKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'arcangel-w' => 'wuzhezmc@gmail.com' }
  s.source           = { :git => 'https://github.com/arcangelw/JavascriptBridgeKit.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.swift_version = ['5']
  
  s.subspec 'Core' do |sub|
    sub.source_files  = "Sources/JavascriptBridgeKit/Core/**/*.swift"
    sub.dependency = 'JavascriptBridgeKit/ObjC'
    sub.dependency = 'AnyCodable-FlightSchool'
  end
  
  s.subspec 'ObjC' do |sub|
    sub.source_files  = "Sources/JavascriptBridgeKit/ObjC/**/*.{h,m,mm}"
  end

  s.source_files = 'Sources/JavascriptBridgeKit/Exports/*.swift'
  s.default_subspecs = 'Core'
  s.frameworks  = 'WebKit', "UIKit", "Foundation"
end
