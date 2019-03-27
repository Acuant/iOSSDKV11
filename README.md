# Acuant iOS Mobile SDK v11


**Last updated  March 2019**

Copyright <sup>@</sup> 2003-2019 Acuant Inc. All rights reserved.

This document contains proprietary and confidential information and creative works owned by Acuant and its respective licensors, if any. Any use, copying, publication, distribution, display, modification, or transmission of such technology, in whole or in part, in any form or by any means, without the prior express written permission of Acuant is strictly prohibited. Except where expressly provided by Acuant in writing, possession of this information shall not be construed to confer any license or rights under any Acuant intellectual property rights, whether by estoppel, implication, or otherwise.

AssureID and *i-D*entify are trademarks of Acuant Inc. Other Acuant product or service names or logos referenced this document are either trademarks or registered trademarks of Acuant.

All 3M trademarks are trademarks of Gemalto Inc.

Windows<sup>@</sup> is a registered trademark of Microsoft Corporation.

Certain product, service, or company designations for companies other
than Acuant may be mentioned in this document for identification
purposes only. Such designations are often claimed as trademarks or
service marks. In all instances where Acuant is aware of a claim, the
designation appears in initial capital or all capital letters. However,
you should contact the appropriate companies for more complete
information regarding such designations and their registration status.

**March 2019**

<p>Acuant Inc.</p>
<p>6080 Center Drive, Suite 850</p>
<p>Los Angeles, CA 90045</p>
<p>==================</p>


# Introduction #

This document provides detailed information about the Acuant iOS SDK v11.

## Modules ##

The iOS SDK includes the following modules:

-	**AcuantCommon**
-	**AcuantImagePreparation**
-	**AcuantCamera**
-	**AcuantDocumentProcessing**
-	**AcuantHGLiveliness**
-	**AcuantFaceMatch**

### AcuantCommon###

This module contails all of the common classes required by other modules.


----------

### AcuantImagePreparation###

This module contains all image preparation functionality.


-	**Initialization**

		AcuantImagePreparation.initialize(delegate: InitializationDelegate)
	
		public protocol InitializationDelegate {
    		func initializationFinished(error: AcuantError?);
		}

- **Crop**

		public class func crop(options: CroppingOptions, data: CroppingData)->Image
		
		// CroppingOptions, and CroppingData & Image are part of AcuantCommon
		// Sample
		
		let croppingData  = CroppingData()
        croppingData.image = image // UIImage
        
   
        let croppingOptions = CroppingOptions()
        croppingOptions.isHealthCard = false
        
        let croppedImage = AcuantImagePreparation.crop(options: croppingOptions, data: croppingData)
        
        
- **Sharpness**

		public class func sharpness(image: UIImage)->Int
		
- **Glare**

		public class func glare(image: UIImage)->Int
				


----------

### AcuantCamera###

This is a completely open source project that customer can customize according to their needs. The objective of this library is to demonstrate how to capture an image using **AcuantImagePreparation**.

----------

**Note:**   **AcuantCamera** is depdendent on **AcuantImagePreparation** and  **AcuantCommon**.

----------

### AcuantDocumentProcessing ###

After a document image is captured, it can be processed using the following steps.

----------
		
**Note:**  If an upload fails with an error, retry the image upload using a better image.

----------

1. Create an instance:

		public class func createInstance(processingMode:ProcessingMode,options:IdOptions,delegate:CreateInstanceDelegate)
		
		public protocol CreateInstanceDelegate{
    		func instanceCreated(instanceId : String?,error:AcuantError?);
		}

1. Upload an image:
	
		public class func uploadImage(processingMode:ProcessingMode,instancdId:String,data:IdData,options:IdOptions,delegate:UploadImageDelegate)
		
		public protocol UploadImageDelegate{
    		func imageUploaded(error: AcuantError?,classification:Classification?);
		}

1. Get the data:

		public class func getData(instanceId:String,isHealthCard:Bool,delegate:GetDataDelegate?)
		
		public protocol UploadImageDelegate{
    		func imageUploaded(error: AcuantError?,classification:Classification?);
		}
		
1. Delete the instance:

		public class func deleteInstance(instanceId : String,type:DeleteType, delegate:DeleteDelegate)
		
		public protocol DeleteDelegate {
    		func instanceDeleted(success : Bool)
		}


----------

**Note:** There is currently no user interface (UI) customization available for this module.

----------


### AcuantHGLiveliness###

This module checks for liveliness (whether the subject is a live person) by using blink detection. The user interface code for this is contained in the Sample application (**FaceLivelinessCameraController.swift**) which customers may modify for their specific requirements.

- Create a face live capture session

		public class func getFaceCaptureSession(delegate:AcuantHGLiveFaceCaptureDelegate?,captureDevice: AVCaptureDevice?,previewSize:CGSize?)->FaceCaptureSession
		
		public protocol AcuantHGLiveFaceCaptureDelegate {
    		func liveFaceDetailsCaptured(liveFaceDetails: LiveFaceDetails?)
		}


----------
		
**Example**

		self.captureSession = AcuantHGLiveliness.getFaceCaptureSession(delegate: self,captureDevice: captureDevice,previewSize:self.view.layer.bounds.size)
		
		// Code for HG Live controller
		let liveFaceViewController = FaceLivelinessCameraController()
		liveFaceViewController.delegate = self
		AppDelegate.navigationController?.pushViewController(liveFaceViewController, animated: true)


----------
		
### AcuantFaceMatch###

This module is used to match two facial images:

		public class func processFacialMatch(facialData : FacialMatchData, delegate : FacialMatchDelegate?)
		
		public protocol FacialMatchDelegate {
    		func facialMatchFinished(result:FacialMatchResult?)
		}
		
		public class FacialMatchData{
    		public var faceImageOne : UIImage? = nil // Face Image from ID Card
    		public var faceImageTwo : UIImage? = nil // Face Image from Selfie Capture during liveliness check. This image gets compressed by 50%
   
		}


----------
		
### Using the sample application ###

1. Add the following dependent embedded frameworks:

	
 -	**AcuantCommon**
 -	**AcuantImagePreparation**
 -	**AcuantCamera**
 -	**AcuantDocumentProcessing**
 -	**AcuantHGLiveliness**
 -	**AcuantFaceMatch**
 
		![](document_images/embeded_framework.png)


1. Create a **plist** file named **AcuantConfig** which includes the following details:


    	<?xml version="1.0" encoding="UTF-8"?>
    	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    	<plist version="1.0">
    	<dict>
    		<key>acuant_username</key>
    		<string>username</string>
    		<key>acuant_password</key>
    		<string>password</string>
    		<key>acuant_subscription</key>
    		<string>XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX</string>
    		<key>frm_endpoint</key>
    		<string>https://test.frm.acuant-dev.net/api/v2</string>
    		<key>med_endpoint</key>
    		<string>https://medicscan.acuant.net/api/v1</string>
    		<key>assureid_endpoint</key>
    		<string>https://test.services.acuant-dev.net</string>
    		<key>liveliness_endpoint</key>
    		<string>https://test.frm.acuant-dev.net/api/v2</string>
    	</dict>
    	</plist>



### Error codes ###

	public struct AcuantErrorCodes{
    	public static let ERROR_InvalidCredentials = -1
    	public static let ERROR_InvalidLicenseKey = -2
    	public static let ERROR_InvalidEndpoint = -3
    	public static let ERROR_InitializationNotFinished = -4
    	public static let ERROR_Network = -5
    	public static let ERROR_InvalidJson = -6
    	public static let ERROR_CouldNotCrop = -7
    	public static let ERROR_NotEnoughMemory = -8
    	public static let ERROR_BarcodeCaptureFailed = -9
    	public static let ERROR_BarcodeCaptureTimedOut = -10
    	public static let ERROR_BarcodeCaptureNotAuthorized = -11
    	public static let ERROR_LiveFaceCaptureNotAuthorized = -12
    	public static let ERROR_CouldNotCreateConnectInstance = -13
    	public static let ERROR_CouldNotUploadConnectImage = -14
    	public static let ERROR_CouldNotUploadConnectBarcode = -15
    	public static let ERROR_CouldNotGetConnectData = -16
    	public static let ERROR_CouldNotProcessFacialMatch = -17
    	public static let ERROR_CardWidthNotSet = -18
    	public static let ERROR_CouldNotGetHealthCardData = -19
    	public static let ERROR_CouldNotClassifyDocument = -20
    	public static let ERROR_LowResolutionImage = -21
    	public static let ERROR_BlurryImage = -22
    	public static let ERROR_ImageWithGlare = -23
    	public static let ERROR_CouldNotGetIPLivelinessToken = -24
    	public static let ERROR_NotALiveFace = -25
    	public static let ERROR_CouldNotAccessLivelinessData = -26
	}

###Error descriptions###

	public struct AcuantErrorDescriptions {
    	public static let ERROR_DESC_InvalidCredentials = "Invalid credentials"
    	public static let ERROR_DESC_InvalidLicenseKey = "Invalid License Key"
    	public static let ERROR_DESC_InvalidEndpoint = "Invalid endpoint"
    	public static let ERROR_DESC_Network = "Network problem"
    	public static let ERROR_DESC_InitializationNotFinished = "Initialization not finished"
    	public static let ERROR_DESC_InvalidJson = "Invalid Json response"
    	public static let ERROR_DESC_CouldNotCrop = "Could not crop image"
    	public static let ERROR_DESC_BarcodeCaptureFailed = "Barcode capture failed"
    	public static let ERROR_DESC_BarcodeCaptureTimedOut = "Barcode capture timed out"
    	public static let ERROR_DESC_BarcodeCaptureNotAuthorized = "Barcode capture is not authorized"
    	public static let ERROR_DESC_LiveFaceCaptureNotAuthorized = "Live face capture is not authorized"
    	public static let ERROR_DESC_CouldNotCreateConnectInstance = "Could not create connect Instance"
    	public static let ERROR_DESC_CouldNotUploadConnectImage = "Could not upload image to connect instance"
    	public static let ERROR_DESC_CouldNotUploadConnectBarcode = "Could not upload barcode to connect instance"
    	public static let ERROR_DESC_CouldNotGetConnectData = "Could not get connect image data"
    	public static let ERROR_DESC_CardWidthNotSet = "Card width not set"
    	public static let ERROR_DESC_CouldNotGetHealthCardData = "Could not get health card data"
    	public static let ERROR_DESC_CouldNotClassifyDocument = "Could not classify document"
    	public static let ERROR_DESC_LowResolutionImage = "Low resolution image"
    	public static let ERROR_DESC_BlurryImage = "Blurry image"
    	public static let ERROR_DESC_ImageWithGlare = "Image has glare"
    	public static let ERROR_DESC_CouldNotGetIPLivelinessToken = "Could not get face liveliness token"
    	public static let ERROR_DESC_NotALiveFace = "Not a live face"
    	public static let ERROR_DESC_CouldNotAccessLivelinessData = "Could not access liveliness data"
	}
	
###Image###

	public class Image {
    	public var image : UIImage? = nil
    	public var hasImageMetrics : Bool = false
    	public var isBlurry : Bool = false
    	public var hasGlare : Bool = false
    	public var sharpnessGrade : Int = 0
    	public var glareGrade : Int = 0
    	public var dpi : Int = 0
    	public var error : AcuantError? = nil
    	public var isCorrectAspectRatio = false
    	public init(){}
    }


##Frequently Asked Questions##

####While publishing the app in the Apple App store we are getting an "Unsupported Architecture" error?####

All frameworks are “fat” (multi-architecture) binaries that contain *slices* for **armv7**, **arm64**, **i386**, and **x86(64)**  CPU architectures. ARM slices are used by physical iOS devices, while i386 and x86(64) are used by the simulator. 

Use the **lipo** command to check which slices are contained in the binaries:

    	lipo -info <path to the file>

You can also use the **lipo** command to remove unwanted slices:

    	lipo -remove i386 <Path to the file> -o <Output file path>

		lipo -remove x86_64 <Path to the file> -o <Output file path>