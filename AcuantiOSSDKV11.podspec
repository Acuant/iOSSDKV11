Pod::Spec.new do |s|
    s.platform = :ios
    s.swift_versions = ['5.5.2']
    s.ios.deployment_target = '11.0'
    s.name         = "AcuantiOSSDKV11"
    s.version      = "11.5.6"
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
                  Copyright 2021 Acuant, Inc. All Rights Reserved.
                  LICENSE
    }
    s.author             = { "Acuant Inc" => "smaltsev@acuant.com" }
    s.source       = { :git => "https://github.com/Acuant/iOSSDKV11.git", :tag =>    "#{s.version}" }
    
    s.pod_target_xcconfig = {
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

    s.subspec 'AcuantCommon' do |acuantCommon|
        acuantCommon.ios.deployment_target = '11.0'
        acuantCommon.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantCommon.xcframework"
    end
    
    s.subspec 'AcuantImagePreparation' do |acuantImage|
        acuantImage.ios.deployment_target = '11.0'

        acuantImage.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantImagePreparation.xcframework"
        
        acuantImage.dependency "#{s.name}/AcuantCommon"
    end
    
    s.subspec 'AcuantDocumentProcessing' do |acuantDocument|
        acuantDocument.ios.deployment_target = '11.0'

        acuantDocument.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantDocumentProcessing.xcframework"
        
        acuantDocument.dependency "#{s.name}/AcuantCommon"
    end
    
    s.subspec 'AcuantFaceMatch' do |acuantFaceMatch|
        acuantFaceMatch.ios.deployment_target = '11.0'

        acuantFaceMatch.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantFaceMatch.xcframework"
        
        acuantFaceMatch.dependency "#{s.name}/AcuantCommon"
    end
    
    s.subspec 'AcuantPassiveLiveness' do |acuantPassive|
        acuantPassive.ios.deployment_target = '11.0'

        acuantPassive.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantPassiveLiveness.xcframework"
        
        acuantPassive.dependency "#{s.name}/AcuantCommon"
    end
    
    s.subspec 'AcuantHGLiveness' do |acuantHG|
        acuantHG.ios.deployment_target = '11.0'

        acuantHG.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantHGLiveness.xcframework"
        
        acuantHG.dependency "#{s.name}/AcuantCommon"
    end
    
    s.subspec 'AcuantIPLiveness' do |acuantIP|
        acuantIP.ios.deployment_target = '11.0'

        acuantIP.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantIPLiveness.xcframework"
        
        acuantIP.dependency "#{s.name}/AcuantCommon"
        acuantIP.dependency 'iProov', '~> 9.2.0'
    end
    
    s.subspec 'AcuantEchipReader' do |acuantEchip|
        acuantEchip.ios.deployment_target = '11.0'

        acuantEchip.ios.vendored_frameworks = "EmbeddedFrameworks/AcuantEchipReader.xcframework"
        
        acuantEchip.dependency "#{s.name}/AcuantCommon"
        acuantEchip.dependency 'OpenSSL-Universal', '1.1.1400'
    end
    
    s.subspec 'AcuantFaceCapture' do |acuantFaceCapture|
        acuantFaceCapture.ios.deployment_target = '11.0'

        acuantFaceCapture.source_files =
            "AcuantFaceCapture/AcuantFaceCapture/*.{h,swift}",
            "AcuantFaceCapture/AcuantFaceCapture/View/*.{h,swift}",
            "AcuantFaceCapture/AcuantFaceCapture/Models/*.{h,swift}",
            "AcuantFaceCapture/AcuantFaceCapture/Extension/*.{h,swift}"

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
             mrz.ios.vendored_frameworks = "EmbeddedFrameworks/TesseractOCR.framework"
         end

        acuantCamera.subspec 'Barcode' do |barcode|
            barcode.source_files = "AcuantCamera/AcuantCamera/Camera/Barcode/*.{h,swift}"
            barcode.dependency "#{s.name}/AcuantCamera/Common"
        end
        
        acuantCamera.subspec 'Common' do |common|
            common.source_files =
                "AcuantCamera/AcuantCamera/View/*.{h,swift}",
                "AcuantCamera/AcuantCamera/Extension/*.{h,swift}",
                "AcuantCamera/AcuantCamera/Constant/*.{h,swift}",
                "AcuantCamera/AcuantCamera/Camera/*.{h,swift}"
            common.resource_bundles = { 'AcuantCameraAssets' => [ 'AcuantCamera/AcuantCamera/*.xcassets'] }
        end

        acuantCamera.source_files = "AcuantCamera/AcuantCamera/*.{h,swift}"

        acuantCamera.dependency "#{s.name}/AcuantCommon"
        acuantCamera.dependency "#{s.name}/AcuantImagePreparation"
    end
end
