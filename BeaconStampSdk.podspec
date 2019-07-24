Pod::Spec.new do |s|

  s.name          = "BeaconStampSdk"
  s.version       = "1.0.0"
  s.summary       = "Receive beacons and view coupons."
  s.description   = <<-DESC
  It is an SDK that can receive beacons and display coupons easily.
  You need an ID issued by administrator to use it.
                   DESC

  s.homepage      = "https://www.cyberagent.co.jp/"

  s.license       = { :type => "Apache License, Version 2.0", :file => "LICENSE-2.0.txt" }

  s.author        = "CyberAgent, Inc."
  s.platform      = :ios, "9.0"
  s.source        = { :git => "https://github.com/CARetailMarketing/app_beacon_sdk_ios.git", :tag => "#{s.version}" }

  s.swift_version = ['4.2', '5.0']
  s.source_files  = "BeaconStamp/**/*.{m,h,swift}"
  s.resources     = 'BeaconStamp/**/*.{xib,png}'

  s.frameworks    = "AdSupport"
  s.dependency 'AFNetworking', '~> 3.0'

end
