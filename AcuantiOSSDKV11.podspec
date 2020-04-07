Pod::Spec.new do |main|
    main.platform = :ios
    main.swift_versions = ['5.2']
    main.ios.deployment_target = '13.2'
    main.name         = "AcuantiOSSDKV11"
    main.version      = "11.4.0"
    main.summary      = "Acuant's latest SDK with most advanced image capture technology and optimized user workflow  "
      s.description  = "Acuant's latest SDK with most advanced image capture technology and optimized user workflow.

    Auto capture of documents
    Feedback on image capture quality, does several check on the captured image to ensure its optimal quality
    Optimized image capture and processing workflow (reduces bad captures and poor results)
    SDK broken down in to small different modules so that developers can include only the modules they want"
    main.homepage     = "https://github.com/Acuant/iOSSDKV11"
    main.license      = {
          :type => 'commercial',
          :text => <<-LICENSE
                  Copyright 2019 Acuant, Inc. All Rights Reserved.
                  LICENSE
    }
    main.author             = { "Acuant Inc" => "jmoon@acuantcorp.com" }
    main.source       = { :git => "https://github.com/Acuant/iOSSDKV11.git", :tag =>    "#{main.version}" }
    
    main.subspec 'AcuantCommon' do |acuantCommon|
        acuantCommon.ios.deployment_target = '11.0'
        acuantCommon.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantCommon.framework"
    end
    
    main.subspec 'AcuantImagePreparation' do |acuantImage|
        acuantImage.ios.deployment_target = '11.0'

        acuantImage.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantImagePreparation.framework"
        
        acuantImage.dependency "#{main.name}/AcuantCommon"
    end
    
    main.subspec 'AcuantDocumentProcessing' do |acuantDocument|
        acuantDocument.ios.deployment_target = '11.0'

        acuantDocument.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantDocumentProcessing.framework"
        
        acuantDocument.dependency "#{main.name}/AcuantCommon"
    end
    
    main.subspec 'AcuantFaceMatch' do |acuantFaceMatch|
        acuantFaceMatch.ios.deployment_target = '11.0'

        acuantFaceMatch.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantFaceMatch.framework"
        
        acuantFaceMatch.dependency "#{main.name}/AcuantCommon"
    end
    
    main.subspec 'AcuantPassiveLiveness' do |acuantPassive|
        acuantPassive.ios.deployment_target = '11.0'

        acuantPassive.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantPassiveLiveness.framework"
        
        acuantPassive.dependency "#{main.name}/AcuantCommon"
    end
    
    main.subspec 'AcuantHGLiveness' do |acuantHG|
        acuantHG.ios.deployment_target = '11.0'

        acuantHG.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantHGLiveness.framework"
        
        acuantHG.dependency "#{main.name}/AcuantCommon"
    end
    
    main.subspec 'AcuantIPLiveness' do |acuantIP|
        acuantIP.ios.deployment_target = '11.0'

        acuantIP.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantIPLiveness.framework"
        
        acuantIP.dependency "#{main.name}/AcuantCommon"
        acuantIP.dependency 'iProov', '~> 7.3.0'
    end
    
    main.subspec 'AcuantEchipReader' do |acuantEchip|
        acuantEchip.ios.deployment_target = '13.2'

        acuantEchip.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantEchipReader.framework"
        
        acuantEchip.dependency "#{main.name}/AcuantCommon"
    end
    
    main.subspec 'AcuantFaceCapture' do |acuantFaceCapture|
        acuantFaceCapture.ios.deployment_target = '11.0'

        acuantFaceCapture.source_files =
            "AcuantFaceCapture/AcuantFaceCapture/*.{h,swift}"

        acuantFaceCapture.dependency "#{main.name}/AcuantCommon"
    end
    
    main.subspec 'AcuantCamera' do |acuantCamera|
        acuantCamera.ios.deployment_target = '11.0'

        acuantCamera.subspec 'Document' do |document|
             document.source_files =
               "AcuantCamera/AcuantCamera/Camera/Document/*.{h,swift}",
               "AcuantCamera/AcuantCamera/Camera/Document/Delegate/*.{h,swift}"
             document.dependency "#{main.name}/AcuantCamera/Common"
         end
        
        acuantCamera.subspec 'Mrz' do |mrz|
             mrz.source_files =
               "AcuantCamera/AcuantCamera/Camera/Mrz/*.{h,swift}",
               "AcuantCamera/AcuantCamera/Camera/Mrz/OCR/*.{h,swift}",
               "AcuantCamera/AcuantCamera/Camera/Mrz/OCR/Utils/*.{h,swift}"
             mrz.dependency "#{main.name}/AcuantCamera/Common"
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
        
        
        acuantCamera.dependency "#{main.name}/AcuantCommon"
        acuantCamera.dependency "#{main.name}/AcuantImagePreparation"
    end
end
