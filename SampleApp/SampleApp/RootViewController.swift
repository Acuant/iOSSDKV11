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
import AVFoundation

class RootViewController: UIViewController , InitializationDelegate,CreateInstanceDelegate,UploadImageDelegate,GetDataDelegate, FacialMatchDelegate,DeleteDelegate,AcuantHGLivenessDelegate,CameraCaptureDelegate,LivenessSetupDelegate,LivenessTestDelegate,LivenessTestResultDelegate, LivenessTestCredentialDelegate{
    

    @IBOutlet var autoCaptureSwitch : UISwitch!
    
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
    private var isInitialized = false
    private var isIPLivenessEnabled = false
    
    public var idOptions : IdOptions? = nil
    public var idData : IdData? = nil
    
    public var ipLivenessSetupResult : LivenessSetupResult? = nil
    
    var side : CardSide = CardSide.Front
    var captureWaitTime = 2
    var minimumNumberOfClassificationAttemptsRequired = 1
    var numerOfClassificationAttempts = 0
    
    var autoCapture = true
    var progressView : AcuantProgressView!
    
    @IBOutlet var medicalCardButton: UIButton!
    @IBOutlet var idPassportButton: UIButton!
    
    @IBOutlet weak var IPLivenessLabel: UILabel!
    @IBOutlet weak var IPLivenessSwitch: UISwitch!
    
    @IBAction func iPLivenessTapped(_ sender: Any) {
        isIPLivenessEnabled = IPLivenessSwitch.isOn
    }
    private func showProgressView(text:String = ""){
        DispatchQueue.main.async {
            self.progressView.messageView.text = text
            self.progressView.startAnimation()
            self.view.addSubview(self.progressView)
        }

    }
    private func hideProgressView(){
        DispatchQueue.main.async {
            self.progressView.stopAnimation()
            self.progressView.removeFromSuperview()
        }
    }
    
    @IBAction func idPassportTapped(_ sender: UIButton) {
        if(CheckConnection.isConnectedToNetwork() == false){
            CustomAlerts.displayError(message: CheckConnection.ERROR_INTERNET_UNAVAILABLE)
        }
        else{
            if(!isInitialized){
                let ipLivenessCallback = IPLivenessCredentialHelper(callback: {
                    (isEnabled) in
                    self.isInitialized = true
                    self.resetData()
                    self.isIPLivenessEnabled = isEnabled
                    self.hideProgressView()
                    self.showDocumentCaptureCamera()
                    
                    DispatchQueue.main.async {
                        self.IPLivenessSwitch.isOn = isEnabled
                        if(isEnabled){
                            self.IPLivenessLabel.isEnabled = true
                            self.IPLivenessSwitch.isEnabled = true
                        }
                    }
                
                    
                }, onError: {
                    error in
                    DispatchQueue.main.async {
                        self.hideProgressView()
                        CustomAlerts.displayError(message: error.errorDescription!)
                    }
                    
                })
                let retryCallback = ReinitializeHelper(callback: { isInitialized in
                    DispatchQueue.main.async {
                        if(isInitialized){
                            if(!Credential.subscription().isEmpty){
                                  AcuantIPLiveness.getLivenessTestCredential(delegate: ipLivenessCallback)
                              }
                              else{
                                  self.hideProgressView()
                                  self.isInitialized = false
                                  self.resetData()
                                  self.isIPLivenessEnabled = false
                                  self.showDocumentCaptureCamera()
                                  self.IPLivenessSwitch.isOn = false
                              }
                            
                        }
                        else{
                            self.hideProgressView()
                        }
                    }
                })
                
                AcuantImagePreparation.initialize( delegate:retryCallback)
                self.showProgressView(text: "Initializing...")
            }
            else{
                resetData()
                showDocumentCaptureCamera()
            }
        }
    }
    
    @IBAction func healthCardTapped(_ sender: UIButton) {
        if(CheckConnection.isConnectedToNetwork() == false){
            CustomAlerts.displayError(message: CheckConnection.ERROR_INTERNET_UNAVAILABLE)
        }
        else{
            if(!isInitialized){
                let ipLivenessCallback = IPLivenessCredentialHelper(callback: {
                    (isEnabled) in
                    self.hideProgressView()
                    self.isInitialized = true
                    self.resetData()
                    self.isHealthCard = true
                    self.isIPLivenessEnabled = isEnabled
                    self.showDocumentCaptureCamera()
                    
                    self.IPLivenessSwitch.isOn = isEnabled
                    if(isEnabled){
                        self.IPLivenessLabel.isEnabled = true
                        self.IPLivenessSwitch.isEnabled = true
                    }
                   
                }, onError: {
                    error in
                    self.hideProgressView()
                    CustomAlerts.displayError(message: error.errorDescription!)
                })
                let retryCallback = ReinitializeHelper(callback: { isInitialized in
                    if(isInitialized){
                        if(Credential.subscription() != nil && !Credential.subscription().isEmpty){
                            AcuantIPLiveness.getLivenessTestCredential(delegate: ipLivenessCallback)
                        }
                        else{
                            self.hideProgressView()
                            self.isInitialized = false
                            self.resetData()
                            self.isHealthCard = true
                            self.isIPLivenessEnabled = false
                            self.showDocumentCaptureCamera()
                            self.IPLivenessSwitch.isOn = false
                        }
                    }
                    else{
                        self.hideProgressView()
                    }
                })
                
                AcuantImagePreparation.initialize( delegate:retryCallback)
                self.showProgressView(text: "Initializing...")
            }
            else{
                resetData()
                isHealthCard = true
                showDocumentCaptureCamera()
            }
        }
    }
    
    
    @IBAction func autocaptureSwitched(_ sender: UISwitch) {
        if sender.isOn {
            autoCapture =  true
        } else {
            autoCapture =  false
        }
    }
    
    private func getIPLivenessCredential(){
        AcuantIPLiveness.getLivenessTestCredential(delegate: self)
    }
    
    func livenessTestCredentialReceived(result:Bool){
        isInitialized = true
        isIPLivenessEnabled = result
        
        DispatchQueue.main.async{
            self.IPLivenessSwitch.isOn = result
            if(self.isIPLivenessEnabled){
                self.IPLivenessLabel.isEnabled = true
                self.IPLivenessSwitch.isEnabled = true
            }
        }
    }
    
    func livenessTestCredentialReceiveFailed(error:AcuantError){
        self.hideProgressView()
        CustomAlerts.displayError(message: "\(error.errorCode) : \(error.errorDescription)" )
    }
    
    func showDocumentCaptureCamera(){
        // handler in .requestAccess is needed to process user's answer to our request
        AVCaptureDevice.requestAccess(for: .video) { [weak self] success in
            if success { // if request is granted (success is true)
                DispatchQueue.main.async {
                    let options = AcuantCameraOptions(digitsToShow:self!.captureWaitTime, autoCapture:self!.autoCapture, hideNavigationBar: true)
                    let documentCameraController = DocumentCameraController.getCameraController(delegate:self!, cameraOptions: options)
                    self!.navigationController?.pushViewController(documentCameraController, animated: false)
                }
            } else { // if request is denied (success is false)
                // Create Alert
                let alert = UIAlertController(title: "Camera", message: "Camera access is absolutely necessary to use this app", preferredStyle: .alert)
                
                // Add "OK" Button to alert, pressing it will bring you to the settings app
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }))
                // Show the alert with animation
                self!.present(alert, animated: true)
            }
        }
    }
    
    
    class IPLivenessCredentialHelper:LivenessTestCredentialDelegate{
        init(callback: @escaping (_ isInitalized: Bool) -> (), onError: @escaping (_ error:AcuantError) -> ()){
            self.completion = callback
            self.onError = onError
        }
        var completion: (_ isInitalized: Bool)->()
        var onError: (_ error:AcuantError)->()
        func livenessTestCredentialReceived(result:Bool){
            self.completion(result)
        }
        func livenessTestCredentialReceiveFailed(error:AcuantError){
            self.onError(error)
        }
    }
    
    class ReinitializeHelper:InitializationDelegate{
        init(callback: @escaping (_ isInitalized: Bool) -> ()){
            completion = callback
        }
        var completion: (_ isInitalized: Bool)->()
        func initializationFinished(error: AcuantError?) {
            if(error != nil){
                CustomAlerts.displayError(message: error!.errorDescription!)
                self.completion(false)
            }
            else{
                self.completion(true)
            }
        }
    }
    
    func resetData(){
        side = CardSide.Front
        captureWaitTime = 2
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
        ipLivenessSetupResult = nil
    }
    
    func showFacialCaptureInterface(){
        self.isProcessingFacialMatch = true
        if(isIPLivenessEnabled){
            //Code for IP liveness
            AcuantIPLiveness.performLivenessSetup(delegate: self)
        }
        else{
            // Code for HG Live controller
            let liveFaceViewController = FaceLivenessCameraController()
            liveFaceViewController.delegate = self
            self.navigationController?.pushViewController(liveFaceViewController, animated: true)
        }
        
    }

    
    func showResult(data:Array<String>?,front:String?,back:String?,sign:String?,face:String?){
        DispatchQueue.global().async {
            if(Credential.endpoints().frmEndpoint != nil){
                while(self.isProcessingFacialMatch == true){
                    sleep(1)
                }
            }
            DispatchQueue.main.async {
                self.hideProgressView()
                let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                let resultViewController = storyBoard.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
                
                if(self.capturedFacialMatchResult != nil){
                    var dataWithFacialData = data
                    dataWithFacialData?.insert("Face matched :\(self.capturedFacialMatchResult!.isMatch)", at: 0)
                    
                    dataWithFacialData?.insert("Face Match score :\(self.capturedFacialMatchResult!.score)", at: 0)
                    
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
                self.navigationController?.pushViewController(resultViewController, animated: true)
            }
            
        }
    }
    
    func showHealthCardResult(data:Array<String>?,front:UIImage?,back:UIImage?){
        DispatchQueue.main.async {
            self.hideProgressView()
            let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
            let resultViewController = storyBoard.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
            
            
            resultViewController.data = data
            
            resultViewController.front = front
            resultViewController.back = back
            self.navigationController?.pushViewController(resultViewController, animated: true)
        }
        
    }

    
    // IP Liveness
    func livenessSetupSucceeded(result: LivenessSetupResult) {
        ipLivenessSetupResult = result
        result.ui.title = ""
        AcuantIPLiveness.performLivenessTest(setupResult: result, delegate: self)
    }
    
    func livenessSetupFailed(error: AcuantError) {
        livenessTestFailed(error:error)
    }
    
    func livenessTestCompleted() {
        AcuantIPLiveness.getLivenessTestResult(token: ipLivenessSetupResult!.token!, userId: ipLivenessSetupResult!.userId!, delegate: self)
    }
    
    func livenessTestProcessing(progress: Double, message: String) {
        DispatchQueue.main.async {
            self.showProgressView(text: "\(Int(progress * 100))%")
        }
    }
    
    func livenessTestCompletedWithError(error: AcuantError?) {
        AcuantIPLiveness.getLivenessTestResult(token: ipLivenessSetupResult!.token!, userId: ipLivenessSetupResult!.userId!, delegate: self)
    }
    
    func livenessTestResultReceived(result: LivenessTestResult) {
        isLiveFace = result.passedLivenessTest
        processFacialMatch(image: result.image)
    }
    
    func livenessTestResultReceiveFailed(error: AcuantError) {
        livenessTestFailed(error:error)
    }
    
    func livenessTestFailed(error:AcuantError) {
        capturedLiveFace = nil
        isLiveFace = false
        self.isProcessingFacialMatch = false
    }

    func processFacialMatch(image:UIImage?){
        self.showProgressView(text: "Processing...")
        DispatchQueue.global().async {
            while(self.isProcessing == true){
                sleep(1)
            }
            if(self.capturedFaceImageUrl != nil && image != nil){
                self.capturedLiveFace = image
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
                    self.hideProgressView()
                }
                
            }
        }
    }
    
    public func liveFaceCaptured(image:UIImage?){
        if(image != nil){
            self.isLiveFace = true
            processFacialMatch(image: image!)
        }
        else{
            self.isProcessingFacialMatch = false
            DispatchQueue.main.async {
                self.hideProgressView()
            }
        }
      
    }
    public func setCapturedImage(image:Image, barcodeString:String?){
        self.showProgressView(text: "Processing...")
    
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
                    self.hideProgressView()
                    
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
                    self.navigationController?.pushViewController(confirmController, animated: true)
                }
                self.hideProgressView()
            }
        }
    }
    
    func cropImage(image:UIImage)->Image?{
        let croppingData  = CroppingData()
        croppingData.image = image
        
        let croppedImage = AcuantImagePreparation.crop(data: croppingData)
        return croppedImage
    }
    
    public func confirmImage(image:UIImage,side:CardSide){
        if(side==CardSide.Front){
            capturedFrontImage = image
            if(isHealthCard){
                let alert = UIAlertController(title: NSLocalizedString("Back Side?", comment: ""), message: NSLocalizedString("Scan the back side of the health insurance card", comment: ""), preferredStyle:UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                { action -> Void in
                    self.side = CardSide.Back
                    self.captureWaitTime = 2
                    self.showDocumentCaptureCamera()
                })
                alert.addAction(UIAlertAction(title: "SKIP", style: UIAlertAction.Style.default)
                { action -> Void in
                    self.processHealthCard()
                })
                self.present(alert, animated: true, completion: nil)
            }else{
                // Create instance
                self.showProgressView(text: "Classifying...")
                
                idOptions = IdOptions()
                idOptions?.cardSide = CardSide.Front
                idOptions?.isHealthCard = false
                idOptions?.isRetrying = isRetrying
                
                idData = IdData()
                idData?.image = capturedFrontImage
                if(isRetrying){
                    numerOfClassificationAttempts = numerOfClassificationAttempts + 1
                    AcuantDocumentProcessing.uploadImage( instancdId: documentInstance!, data: idData!, options: idOptions!, delegate: self)
                }else{
                    AcuantDocumentProcessing.createInstance(options: idOptions!, delegate:self)
                }
                
            }
        }else{
            if(isHealthCard){
                capturedBackImage = image
                processHealthCard()
            }else{
                capturedBackImage = image
                self.showProgressView(text: "Processing...")
                
                idOptions = IdOptions()
                idOptions?.cardSide = CardSide.Back
                idOptions?.isHealthCard = false
                idOptions?.isRetrying = false
                
                idData = IdData()
                idData?.image = capturedBackImage
                AcuantDocumentProcessing.uploadImage( instancdId: documentInstance!, data: idData!, options: idOptions!, delegate: self)
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
                AcuantDocumentProcessing.uploadImage( instancdId: documentInstance!, data: idData!, options: idOptions!, delegate: self)
                
            }else{
                // Upload and Classify ID/Passport image
                AcuantDocumentProcessing.uploadImage( instancdId: documentInstance!, data: idData!, options: idOptions!, delegate: self)
            }
        }else{
            self.hideProgressView()
            CustomAlerts.displayError(message: "\(error!.errorCode) : " + (error?.errorDescription)!)
        }
    }
    
    func imageUploaded(error: AcuantError?,classification:Classification?) {
        if(error == nil){
            if(self.isHealthCard){
                if(self.idOptions?.cardSide == CardSide.Front){
                    if(self.capturedBackImage == nil){
                        // Get Data
                        AcuantDocumentProcessing.getData(instanceId: self.documentInstance!, isHealthCard: true, delegate: self)
                    }else{
                        // upload back image
                        self.idData?.barcodeString=nil
                        self.idData?.image=self.capturedBackImage
                        
                        self.idOptions?.isHealthCard = true
                        self.idOptions?.cardSide = CardSide.Back
                        self.idOptions?.isRetrying = false
                        AcuantDocumentProcessing.uploadImage( instancdId: self.documentInstance!, data: self.idData!, options: self.idOptions!, delegate: self)
                    }
                }else{
                    // Get Data
                    AcuantDocumentProcessing.getData(instanceId: self.documentInstance!, isHealthCard: true, delegate: self)
                }
            }else{
                self.hideProgressView()
                if(self.idOptions?.cardSide == CardSide.Front){
                    if(self.isBackSideRequired(classification: classification)){
                        // Capture Back Side
                        let alert = UIAlertController(title: NSLocalizedString("Back Side?", comment: ""), message: NSLocalizedString("Scan the back side of the ID document", comment: ""), preferredStyle:UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                        { action -> Void in
                            self.side = CardSide.Back
                            self.captureWaitTime = 2
                            self.showDocumentCaptureCamera()
                        })
                        self.present(alert, animated: true, completion: nil)
                    }else{
                        // Get Data
                        if(Credential.endpoints().frmEndpoint != nil){
                            self.showFacialCaptureInterface()
                        }
                        self.isProcessing = true
                        AcuantDocumentProcessing.getData(instanceId: self.documentInstance!, isHealthCard: false, delegate: self)
                        self.showProgressView(text: "Processing...")
                    }
                }else{
                    // Get Data
                    if(Credential.endpoints().frmEndpoint != nil){
                        self.showFacialCaptureInterface()
                    }
                    self.isProcessing = true
                    AcuantDocumentProcessing.getData(instanceId: self.documentInstance!, isHealthCard: false, delegate: self)
                    self.showProgressView(text: "Processing...")
                }
            }
        }else{
            self.hideProgressView()
            if(error?.errorCode == AcuantErrorCodes.ERROR_CouldNotClassifyDocument){
                let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                let errorController = storyBoard.instantiateViewController(withIdentifier: "ClassificationErrorViewController") as! ClassificationErrorViewController
                if(self.idOptions?.cardSide == CardSide.Front){
                    errorController.image = self.capturedFrontImage
                }else{
                    errorController.image = self.capturedBackImage
                }
                self.navigationController?.pushViewController(errorController, animated: true)
            }else{
                CustomAlerts.displayError(message: "\(error!.errorCode) : " + (error?.errorDescription)!)
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
                
                dataArray.append("Authentication Result : \(Utils.getAuthResultString(authResult: idResult.result))")
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
    
   // let vcUtil = ViewControllerUtils.createInstance()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        autoCaptureSwitch.setOn(true, animated: false)
        
//        var configDictionay: NSDictionary?
//        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
//            configDictionay = NSDictionary(contentsOfFile: path)
//        }
//

        self.progressView = AcuantProgressView(frame: self.view.frame, center: self.view.center)
        self.showProgressView(text:  "Initializing...")
        
        // If not initialized via AcuantConfig.plist , the initiallize as below
        /*Credential.setUsername(username: "xxx")
        Credential.setPassword(password: "xxxx")
        Credential.setSubscription(subscription: "xxxxxx")
        
        let endpoints = Endpoints()
        endpoints.frmEndpoint = "https://frm.acuant.net"
        endpoints.healthInsuranceEndpoint = "https://medicscan.acuant.net"
        endpoints.idEndpoint = "https://services.assureid.net"
        
        Credential.setEndpoints(endpoints: endpoints)*/
        
        
        AcuantImagePreparation.initialize(delegate:self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func initializationFinished(error: AcuantError?) {
        self.hideProgressView()
        if(error == nil){
            if(!Credential.subscription().isEmpty){
                AcuantIPLiveness.getLivenessTestCredential(delegate: self)
             }
             else{
                 self.hideProgressView()
                 self.isInitialized = false
                 self.resetData()
                 self.isIPLivenessEnabled = false
                 self.IPLivenessSwitch.isOn = false
             }
        }else{
            if let msg = error?.errorDescription {
                CustomAlerts.displayError(message: "\(error!.errorCode) : " + msg)
            }
        }
    }
    
    func processHealthCard(){
        self.showProgressView(text: "Processing...")
        
        idOptions = IdOptions()
        idOptions?.cardSide = CardSide.Front
        idOptions?.isHealthCard = true
        idOptions?.isRetrying = false
        
        idData = IdData()
        idData?.image = capturedFrontImage
        
        AcuantDocumentProcessing.createInstance(options: idOptions!, delegate:self)
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
