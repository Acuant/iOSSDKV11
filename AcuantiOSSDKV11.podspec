Pod::Spec.new do |s|
    s.platform = :ios
    s.swift_versions = ['5.2']
    s.ios.deployment_target = '11.0'
    s.name         = "AcuantiOSSDKV11"
    s.version      = "11.4.4"
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
    s.author             = { "Acuant Inc" => "jmoon@acuantcorp.com" }
    s.source       = { :git => "https://github.com/Acuant/iOSSDKV11.git", :tag =>    "#{s.version}" }
    
    s.subspec 'AcuantCommon' do |acuantCommon|
        acuantCommon.ios.deployment_target = '11.0'
        acuantCommon.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantCommon.framework"
    end
    
    s.subspec 'AcuantImagePreparation' do |acuantImage|
        acuantImage.ios.deployment_target = '11.0'

        acuantImage.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantImagePreparation.framework"
        
        acuantImage.dependency "#{s.name}/AcuantCommon"
    end
    
    s.subspec 'AcuantDocumentProcessing' do |acuantDocument|
        acuantDocument.ios.deployment_target = '11.0'

        acuantDocument.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantDocumentProcessing.framework"
        
        acuantDocument.dependency "#{s.name}/AcuantCommon"
    end
    
    s.subspec 'AcuantFaceMatch' do |acuantFaceMatch|
        acuantFaceMatch.ios.deployment_target = '11.0'

        acuantFaceMatch.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantFaceMatch.framework"
        
        acuantFaceMatch.dependency "#{s.name}/AcuantCommon"
    end
    
    s.subspec 'AcuantPassiveLiveness' do |acuantPassive|
        acuantPassive.ios.deployment_target = '11.0'

        acuantPassive.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantPassiveLiveness.framework"
        
        acuantPassive.dependency "#{s.name}/AcuantCommon"
    end
    
    s.subspec 'AcuantHGLiveness' do |acuantHG|
        acuantHG.ios.deployment_target = '11.0'

        acuantHG.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantHGLiveness.framework"
        
        acuantHG.dependency "#{s.name}/AcuantCommon"
    end
    
    s.subspec 'AcuantIPLiveness' do |acuantIP|
        acuantIP.ios.deployment_target = '11.0'

        acuantIP.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantIPLiveness.framework"
        
        acuantIP.dependency "#{s.name}/AcuantCommon"
        acuantIP.dependency 'iProov', '~> 7.5.0'
    end
    
    s.subspec 'AcuantEchipReader' do |acuantEchip|
        acuantEchip.ios.deployment_target = '11.0'

        acuantEchip.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantEchipReader.framework"
        
        acuantEchip.dependency "#{s.name}/AcuantCommon"
    end
    
    s.subspec 'AcuantFaceCapture' do |acuantFaceCapture|
        acuantFaceCapture.ios.deployment_target = '11.0'

        acuantFaceCapture.source_files =
            "AcuantFaceCapture/AcuantFaceCapture/*.{h,swift}"

        acuantFaceCapture.dependency "#{s.name}/AcuantCommon"
        acuantFaceCapture.dependency "#{s.name}/AcuantImagePreparation"
    end
    
    s.subspec 'AcuantCamera' do |acuantCamera|
        acuantCamera.ios.deployment_target = '11.0'

        acuantCamera.subspec 'Document' do |document|
             document.source_files =
               "AcuantCamera/AcuantCamera/Camera/Document/*.{h,swift}",
               "AcuantCamera/AcuantCamera/Camera/Document/Delegate/*.{h,swift}"
             document.dependency "#{s.name}/AcuantCamera/Common"
         end
        
        acuantCamera.subspec 'Mrz' do |mrz|
             mrz.source_files =
               "AcuantCamera/AcuantCamera/Camera/Mrz/*.{h,swift}",
               "AcuantCamera/AcuantCamera/Camera/Mrz/OCR/*.{h,swift}",
               "AcuantCamera/AcuantCamera/Camera/Mrz/OCR/Utils/*.{h,swift}"
             mrz.dependency "#{s.name}/AcuantCamera/Common"
             mrz.dependency 'TesseractOCRiOS', '~> 5.0.1'
             mrz.resources = "AcuantCamera/AcuantCamera/Camera/Mrz/*.xcassets"
         end
        
         acuantCamera.subspec 'Common' do |common|
              common.source_files =
                "AcuantCamera/AcuantCamera/View/*.{h,swift}",
                "AcuantCamera/AcuantCamera/Extension/*.{h,swift}",
                "AcuantCamera/AcuantCamera/Constant/*.{h,swift}",
                "AcuantCamera/AcuantCamera/Camera/*.{h,swift}"
         end
        
        acuantCamera.source_files =
            "AcuantCamera/AcuantCamera/*.{h,swift}"
        
        
        acuantCamera.dependency "#{s.name}/AcuantCommon"
        acuantCamera.dependency "#{s.name}/AcuantImagePreparation"
    end
end
