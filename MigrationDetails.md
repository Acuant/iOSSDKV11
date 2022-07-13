# Migration Details

----------

## v11.5.6

### Important information about upgrading from iOS SDK version 11.5.x to version 11.5.6+

- Because the PACE protocol is now supported by the AcuantEchipReader module, to integrate with the SDK manually, you have to add OpenSSL.xcframework as a dependency.

## v11.5.5

### Important information about upgrading from iOS SDK version 11.5.x to version 11.5.5+

- The callback in FaceCaptureController now receives a FaceCaptureResult instead of a UIImage. The former holds an UImage and its corresponding JPEG data.

- AcuantLivenessRequest now holds the image as JPEG data instead of a UIImage.

- FacialMatchData changed its properties name to faceOneData and faceTwoData. Both are of type Data instead of UIImage.

- In HGLivenessDelegate, liveFaceCapture function now receives a HGLivenessResult instead of a UIImage. The former holds the UIImage and its corresponding JPEG data.

----------

## v11.5.1

### Important information about upgrading from iOS SDK version 11.4.x to version 11.5.1+

To support Xcode 12.5, Acuant iOS SDK v11 is now distributed through XCFramework files instead of Framework files. To work around a bug in Swift, several class names have changed. Refer to the following list and update your implementation accordingly:

- AcuantCameraOptions -> CameraOptions

- AcuantCameraMetaData -> CameraMetaData

- AcuantCameraTextView -> CameraTextView

- AcuantDocumentProcessing -> DocumentProcessing

- AcuantEchipReader -> EchipReader

- IAcuantEchipReader -> IEchipReader

- AcuantFaceCaptureController -> FaceCaptureController

- FaceAcuantCameraOptions -> FaceCameraOptions

- AcuantFaceMatch -> FaceMatch

- AcuantHGLiveness -> HGLiveness

- AcuantHGLivenessDelegate -> HGLivenessDelegate

- AcuantImagePreparation -> ImagePreparation

- AcuantImagePreparationPackage -> ImagePreparationPackage

- AcuantIPLiveness -> IPLiveness

- AcuantPassiveLiveness -> PassiveLiveness

- IAcuantPassiveLivenessService -> IPassiveLivenessService

- AcuantPassiveLivenessService -> PassiveLivenessService

Users of **IPLiveness** must implement two new callbacks: livenessTestConnecting() and livenessTestConnected(). This will allow the user to display any desired form of connecting message and the IPLiveness UI will only appear when it is fully ready for capture. In addition, users of IPLiveness might need to review localization as some strings have changed.

----------

## v11.4.0

### Important information about upgrading from iOS SDK version 11.3.x or earlier to version 11.4.x using CocoaPods

The Acuant iOS SDK v11 now has a minimum target of iOS 13.2. Each module has been divided into subpods.

- To use the entire SDK, add the parent pod AcuantiOSSDKV11:

    ``` pod 'AcuantiOSSDKV11' ```

The **minimum target is iOS 11** unless stated otherwise.

- To include a specific pod in the SDK:

    | ``` pod 'AcuantiOSSDKV11/AcuantCamera' ``` | |
    | ----------- | ----------- |
    | Use document camera only      | ``` pod 'AcuantiOSSDKV11/AcuantCamera/Document' ``` |
    | Use passport MRZ camera only  | ``` pod 'AcuantiOSSDKV11/AcuantCamera/Mrz' ```     |
    | Import library in Swift       | ``` import AcuantiOSSDKV11 ```                      |

    | ``` pod 'AcuantiOSSDKV11/AcuantImagePreparation' ``` | |
    | ----------- | ----------- |
    | Import library in Swift       | ``` import AcuantImagePreparation ```     |

    | ``` pod 'AcuantiOSSDKV11/AcuantFaceCapture' ``` | |
    | ----------- | ----------- |
    | Import library in Swift       | ``` import AcuantFaceCapture ```     |

    | ``` pod 'AcuantiOSSDKV11/AcuantEchipReader' ``` | |
    | ----------- | ----------- |
    | The **minimum target is iOS 13.2** | |
    | Import library in Swift       | ``` import AcuantEchipReader ```     |

    | ``` pod 'AcuantiOSSDKV11/AcuantHGLiveness' ``` | |
    | ----------- | ----------- |
    | Import library in Swift       | ``` import AcuantHGLiveness ```     |

    | ``` pod 'AcuantiOSSDKV11/AcuantIPLiveness' ``` | |
    | ----------- | ----------- |
    | Import library in Swift       | ``` import AcuantIPLiveness ```     |

    | ``` pod 'AcuantiOSSDKV11/AcuantPassiveLiveness' ``` | |
    | ----------- | ----------- |
    | Import library in Swift       | ``` import AcuantPassiveLiveness ``` |

    | ``` pod 'AcuantiOSSDKV11/AcuantDocumentProcessing' ``` | |
    | ----------- | ----------- |
    | Import library in Swift       | ``` import AcuantDocumentProcessing ``` |

### Aditional notes

- Refactored the SDK initialization. You will need to pass in packages to the  ``` AcuantInitializer ``` (``` IAcuantInitializer ```).

  - The package that can be initialized is ``` AcuantImagePreparation ```

  - (```AcuantImagePreparationPackage```) and ```AcuantEchipReader``` (```AcuantEchipPackage```)

- ``` AcuantCamera ```

  - Added MRZ capture

  - Depends on iOS Tesseract

  - If you do not need the new MRZ capture, you can exclude adding the dependency and remove the “Mrz” directory from the ``` AcuantCamera ``` project

- ``` AcuantEchipReader ```
  
  - Requires iOS 13.2
  
  - If you want to add the ``` AcuantEchipReader ``` to your project, you have to upgrade your application target to iOS version 13.2 or later.

  - Remove “NFC Data Exchange” Item in entitlement file
