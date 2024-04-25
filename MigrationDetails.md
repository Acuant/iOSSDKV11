# Migration Details

## v11.6.3

### Important information about upgrading from iOS SDK version 11.6.2 to version 11.6.3+

The IPLiveness module has been removed.

----------

## v11.6.2

### Important information about upgrading from iOS SDK version 11.6.0 to version 11.6.2+

The health insurance models have been updated. In particular, the ```planCodes```, ```telephones```, ```emails```, ```webs``` properties of ```HealthInsuranceCardResult``` model have changed its types as follows:

  ```swift
  public class HealthInsuranceCardResult {
    public let copayEr: String?
    public let copayOv: String?
    public let copaySp: String?
    public let copayUc: String?
    public let coverage: String?
    public let contractCode: String?
    public let dateOfBirth: String?
    public let deductible: String?
    public let effectiveDate: String?
    public let employer: String?
    public let expirationDate: String?
    public let firstName: String?
    public let groupName: String?
    public let groupNumber: String?
    public let issuerNumber: String?
    public let lastName: String?
    public let memberId: String?
    public let memberName: String?
    public let middleName: String?
    public let namePrefix: String?
    public let nameSuffix: String?
    public let other: String?
    public let payerId: String?
    public let planAdmin: String?
    public let planProvider: String?
    public let planType: String?
    public let rxBin: String?
    public let rxGroup: String?
    public let rxId: String?
    public let rxPcn: String?
    public let addresses: [Address]?
    public let planCodes: [PlanCode]?
    public let telephones: [LabelValuePair]?
    public let emails: [LabelValuePair]?
    public let webs: [LabelValuePair]?
    public let transactionId: String?
    public var instanceID: String?
    public let frontImage: UIImage?
    public let backImage: UIImage?
  }
  ```

  ```swift
  public class LabelValuePair {
    public let label: String?
    public let value: String?
  }

  public class PlanCode {
    public let planCode: String?
  }
  ```

## v11.6.0

### Important information about upgrading from iOS SDK version 11.5.x to version 11.6.0+

- Now that we support M1 based iOS simulators, you must use libtesseract.xcframework instead of TesseractOCR.framework (and remove the Carthage configuration for the latter) in order to manually integrate with the SDK and use the AcuantCamera module. In addition, the OCRB Training data must be added in a referenced folder called ***tessdata***. The latter also applies when integrating the SDK via Cocoapods.

- The interaction with document-related cameras (which includes improvements around the creation, name, and language localization), the MRZ, document cameras, and barcode cameras have been standardized as follows:

### Document Camera

#### Using the default UI

1. To get the document and barcode string, implement ```DocumentCameraViewControllerDelegate``` protocol instead of  ```CameraCaptureDelegate```.

    Implement

    ```swift
    public protocol DocumentCameraViewControllerDelegate {
      func onCaptured(image: Image, barcodeString: String?)
    }

    ```

    Instead of

    ```swift
    public protocol CameraCaptureDelegate {
      func setCapturedImage(image: Image, barcodeString: String?)
    }
    ```

2. Customize the camera using ```DocumentCameraOptions``` instead of ```CameraOptions```

    ```swift
    public enum DocumentCameraState: Int {
      case align, moveCloser, tooClose, steady, hold, capture
    }

    public class DocumentCameraOptions: CameraOptions {
      public let countdownDigits: Int
      public let timeInMillisecondsPerCountdownDigit: int
      public let textForManualCapture: String
      public let textForState: (DocumentCameraState) -> String
      public let colorForState: (DocumentCameraState) -> CGColor

      public init(countdownDigits: Int = 2,
                  timeInSecondsPerCountdownDigit: Int = 900,
                  showDetectionBox: Bool = true,
                  autoCapture: Bool = true,
                  hideNavigationBar: Bool = true,
                  showBackButton: Bool = true,
                  bracketLengthInHorizontal: Int = 80,
                  bracketLengthInVertical: Int = 50,
                  defaultBracketMarginWidth: CGFloat = 0.5,
                  defaultBracketMarginHeight: CGFloat = 0.6,
                  textForManualCapture: String = "ALIGN & TAP",
                  textForState: @escaping (DocumentCameraState) -> String = { state in
                      switch state {
                      case .align: return "ALIGN"
                      case .moveCloser: return "MOVE CLOSER"
                      case .tooClose: return "TOO CLOSE"
                      case .steady: return "HOLD STEADY"
                      case .hold: return "HOLD"
                      case .capture: return "CAPTURING"
                      @unknown default: return ""
                      }
                  },
                  colorForState: @escaping (DocumentCameraState) -> CGColor = { state in
                      switch state {
                      case .align: return UIColor.black.cgColor
                      case .moveCloser: return UIColor.red.cgColor
                      case .tooClose: return UIColor.red.cgColor
                      case .steady: return UIColor.yellow.cgColor
                      case .hold: return UIColor.yellow.cgColor
                      case .capture: return UIColor.green.cgColor
                      @unknown default: return UIColor.black.cgColor
                      }
                  },
                  textForCameraPaused: String = "CAMERA PAUSED",
                  backButtonText: String = "BACK")
    }
    ```

    - ```DocumentCameraState``` enum cases are now in lower case
    - ```digitsToShow``` is now ```countdownDigits```
    - ```timeInMsPerDigit``` is now ```timeInMillisecondsPerCountdownDigit```
    - ```allowBox``` is now ```showDetectionBox```
    - ```colorHold```, ```colorCapturing```, ```colorBracketAlign```, ```colorBracketCloser```, ```colorBracketHold```, ```colorBracketCapture```
    are now removed in favor of ```colorForState```
    - Regarding language localization, the document camera does no longer read from the app's localizable files. The strings are now expected to be passed using ```textForState```, ```textForManualCapture```, ```textForCameraPaused``` and ```backButtonText``` properties.

3. Create and open the camera.

    Implement

    ```swift
    let opions = DocumentCameraOptions()
    let documentCameraViewController = DocumentCameraViewController(options: options)
    documentCameraViewController.delegate = self
    navigationController.pushViewController(documentCameraViewController, animated: false)
    ```

    Instead of

    ```swift
    let options = CameraOptions()
    let documentCameraController = DocumentCameraController.getCameraController(delegate: self, cameraOptions: options)
    navigationController.pushViewController(documentCameraController, animated: false)
    ```

#### Using a custom UI

1. To get the image and barcode string, implement ```DocumentCaptureSessionDelegate``` protocol instead of ```DocumentCaptureDelegate```.

    Implement

    ```swift
    public protocol DocumentCaptureSessionDelegate {
      func readyToCapture()
      func documentCaptured(image: UIImage, barcodeString: String?)
    }
    ```

    Instead of

    ```swift
    public protocol DocumentCaptureDelegate {
      func readyToCapture() 
      func documentCaptured(image: UIImage, barcodeString: String?)
    } 
    ```

2. (Optionally) Implement AutoCaptureDelegate and/or FrameAnalysisDelegate protocols. The latter changed as follows:

    ```swift
    public protocol FrameAnalysisDelegate {
      func onFrameAvailable(frameResult: FrameResult, points: [CGPoint]?)
    }
    ```

    Instead of

    ```swift
    public protocol FrameAnalysisDelegate {
      func onFrameAvailable(frameResult: FrameResult, points: Array<CGPoint>?)
    }
    ```

    Additionally ```FrameResult``` enum cases are now in lower case

    Implement

    ```swift
    public enum FrameResult: Int {
        case noDocument, smallDocument, badAspectRatio, goodDocument, documentNotInFrame
    }
    ```

    Instead of

    ```swift
    public enum FrameResult: Int {
      case NO_DOCUMENT, SMALL_DOCUMENT, BAD_ASPECT_RATIO, GOOD_DOCUMENT, DOCUMENT_NOT_IN_FRAME
    }
    ```

3. Create a capture session

    Implement

    ```swift
    let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
    let captureSession = DocumentCaptureSession(captureDevice: captureDevice)
    captureSession.delegate = self
    captureSession.autoCaptureDelegate = self
    captureSession.frameDelegate = self
    ```

    Instead of

    ```swift
    let captureSession = DocumentCaptureSession.getDocumentCaptureSession(delegate: self,
                                                                          frameDelegate: self,
                                                                          autoCaptureDelegate: self,
                                                                          captureDevice: captureDevice)
    ```

4. Starting, stopping, and enabling capture remains unchanged.

### Barcode Camera

1. To get the barcode string, implement ```BarcodeCameraViewControllerDelegate``` protocol instead of ```BarcodeCameraDelegate``` .

    Implement

    ```swift
    public protocol BarcodeCameraViewControllerDelegate: AnyObject {
        func onCaptured(barcode: String?)
    }
    ```

    Instead of

    ```swift
    public protocol BarcodeCameraDelegate: AnyObject {
      func captured(barcode: String?)
    }
    ```

2. Customize the camera using ```BarcodeCameraOptions``` instead of ```CameraOptions```.

    ```swift
    public enum BarcodeCameraState: Int {
      case align
      case capturing
    }

    public class BarcodeCameraOptions: CameraOptions {
      public let waitTimeAfterCapturingInSeconds: Int
      public let timeoutInSeconds: Int
      public let textForState: (BarcodeCameraState) -> String
      public let colorForState: (BarcodeCameraState) -> CGColor

      public init(hideNavigationBar: Bool = true,
                  showBackButton: Bool = true,
                  waitTimeAfterCapturingInSeconds: Int = 1,
                  timeoutInSeconds: Int = 20,
                  textForState: @escaping (BarcodeCameraState) -> String = { state in
                      switch state {
                      case .align: return "CAPTURE BARCODE"
                      case .capturing: return "CAPTURING"
                      @unknown default: return ""
                      }
                  },
                  colorForState: @escaping (BarcodeCameraState) -> CGColor = { state in
                      switch state {
                      case .align: return UIColor.white.cgColor
                      case .capturing: return UIColor.green.cgColor
                      @unknown default: return UIColor.white.cgColor
                      }
                  },
                  textForCameraPaused: String = "CAMERA PAUSED",
                  backButtonText: String = "BACK",
                  placeholderImageName: String? = "barcode_placement_overlay")
    }
    ```

    - ```timeInMsPerDigit``` is now ```waitTimeAfterCapturingInSeconds```
    - ```digitsToShow``` is now ```timeoutInSeconds```
    - ```colorHold``` and ```colorCapturing``` are now removed in favor of ```colorForState``` property
    - Regarding language localization, the barcode camera does no longer read from the app's localizable files. The strings are now expected to be passed using ```textForState```, ```textForCameraPaused``` and ```backButtonText``` properties.

3. Create and open the camera.

    Implement

    ```swift
    let options = BarcodeCameraOptions(waitTimeAfterCapturingInSeconds: 1, timeoutInSeconds: 20)
    let barcodeCamera = BarcodeCameraViewController(options: options)
    barcodeCamera.delegate = self
    navigationController?.pushViewController(barcodeCamera, animated: false)
    ```

    Instead of

    ```swift
    let options = CameraOptions(timeInMsPerDigit: 1000,
                                digitsToShow: 20,
                                colorHold: UIColor.white.cgColor,
                                colorCapturing: UIColor.green.cgColor)
    let barcodeCamera = BarcodeCameraViewController(options: options, delegate: self)
    navigationController?.pushViewController(barcodeCamera, animated: false)
    ```

### MRZ Camera

1. To get the MRZ result, implement ```MrzCameraViewControllerDelegate``` protocol instead of the view controller's ```callback``` property.

    Implement

    ```swift
    public protocol MrzCameraViewControllerDelegate: AnyObject {
      func onCaptured(mrz: AcuantMrzResult?)
    }
    ```

    Instead of

    ```swift
    acuantMrzCameraController.callback: ((AcuantMrzResult?) -> Void)?
    ```

2. Customize camera using ```MrzCameraOptions``` instead of ```CameraOptions```.

    ```swift
    public enum MrzCameraState: Int {
      case none, align, moveCloser, tooClose, reposition, good, captured
    }

    public class MrzCameraOptions: CameraOptions {
      public let textForState: (MrzCameraState) -> String
      public let colorForState: (MrzCameraState) -> CGColor

      public init(showDetectionBox: Bool = true,
                  bracketLengthInHorizontal: Int = 50,
                  bracketLengthInVertical: Int = 40,
                  defaultBracketMarginWidth: CGFloat = 0.58,
                  defaultBracketMarginHeight: CGFloat = 0.63,
                  hideNavigationBar: Bool = true,
                  showBackButton: Bool = true,
                  placeholderImageName: String? = "Passport_placement_Overlay",
                  textForState: @escaping (MrzCameraState) -> String = { state in
                      switch state {
                      case .none, .align: return ""
                      case .moveCloser: return "Move Closer"
                      case .tooClose: return "Too Close!"
                      case .good: return "Reading MRZ"
                      case .captured: return "Captured"
                      case .reposition: return "Reposition"
                      @unknown default: return ""
                      }
                  },
                  colorForState: @escaping (MrzCameraState) -> CGColor = { state in
                      switch state {
                      case .none, .align: return UIColor.black.cgColor
                      case .moveCloser: return UIColor.red.cgColor
                      case .tooClose: return UIColor.red.cgColor
                      case .good: return UIColor.yellow.cgColor
                      case .captured: return UIColor.green.cgColor
                      case .reposition: return UIColor.red.cgColor
                      @unknown default: return UIColor.black.cgColor
                      }
                  },
                  textForCameraPaused: String = "CAMERA PAUSED",
                  backButtonText: String = "BACK")
    }
    ```

    - ```MrzCameraState``` enum cases are now in lower case
    - ```colorHold```, ```colorCapturing```, ```colorReposition```, ```colorBracketAlign```, ```colorBracketCloser```, ```colorBracketHold```, ```colorBracketCapture```
        are now removed in favor of ```colorForState```
    - Regarding language localization, the mrz camera does no longer expose ```customDisplayMessage``` property. The strings are now expected to be passed using ```textForState```, ```textForCameraPaused``` and ```backButtonText``` properties.
    - ```allowBox``` is now ```showDetectionBox```

3. Create and open the camera.

    Implement

    ```swift
    let textForState: (MrzCameraState) -> String = { state in
      switch state {
      case .none, .align: return ""
      case .moveCloser: return "Move Closer"
      case .tooClose: return "Too Close!"
      case .good: return "Reading MRZ"
      case .captured: return "Captured"
      case .reposition: return "Reposition"
      @unknown default: return ""
      }
    }
    let options = MrzCameraOptions(textForState: textForState)
    let mrzCameraViewController = MrzCameraViewController(options: options)
    mrzCameraViewController.delegate = self
    navigationController?.pushViewController(mrzCameraViewController, animated: false)
    ```

    Instead of

    ```swift
    let vc = AcuantMrzCameraController()
    vc.options = CameraOptions()
    vc.customDisplayMessage: ((MrzCameraState) -> String) = { state in
      switch state {
        case .None, .Align:
          return ""
        case .MoveCloser:
          return "Move Closer"
        case .TooClose:
          return "Too Close!"
        case .Reposition:
          return "Reposition"
        case .Good:
          return "Reading MRZ"
        case .Captured:
          return "Captured"
      }
    }
    vc.callback: ((AcuantMrzResult?) -> Void)? = { [weak self] result in
      if let success = result {
        DispatchQueue.main.async {
          //pop or dismiss the View Controller
          self?.navigationController?.popViewController(animated: true)
        }
      } else {
        //User Canceled
      }
    }
    navigationController?.pushViewController(controller, animated: false)
    ```

### HGLiveness Camera

- A new face state (FACE_HAS_ANGLE) was added to determine whether the face has roll or yaw angle. The possible states are as follows:

  ```swift
  public enum AcuantFaceType: Int {
      case NONE
      case FACE_TOO_CLOSE
      case FACE_MOVED
      case FACE_TOO_FAR
      case FACE_GOOD_DISTANCE
      case FACE_NOT_IN_FRAME
      case FACE_HAS_ANGLE
  }
  ```

### Updated models returned by web calls

The Document, Classification, Health Insurance, Passive Liveness and Ozone models have been updated. The structure of these models has been modified to more closely match the structure of the model returned through the web call. This modification reduces ambiguity and enables future fields in the web model to be mapped more easily to the Swift model. Fields also will more closely match their type (int to int, boolean to boolean, etc.) whereas, in the past, most fields were read as strings. Fields that represent an emun are now parsed into the appropriate enum. The unparsed value is still exposed if a new enum value is added in the web result and not yet mapped to the Swift model.

Breakdowns of the new Swift models are shown below. Although these models might seem overwhelming, large portions remain unchanged from the previous version.

### Document + Classification

  IDResult

```swift
  public let instanceID: String
  public let unparsedAuthenticationSensitivity: Int
  public var authenticationSensitivity: AuthenticationSensitivity?
  public let engineVersion: String?
  public let libraryVersion: String?
  public let unparsedProcessMode: Int
  public var processMode: DocumentProcessMode?
  public var unparsedResult: Int
  public var result: AuthenticationResult?
  public let subscription: Subscription?
  public let biographic: Biographic?
  public let classification: Classification?
  public let device: DeviceInfo?
  public let alerts: [DocumentAlert]?
  public let dataFields: [DocumentDataField]?
  public let fields: [DocumentField]?
  public let images: [DocumentImage]?
  public let regions: [DocumentRegion]?
  public let unparsedTamperResult: Int
  public var tamperResult: AuthenticationResult?
  public let unparsedTamperSensitivity: Int
  public var tamperSensitivity: TamperSensitivity?

```

DocumentAlert

```swift
  public let actions: String?
  public let actionDescription: String?
  public let disposition: String?
  public let id: String
  public let information: String?
  public let key: String?
  public let name: String?
  public let unparsedResult: Int
  public var result: AuthenticationResult?
  public let model: String?
```

Biographic

```swift
  public let age: Int
  public let birthDate: String?
  public let expirationDate: String?
  public let fullName: String?
  public let unparsedGender: Int
  public var gender: GenderType?
  public var photo: String?
```

Classification

```swift
  public let unparsedMode: Int
  public var mode: ClassificationMode?
  public let orientationChanged: Bool
  public let presentationChanged: Bool
  public let classificationDetails: ClassificationDetails?
  public let type: DocumentType?
```

ClassificationDetails

```swift
  public let front: DocumentType?
  public let back: DocumentType?
```

DocumentType

```swift
  public let unparsedDocumentClass: Int
  public var documentClass: DocumentClass?
  public let classCode: String?
  public let className: String?
  public let countryCode: String?
  public let geographicRegions: [String]?
  public let id: String
  public let isGeneric: Bool
  public let issue: String?
  public let issueType: String?
  public let issuerCode: String?
  public let issuerName: String?
  public let unparsedIssuerType: Int
  public var issuerType: IssuerType?
  public let keesingCode: String?
  public let name: String?
  public let unparsedSize: Int
  public var size: DocumentSize?
  public let referenceDocumentDataTypes: [DocumentDataType]?
  public let documentDataTypes: [DocumentDataType]?
  public let supportedImages: [DocumentImageType]
```

DocumentImageType

```swift
  public let unparsedLight: Int
  public var light: LightSource?
  public let unparsedSide: Int
  public var side: DocumentSide?
```

DocumentDataField

```swift
  public let dataSource: Int
  public let fieldDescrption: String?
  public let id: String?
  public let isImage: Bool
  public let key: String?
  public let regionOfInterest: Rectangle?
  public let regionReference: String?
  public let reliability: Double
  public let type: String?
  public let value: String?
```

Rectangle

```swift
  public let height: Int
  public let width: Int
  public let x: Int
  public let y: Int
```

DeviceInfo

```swift
  public let hasContactlessChipReader: Bool
  public let hasMagneticStripeReader: Bool
  public let serialNumber: String?
  public let type: DeviceType?
```

DeviceType

```swift
  public let manufacturer: String?
  public let model: String?
  public let unparsedSensorType: Int
  public var sensorType: SensorType?
```

DocumentField

```swift
  public let unparsedDataSource: Int
  public var dataSource: DocumentDataSource?
  public let fieldDescription: String?
  public let id: String
  public let isImage: Bool
  public let key: String?
  public let name: String?
  public let regionReference: String?
  public let type: String?
  public let value: String?
  public let dataFieldReference: [String]?
```

DocumentImage

```swift
  public let horizontalResolution: Int
  public let verticalResolution: Int
  public let unparsedSide: Int
  public var side: DocumentSide?
  public let unparsedLight: Int
  public var light: LightSource?
  public let isCropped: Bool
  public let isTampered: Bool
  public let glareMetric: UInt8?
  public let sharpnessMetric: UInt8?
  public let id: String
  public let mimeType: String?
  public let uri: String?
```

DocumentRegion

```swift
  public let unparsedDocumentElement: Int
  public var documentElement: DocumentElement?
  public let imageReference: String
  public let key: String?
  public let id: String?
  public let rectangle: Rectangle?
```

Subscription

```swift
  public let unparsedDocumentProcessMode: Int
  public var documentProcessMode: DocumentProcessMode?
  public let id: String
  public let isActive: Bool
  public let isDevelopment: Bool
  public let isTrial: Bool
  public let name: String?
  public let storePII: Bool
```

### Document + Classification Enums

```swift
  public enum AuthenticationResult: Int {
    case unknown, passed, failed, skipped, caution, attention

    public var name: String
  }

  public enum AuthenticationSensitivity: Int  {
    case normal, high, low
  }

  public enum ClassificationMode: Int {
    case automatic, manual
  }

  public enum DocumentClass: Int {
    case unknown
    case passport
    case visa
    case driversLicense
    case identificationCard
    case permit
    case currency
    case residenceDocument
    case travelDocument
    case birthCertificate
    case vehicleRegistration
    case other
    case weaponLicense
    case tribalIdentification
    case voterIdentification
    case military
    case consularIdentification
  }

  public enum DocumentDataSource: Int {
    case none
    case barcode1D
    case barcode2D
    case contactlessChip
    case machineReadableZone
    case magneticStripe
    case visualInspectionZone
    case other
  }

  public enum DocumentDataType: Int {
    case barcode2D, machineReadableZone, magneticStripe
  }

  public enum DocumentElement: Int {
    case unknown, none, photo, data, substrate, overlay
  }

  public enum DocumentProcessMode: Int {
    case `default`, captureData, authenticate, barcode
  }

  public enum DocumentSide: Int {
    case front, back
  }

  public enum DocumentSize: Int {
    case unknown, id1, id2, id3, letter, checkCurrency, custom
  }

  public enum GenderType: Int {
    case unspecified, male, female, unknown
  }

  public enum IssuerType: Int {
    case unknown, country, stateProvince, tribal, municipality, business, other
  }

  public enum LightSource: Int {
    case white, nearInfrared, ultravioletA, coaxialWhite, coaxialNearInfrared
  }

  public enum SensorType: Int {
    case unknown, camera, scanner, mobile
  }
```

Additionally `CardSide` was removed in favor of `DocumentSide`.

### Health Insurance

HealthInsuranceCardResult

```swift
  public let copayEr: String?
  public let copayOv: String?
  public let copaySp: String?
  public let copayUc: String?
  public let coverage: String?
  public let contractCode: String?
  public let dateOfBirth: String?
  public let deductible: String?
  public let effectiveDate: String?
  public let employer: String?
  public let expirationDate: String?
  public let firstName: String?
  public let groupName: String?
  public let groupNumber: String?
  public let issuerNumber: String?
  public let lastName: String?
  public let memberId: String?
  public let memberName: String?
  public let middleName: String?
  public let namePrefix: String?
  public let nameSuffix: String?
  public let other: String?
  public let payerId: String?
  public let planAdmin: String?
  public let planProvider: String?
  public let planType: String?
  public let rxBin: String?
  public let rxGroup: String?
  public let rxId: String?
  public let rxPcn: String?
  public let addresses: [Address]?
  public let planCodes: [String]?
  public let telephones: [String: String]?
  public let emails: [String: String]?
  public let webs: [String: String]?
  public let transactionId: String?
  public var instanceID: String?
  public let frontImage: UIImage?
  public let backImage: UIImage?
```

Address

```swift
  let fullAddress: String?
  let street: String?
  let city: String?
  let state: String?
  let zip: String?
```

### Passive Liveness Enums

```swift
  public enum AcuantLivenessAssessment: String {
    case error = "Error"
    case poorQuality = "PoorQuality"
    case live = "Live"
    case notLive = "NotLive"
  }

  public enum AcuantLivenessErrorCode: String {
    case unknown = "Unknown"
    case faceTooClose = "FaceTooClose"
    case faceNotFound = "FaceNotFound"
    case faceTooSmall = "FaceTooSmall"
    case faceAngleTooLarge = "FaceAngleTooLarge"
    case failedToReadImage = "FailedToReadImage"
    case invalidRequest = "InvalidRequest"
    case invalidRequestSettings = "InvalidRequestSettings"
    case unauthorized = "Unauthorized"
    case notFound = "NotFound"
    case internalError = "InternalError"
    case invalidJson = "InvalidJson"
  }
```

### Ozone Enums

OzoneResultStatus

```swift
  public enum OzoneResultStatus: Int {
    case success
    case failed
    case unknown
    case notPerformed
  }
```

## v11.5.8

### Important information about upgrading from iOS SDK version 11.5.x to version 11.5.8+

- If you use a custom UI to capture a document (using only DocumentCaptureSession class), the start method now starts the capture session asynchronously on a background queue. The start method receives a completion handler to notify the caller after the session is started. This handler is optional and is dispatched on the main queue.

## v11.5.7

### Important information about upgrading from iOS SDK version 11.5.x to version 11.5.7+

- A new MRZ state (Reposition) was added to determine whether the reading is taking too long. The possible states are as follows:

```swift

public enum MrzCameraState: Int {
  case None, Align, MoveCloser, TooClose, Reposition, Good, Captured
}
```

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
