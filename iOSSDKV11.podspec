Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = '11.0'
  s.name         = "iOSSDKV11"
  s.version      = "11.1"
  s.summary      = "Acuant's latest SDK with most advanced image capture technology and optimized user workflow  "
  s.description  = "Acuant's latest SDK with most advanced image capture technology and optimized user workflow.

Auto capture of documents
Feedback on image capture quality, does several check on the captured image to ensure its optimal quality
Optimized image capture and processing workflow (reduces bad captures and poor results)
SDK broken down in to small different modules so that developers can include only the modules they want"
  s.homepage     = "https://github.com/Acuant/iOSSDKV11"
  s.license      = {
        :type => 'commercial',
        :text => <<-LICENSE
                Copyright 2019 Acuant, Inc. All Rights Reserved.
                LICENSE
  }
  s.author             = { "Acuant Inc" => "tbehera@acuantcorp.com" }
  s.source       = { :git => "https://github.com/Acuant/iOSSDKV11.git", :tag => "#{s.version}" }
  s.vendored_frameworks = 'EmbeddedFrameworks/AcuantCommon.framework'
end
