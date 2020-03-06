Pod::Spec.new do |s|
  s.swift_versions = ['5.1']
  s.platform = :ios
  s.ios.deployment_target = '11.0'
  s.name         = "AcuantiOSSDKV11"
  s.version      = "11.3.2"
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
  s.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantCommon.framework" , "EmbeddedFrameworks/AcuantDocumentProcessing.framework",
  "EmbeddedFrameworks/AcuantFaceMatch.framework","EmbeddedFrameworks/AcuantHGLiveness.framework","EmbeddedFrameworks/AcuantImagePreparation.framework","EmbeddedFrameworks/AcuantIPLiveness.framework","EmbeddedFrameworks/AcuantPassiveLiveness.framework"
  s.source_files = ['SampleApp/SampleApp/AcuantConfig.plist']
  s.subspec 'AcuantCamera' do |acuantcamera|
    acuantcamera.source_files = "AcuantCamera/AcuantCamera/*.{h,swift}", "AcuantCamera/AcuantCamera/View/*.{h,swift}"
    acuantcamera.ios.vendored_frameworks  = "EmbeddedFrameworks/AcuantCommon.framework","EmbeddedFrameworks/AcuantImagePreparation.framework"
  end

  s.subspec 'AcuantFaceCapture' do |acuantfacecapture|
    acuantfacecapture.source_files = "AcuantFaceCapture/AcuantFaceCapture/*.{h,swift}"
  end

  s.dependency 'iProov', '~> 7.2.2'
end
