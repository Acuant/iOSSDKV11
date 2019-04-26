//
//  ViewController.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/5/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import UIKit
import AcuantImagePreparation
import AcuantCamera
import AcuantCommon
import AcuantDocumentProcessing
import AcuantFaceMatch
import AcuantHGLiveness
import AcuantIPLiveness

class RootViewController: UIViewController , InitializationDelegate,CreateInstanceDelegate,UploadImageDelegate,GetDataDelegate, FacialMatchDelegate,DeleteDelegate,AcuantHGLivenessDelegate,LivenessTestDelegate,CameraCaptureDelegate{
    
    public var capturedFrontImage : UIImage?
    public var capturedBackImage : UIImage?
    public var capturedLiveFace : UIImage?
    public var capturedBarcodeString : String?
    public var documentInstance : String?
    public var isProcessing : Bool = false
    public var isLiveFace : Bool = false
    public var isProcessingFacialMatch : Bool = false
    public var capturedFacialMatchResult : FacialMatchResult? = nil
    public var capturedFaceImageUrl : String? = nil
    public var isHealthCard : Bool = false
    public var isRetrying : Bool = false
    
    public var idOptions : IdOptions? = nil
    public var idData : IdData? = nil
    
    var side : CardSide = CardSide.Front
    var captureWaitTime = 0
    var minimumNumberOfClassificationAttemptsRequired = 1
    var numerOfClassificationAttempts = 0
    
    @IBOutlet var medicalCardButton: UIButton!
    @IBOutlet var idPassportButton: UIButton!
    
    @IBAction func idPassportTapped(_ sender: UIButton) {
        resetData()
        showDocumentCaptureCamera()
    }
    
    @IBAction func healthCardTapped(_ sender: UIButton) {
        resetData()
        isHealthCard = true
        showDocumentCaptureCamera()
    }
    
    func showDocumentCaptureCamera(){
        let documentCameraController = DocumentCameraController.getCameraController(delegate:self,captureWaitTime:captureWaitTime)
        AppDelegate.navigationController?.pushViewController(documentCameraController, animated: false)
    }
    
    func resetData(){
        side = CardSide.Front
        captureWaitTime = 0
        numerOfClassificationAttempts = 0
        isProcessing = false
        isLiveFace = false
        isHealthCard = false
        isRetrying = false
        isProcessingFacialMatch = false
        capturedFrontImage = nil
        capturedBackImage = nil
        capturedLiveFace = nil
        capturedBarcodeString = nil
        capturedFaceImageUrl = nil
        capturedFacialMatchResult = nil
        documentInstance = nil
        idOptions = nil
        idData = nil
    }
    
    func showFacialCaptureInterface(){
        self.isProcessingFacialMatch = true
        //Code for IP liveness
        //AcuantIPLiveness.showLiveFaceCaptureInterface(del: self)
        
         //Code for HG Live controller
        let liveFaceViewController = FaceLivenessCameraController()
        liveFaceViewController.delegate = self
        AppDelegate.navigationController?.pushViewController(liveFaceViewController, animated: true)
    }

    
    func showResult(data:Array<String>?,front:String?,back:String?,sign:String?,face:String?){
        DispatchQueue.global().async {
            if(Credential.endpoints().frmEndpoint != nil){
                while(self.isProcessingFacialMatch == true){
                    sleep(1)
                }
            }
            DispatchQueue.main.async {
                self.vcUtil.hideActivityIndicator(uiView: self.view)
                let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                let resultViewController = storyBoard.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
                
                if(self.capturedFacialMatchResult != nil){
                    var dataWithFacialData = data
                    dataWithFacialData?.insert("Face matched :\(self.capturedFacialMatchResult!.isMatch)", at: 0)
                    
                    dataWithFacialData?.insert("Face Match score :\(self.capturedFacialMatchResult!.score!)", at: 0)
                    
                    if(self.isLiveFace){
                        dataWithFacialData?.insert("Is live Face : true", at: 0)
                    }else{
                        dataWithFacialData?.insert("Is live Face : false", at: 0)
                    }
                    
                    resultViewController.data = dataWithFacialData
                }else{
                    resultViewController.data = data
                }
                resultViewController.frontImageUrl = front
                resultViewController.backImageUrl = back
                resultViewController.signImageUrl = sign
                resultViewController.faceImageUrl = face
                resultViewController.username = Credential.username()
                resultViewController.password = Credential.password()
                AppDelegate.navigationController?.pushViewController(resultViewController, animated: true)
            }
            
        }
    }
    
    func showHealthCardResult(data:Array<String>?,front:UIImage?,back:UIImage?){
        DispatchQueue.main.async {
            self.vcUtil.hideActivityIndicator(uiView: self.view)
            let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
            let resultViewController = storyBoard.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
            
            
            resultViewController.data = data
            
            resultViewController.front = front
            resultViewController.back = back
            AppDelegate.navigationController?.pushViewController(resultViewController, animated: true)
        }
        
    }
    
    
    // Delegate if MiniLiveFaceSDK is used
    func liveFaceCaptured(image: UIImage?) {
        processFacialMatch(image: image!)
    }
    
    func livenessSetupdone() {
        
    }
    
    func livenessTestdone() {
        
    }
    
    // Delegate if LiveFaceSDK is used
    func livenessTestSucceeded(image: UIImage?) {
        processFacialMatch(image: image!)
    }
    
    func livenessTestFailed(error:AcuantError) {
        capturedLiveFace = nil
        isLiveFace = false
        self.isProcessingFacialMatch = false
    }
    
    func processFacialMatch(image:UIImage){
        capturedLiveFace = image
        isLiveFace = true
        self.vcUtil.showActivityIndicator(uiView: self.view, text: "Processing...")
        DispatchQueue.global().async {
            while(self.isProcessing == true){
                sleep(1)
            }
            if(self.capturedFaceImageUrl != nil){
                self.isProcessingFacialMatch = true
                let loginData = String(format: "%@:%@", Credential.username(), Credential.password()).data(using: String.Encoding.utf8)!
                let base64LoginData = loginData.base64EncodedString()
                
                // create the request
                let url = URL(string: self.capturedFaceImageUrl!)!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let httpURLResponse = response as? HTTPURLResponse
                    if(httpURLResponse?.statusCode == 200){
                        let downloadedImage = UIImage(data: data!)
                        
                        let facialMatchData = FacialMatchData()
                        facialMatchData.faceImageOne = downloadedImage
                        facialMatchData.faceImageTwo = self.capturedLiveFace
                        AcuantFaceMatch.processFacialMatch(facialData: facialMatchData, delegate: self)
                    }else {
                        self.isProcessingFacialMatch = false
                        return
                    }
                    }.resume()
            }else{
                self.isProcessingFacialMatch = false
                DispatchQueue.main.async {
                    self.vcUtil.hideActivityIndicator(uiView: self.view)
                }
                
            }
        }
    }
    
    public func liveFaceCaptured(image:UIImage){
        capturedLiveFace = image
        isLiveFace = true
        self.vcUtil.showActivityIndicator(uiView: self.view, text: "Processing...")
        DispatchQueue.global().async {
            while(self.isProcessing == true){
                sleep(1)
            }
            if(self.capturedFaceImageUrl != nil){
                self.isProcessingFacialMatch = true
                let loginData = String(format: "%@:%@", Credential.username(), Credential.password()).data(using: String.Encoding.utf8)!
                let base64LoginData = loginData.base64EncodedString()
                
                // create the request
                let url = URL(string: self.capturedFaceImageUrl!)!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let httpURLResponse = response as? HTTPURLResponse
                    if(httpURLResponse?.statusCode == 200){
                        let downloadedImage = UIImage(data: data!)
                        
                        let facialMatchData = FacialMatchData()
                        facialMatchData.faceImageOne = downloadedImage
                        facialMatchData.faceImageTwo = self.capturedLiveFace
                        AcuantFaceMatch.processFacialMatch(facialData: facialMatchData, delegate: self)
                    }else {
                        self.isProcessingFacialMatch = false
                        return
                    }
                    }.resume()
            }else{
                self.isProcessingFacialMatch = false
                DispatchQueue.main.async {
                    self.vcUtil.hideActivityIndicator(uiView: self.view)
                }
                
            }
        }
    }
    public func setCapturedImage(image:Image, barcodeString:String?){
        self.vcUtil.showActivityIndicator(uiView: self.view, text: "Processing...")
        
        if(barcodeString != nil){
            capturedBarcodeString = barcodeString
        }
        let croppedImage = cropImage(image: image.image!)
            
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                if(croppedImage?.image == nil || (croppedImage?.error != nil && croppedImage?.error?.errorCode != AcuantErrorCodes.ERROR_LowResolutionImage)){
                    CustomAlerts.display(
                        message: (croppedImage?.error?.errorDescription)!,
                        action: UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default, handler: { (action:UIAlertAction) in self.retryCapture() }))
                }
                else{
                    let sharpness = AcuantImagePreparation.sharpness(image:croppedImage!.image!)
                    let glare = AcuantImagePreparation.glare(image:croppedImage!.image!)
                    self.vcUtil.hideActivityIndicator(uiView: self.view)
                    
                    let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                    let confirmController = storyBoard.instantiateViewController(withIdentifier: "ConfirmationViewController") as! ConfirmationViewController
                    confirmController.sharpness = sharpness
                    confirmController.glare = glare
                    if(self.side==CardSide.Front){
                        confirmController.side = CardSide.Front
                    }else{
                        confirmController.side = CardSide.Back
                    }
                    if(barcodeString != nil){
                        confirmController.barcodeCaptured = true
                        confirmController.barcodeString = barcodeString
                    }
                    confirmController.image = croppedImage
                    AppDelegate.navigationController?.pushViewController(confirmController, animated: true)
                }
                self.vcUtil.hideActivityIndicator(uiView: self.view)
            }
        }
    }
    
    func cropImage(image:UIImage)->Image?{
        let croppingData  = CroppingData()
        croppingData.image = image
        
        let croppingOptions = CroppingOptions()
        croppingOptions.isHealthCard = false
        
        let croppedImage = AcuantImagePreparation.crop(options: croppingOptions, data: croppingData)
        return croppedImage
    }
    
    public func confirmImage(image:UIImage,side:CardSide){
        if(side==CardSide.Front){
            capturedFrontImage = image
            if(isHealthCard){
                let alert = UIAlertController(title: "Back Side?", message: "Scan the back side of the health insurance card", preferredStyle:UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                { action -> Void in
                    self.side = CardSide.Back
                    self.captureWaitTime = 0
                    self.showDocumentCaptureCamera()
                })
                alert.addAction(UIAlertAction(title: "SKIP", style: UIAlertAction.Style.default)
                { action -> Void in
                    self.processHealthCard()
                })
                self.present(alert, animated: true, completion: nil)
            }else{
                // Create instance
                self.vcUtil.showActivityIndicator(uiView: self.view, text: "Classifying...")
                
                idOptions = IdOptions()
                idOptions?.cardSide = CardSide.Front
                idOptions?.isHealthCard = false
                idOptions?.isRetrying = isRetrying
                
                idData = IdData()
                idData?.image = capturedFrontImage
                if(isRetrying){
                    numerOfClassificationAttempts = numerOfClassificationAttempts + 1
                    AcuantDocumentProcessing.uploadImage(processingMode: ProcessingMode.Authentication,instancdId: documentInstance!, data: idData!, options: idOptions!, delegate: self)
                }else{
                    AcuantDocumentProcessing.createInstance(processingMode: ProcessingMode.Authentication,options: idOptions!, delegate:self)
                }
                
            }
        }else{
            if(isHealthCard){
                capturedBackImage = image
                processHealthCard()
            }else{
                capturedBackImage = image
                self.vcUtil.showActivityIndicator(uiView: self.view, text: "Processing...")
                
                idOptions = IdOptions()
                idOptions?.cardSide = CardSide.Back
                idOptions?.isHealthCard = false
                idOptions?.isRetrying = false
                
                idData = IdData()
                idData?.image = capturedBackImage
                AcuantDocumentProcessing.uploadImage(processingMode: ProcessingMode.Authentication,instancdId: documentInstance!, data: idData!, options: idOptions!, delegate: self)
            }
            
        }
        
    }
    
    func instanceCreated(instanceId: String?, error: AcuantError?) {
        if(error == nil){
            documentInstance = instanceId
            if(isHealthCard){
                // Upload front image
                idData?.barcodeString=nil
                idData?.image=capturedFrontImage
                
                idOptions?.isHealthCard = true
                idOptions?.cardSide = CardSide.Front
                idOptions?.isRetrying = false
                AcuantDocumentProcessing.uploadImage(processingMode: ProcessingMode.Authentication,instancdId: documentInstance!, data: idData!, options: idOptions!, delegate: self)
                
            }else{
                // Upload and Classify ID/Passport image
                AcuantDocumentProcessing.uploadImage( processingMode: ProcessingMode.Authentication,instancdId: documentInstance!, data: idData!, options: idOptions!, delegate: self)
            }
        }else{
            CustomAlerts.displayError(message: "\(error!.errorCode!) : " + (error?.errorDescription)!)
        }
    }
    
    func imageUploaded(error: AcuantError?,classification:Classification?) {
        if(error == nil || (error?.errorCode == AcuantErrorCodes.ERROR_CouldNotClassifyDocument && numerOfClassificationAttempts>=minimumNumberOfClassificationAttemptsRequired)){
            if(isHealthCard){
                if(idOptions?.cardSide == CardSide.Front){
                    if(capturedBackImage == nil){
                        // Get Data
                        AcuantDocumentProcessing.getData(instanceId: documentInstance!, isHealthCard: true, delegate: self)
                    }else{
                        // upload back image
                        idData?.barcodeString=nil
                        idData?.image=capturedBackImage
                        
                        idOptions?.isHealthCard = true
                        idOptions?.cardSide = CardSide.Back
                        idOptions?.isRetrying = false
                        AcuantDocumentProcessing.uploadImage( processingMode: ProcessingMode.Authentication,instancdId: documentInstance!, data: idData!, options: idOptions!, delegate: self)
                    }
                }else{
                    // Get Data
                    AcuantDocumentProcessing.getData(instanceId: documentInstance!, isHealthCard: true, delegate: self)
                }
            }else{
                self.vcUtil.hideActivityIndicator(uiView: self.view)
                if(idOptions?.cardSide == CardSide.Front){
                    if(isBackSideRequired(classification: classification)){
                        // Capture Back Side
                        let alert = UIAlertController(title: "Back Side?", message: "Scan the back side of the ID document", preferredStyle:UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                        { action -> Void in
                            self.side = CardSide.Back
                            self.captureWaitTime = 1
                            self.showDocumentCaptureCamera()
                        })
                        self.present(alert, animated: true, completion: nil)
                    }else{
                        // Get Data
                        if(Credential.endpoints().frmEndpoint != nil){
                            showFacialCaptureInterface()
                        }
                        self.isProcessing = true
                        AcuantDocumentProcessing.getData(instanceId: documentInstance!, isHealthCard: false, delegate: self)
                        self.vcUtil.showActivityIndicator(uiView: self.view, text: "Processing...")
                    }
                }else{
                    // Get Data
                    if(Credential.endpoints().frmEndpoint != nil){
                        showFacialCaptureInterface()
                    }
                    self.isProcessing = true
                    AcuantDocumentProcessing.getData(instanceId: documentInstance!, isHealthCard: false, delegate: self)
                    self.vcUtil.showActivityIndicator(uiView: self.view, text: "Processing...")
                    
                }
            }
        }else{
            self.vcUtil.hideActivityIndicator(uiView: self.view)
            if(error?.errorCode == AcuantErrorCodes.ERROR_CouldNotClassifyDocument){
                let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                let errorController = storyBoard.instantiateViewController(withIdentifier: "ClassificationErrorViewController") as! ClassificationErrorViewController
                if(idOptions?.cardSide == CardSide.Front){
                    errorController.image = capturedFrontImage
                }else{
                    errorController.image = capturedBackImage
                }
                AppDelegate.navigationController?.pushViewController(errorController, animated: true)
            }else{
                CustomAlerts.displayError(message: "\(error!.errorCode!) : " + (error?.errorDescription)!)
            }
        }
    }
    
    func processingResultReceived(processingResult: ProcessingResult) {
        if(processingResult.error == nil){
            if(isHealthCard){
                let healthCardResult = processingResult as! HealthInsuranceCardResult
                let mirrored_object = Mirror(reflecting: healthCardResult)
                var dataArray = Array<String>()
                for (index, attr) in mirrored_object.children.enumerated() {
                    if let property_name = attr.label as String? {
                        if let property_value = attr.value as? String {
                            if(property_value != ""){
                                dataArray.append("\(property_name) : \(property_value)")
                            }
                        }
                    }
                }
                
                showHealthCardResult(data: dataArray, front: healthCardResult.frontImage, back: healthCardResult.backImage)
                AcuantDocumentProcessing.deleteInstance(instanceId: healthCardResult.instanceID!,type:DeleteType.MedicalCard, delegate: self)
                
            }else{
                let idResult = processingResult as! IDResult
                if(idResult.fields == nil){
                    CustomAlerts.displayError(message: "Could not extract data")
                    isProcessing = false
                    return
                }else if(idResult.fields!.documentFields == nil){
                    CustomAlerts.displayError(message: "Could not extract data")
                    isProcessing = false
                    return
                }else if(idResult.fields!.documentFields!.count==0){
                    CustomAlerts.displayError(message: "Could not extract data")
                    isProcessing = false
                    return
                }
                let fields : Array<DocumentField>! = idResult.fields!.documentFields!
                
                var frontImageUri: String? = nil
                var backImageUri: String? = nil
                var signImageUri: String? = nil
                var faceImageUri: String? = nil
                
                var dataArray = Array<String>()
                
                dataArray.append("Authentication Result : \(Utils.getAuthResultString(authResult: idResult.result!))")
                //var images = [String:UIImage]()
                for field in fields{
                    if(field.type == "string"){
                        dataArray.append("\(field.key!) : \(field.value!)")
                    }else if(field.type == "datetime"){
                        dataArray.append("\(field.key!) : \(Utils.dateFieldToDateString(dateStr: field.value!)!)")
                    }else if (field.key == "Photo" && field.type == "uri") {
                        faceImageUri = field.value
                        capturedFaceImageUrl = faceImageUri
                    } else if (field.key == "Signature" && field.type == "uri") {
                        signImageUri = field.value
                    }
                }
                
                for image in (idResult.images?.images!)! {
                    if (image.side == 0) {
                        frontImageUri = image.uri
                    } else if (image.side == 1) {
                        backImageUri = image.uri
                    }
                }
                isProcessing = false
                showResult(data: dataArray, front: frontImageUri, back: backImageUri, sign: signImageUri, face: faceImageUri)
                //AcuantDocumentProcessing.deleteInstance(instanceId: idResult.instanceID!,type:DeleteType.ID, delegate: self)
            }
        }else{
            if let msg = processingResult.error?.errorDescription {
                CustomAlerts.displayError(message: msg)
            }
        }
        
    }
    
    
    public func retryCapture(){
        showDocumentCaptureCamera()
    }
    
    public func retryClassification(){
        isRetrying = true
        showDocumentCaptureCamera()
    }
    
    let vcUtil = ViewControllerUtils()
    override func viewDidLoad() {
        super.viewDidLoad()
        vcUtil.showActivityIndicator(uiView: self.view, text: "Initializing...")
        AcuantImagePreparation.initialize(delegate:self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func initializationFinished(error: AcuantError?) {
        vcUtil.hideActivityIndicator(uiView: self.view)
        if(error == nil){
            medicalCardButton.isHidden = false
        }else{
            if let msg = error?.errorDescription {
                CustomAlerts.displayError(message: "\(error!.errorCode!) : " + msg)
            }
        }
    }
    
    func processHealthCard(){
        self.vcUtil.showActivityIndicator(uiView: self.view, text: "Processing...")
        
        idOptions = IdOptions()
        idOptions?.cardSide = CardSide.Front
        idOptions?.isHealthCard = true
        idOptions?.isRetrying = false
        
        idData = IdData()
        idData?.image = capturedFrontImage
        
        AcuantDocumentProcessing.createInstance( processingMode: ProcessingMode.DataCapture, options: idOptions!, delegate:self)
    }
    
    func facialMatchFinished(result: FacialMatchResult?) {
        self.isProcessingFacialMatch = false
        if(result?.error == nil){
            capturedFacialMatchResult = result
        }else{
            if let msg = result?.error?.errorDescription {
                CustomAlerts.displayError(message: msg)
            }
        }
    }
    
    
    func instanceDeleted(success: Bool) {
        print()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func isBackSideRequired(classification:Classification?)->Bool{
        if(classification == nil){
            return false
        }
        var isBackSideRequired : Bool = false
        let supportedImages : [Dictionary<String, Int>]? = classification?.type?.supportedImages as? [Dictionary<String, Int>]
        if(supportedImages != nil){
            for image in supportedImages!{
                if(image["Light"]==0 && image["Side"]==1){
                    isBackSideRequired = true
                }
            }
        }
        return isBackSideRequired
    }
}

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
