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
import AcuantPassiveLiveness
import AcuantFaceCapture
import AVFoundation
import AcuantEchipReader

class RootViewController: UIViewController{
    
    @IBOutlet weak var autoCaptureSwitch : UISwitch!
    @IBOutlet weak var medicalCardButton: UIButton!
    @IBOutlet weak var idPassportButton: UIButton!
    @IBOutlet weak var livenessOption: UISegmentedControl!
    
    @IBOutlet weak var mrzButton: UIButton!
    
    public var documentInstance : String?
    public var livenessString: String?
    public var capturedFacialMatchResult : FacialMatchResult? = nil
    public var capturedFaceImageUrl : String? = nil
    private var isInitialized = false
    private var isKeyless = false
    private var faceCapturedImage: UIImage?
    
    public var idOptions = IdOptions()
    public var idData = IdData()
    
    public var ipLivenessSetupResult : LivenessSetupResult? = nil
    
    var autoCapture = true
    var progressView : AcuantProgressView!
    
    private let getDataGroup = DispatchGroup()
    private let faceProcessingGroup = DispatchGroup()
    private let showResultGroup = DispatchGroup()
    private let createInstanceGroup = DispatchGroup()
    
    //    private let passportReader = PassportReader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autoCaptureSwitch.setOn(true, animated: false)
        self.isKeyless = Credential.subscription() == nil || Credential.subscription() == ""
        
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
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor:UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor:UIColor.white], for: .normal)
    }
    
    func addEnhancedLiveness(){
        if(livenessOption.numberOfSegments == 2){
            livenessOption.insertSegment(withTitle: "Enhanced", at: livenessOption.numberOfSegments, animated: true)
        }
    }
    
    private func initialize(){
        let initalizer: IAcuantInitializer = AcuantInitializer()
        
        let task = initalizer.initialize(packages: [AcuantEchipPackage(), AcuantImagePreparationPackage()]){ [weak self]
            error in
            
            DispatchQueue.main.async {
                if let self = self{
                    self.hideProgressView()
                    if(error == nil){
                        if(!Credential.authorization().hasOzone){
                            self.mrzButton.isHidden = true
                        }
                        
                        if(!self.isKeyless){
                            AcuantIPLiveness.getLivenessTestCredential(delegate: self)
                        }
                        else{
                            self.hideProgressView()
                            self.isInitialized = true
                            self.resetData()
                        }
                    }else{
                        if let msg = error?.errorDescription {
                            CustomAlerts.displayError(message: "\(error!.errorCode) : " + msg)
                        }
                    }
                    
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(!self.isInitialized){
            self.initialize()
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onMrzEchipTapped(_ sender: Any) {
        self.handleInitialization(isDocumentCapture: false)
    }
    
    @IBAction func idPassportTapped(_ sender: UIButton){
        self.idOptions.isHealthCard = false
        self.handleInitialization()
    }
    
    @IBAction func healthCardTapped(_ sender: UIButton){
        self.idOptions.isHealthCard = true
        self.handleInitialization()
    }
    
    @IBAction func autocaptureSwitched(_ sender: UISwitch) {
        if sender.isOn {
            autoCapture =  true
        } else {
            autoCapture =  false
        }
    }
    
    
    @IBAction func onLivenessChanged(_ sender: Any) {
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
    
    private func resetData(){
        capturedFaceImageUrl = nil
        capturedFacialMatchResult = nil
        documentInstance = nil
        ipLivenessSetupResult = nil
        livenessString = nil
        faceCapturedImage = nil
        self.idOptions.cardSide = CardSide.Front
        self.createInstance()
    }
    
    public func confirmImage(image:UIImage){
        self.createInstanceGroup.notify(queue: .main){
            self.showProgressView(text: "Processing...")
            self.idData.image = image
            
            AcuantDocumentProcessing.uploadImage( instancdId: self.documentInstance!, data: self.idData, options: self.idOptions, delegate: self)
        }
    }
    
    public func retryCapture(){
        showDocumentCaptureCamera()
    }
    
    public func retryClassification(){
        self.idOptions.isRetrying = true
        showDocumentCaptureCamera()
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

//ImagePreparation - START =============
extension RootViewController{
    private func handleInitialization(isDocumentCapture : Bool = true){
        if(CheckConnection.isConnectedToNetwork() == false){
            CustomAlerts.displayError(message: CheckConnection.ERROR_INTERNET_UNAVAILABLE)
        }
        else{
            if(!self.isInitialized){
                self.initialize()
                self.showProgressView(text: "Initializing...")
            }
            else if (isDocumentCapture){
                self.resetData()
                self.showDocumentCaptureCamera()
            }
            else{
                self.resetData()
                self.showMrzCamera()
            }
        }
    }
}
//ImagePreparation - END =============

//AcuantCamera - START =============
extension RootViewController: CameraCaptureDelegate{
    public func setCapturedImage(image:Image, barcodeString:String?){
        if(self.isKeyless){
            handleKeyless(image: image)
        }
        else{
            cropImage(image: image){ croppedImage in
                if(croppedImage?.image == nil || (croppedImage?.error != nil && croppedImage?.error?.errorCode != AcuantErrorCodes.ERROR_LowResolutionImage)){
                    CustomAlerts.display(
                        message: (croppedImage?.error?.errorDescription)!,
                        action: UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default, handler: { (action:UIAlertAction) in self.retryCapture() }))
                }
                else{
                    let sharpness = AcuantImagePreparation.sharpness(image:croppedImage!.image!)
                    let glare = AcuantImagePreparation.glare(image:croppedImage!.image!)
                    
                    let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                    let confirmController = storyBoard.instantiateViewController(withIdentifier: "ConfirmationViewController") as! ConfirmationViewController
                    confirmController.sharpness = sharpness
                    confirmController.glare = glare
                    if(barcodeString != nil){
                        confirmController.barcodeCaptured = true
                        confirmController.barcodeString = barcodeString
                    }
                    self.idData.barcodeString = barcodeString
                    confirmController.image = croppedImage
                    self.navigationController?.pushViewController(confirmController, animated: true)
                }
            }
        }
    }
    
    func showMrzCamera(){
        let controller = AcuantMrzCameraController()
        controller.customDisplayMessage = {
            state in
            
            switch(state){
            case .None, .Align:
                return ""
            case .MoveCloser:
                return "Move Closer"
            case .TooClose:
                return "Too Close!"
            case .Good:
                return "Reading MRZ"
            case .Captured:
                return "Captured"
            }
        }
        controller.callback = { [weak self]
            result in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
                let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewController(withIdentifier: "NFCViewController") as! NFCViewController
                vc.result = result
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }
        self.navigationController?.pushViewController(controller, animated: false)
    }
    
    func showDocumentCaptureCamera(){
        //handler in .requestAccess is needed to process user's answer to our request
        AVCaptureDevice.requestAccess(for: .video) { [weak self] success in
            if success { // if request is granted (success is true)
                DispatchQueue.main.async {
                    let options = AcuantCameraOptions(autoCapture:self!.autoCapture, hideNavigationBar: true)
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
    
    public func showKeylessHGLiveness(){
        let liveFaceViewController = FaceLivenessCameraController()
        
        //Optionally override to change refresh rate
        //liveFaceViewController.frameRefreshSpeed = 10
        
        self.navigationController?.pushViewController(liveFaceViewController, animated: true)
    }
    
    func cropImage(image:UIImage)->Image?{
        let croppingData  = CroppingData()
        croppingData.image = image
        
        let croppedImage = AcuantImagePreparation.crop(data: croppingData)
        return croppedImage
    }
    
    
    public func cropImage(image:Image, callback: @escaping (Image?) -> ()){
        self.showProgressView(text: "Processing...")
        DispatchQueue.global().async {
            let croppedImage = self.cropImage(image: image.image!)
            DispatchQueue.main.async {
                self.hideProgressView()
                callback(croppedImage)
            }
        }
    }
    
    private func handleKeyless(image:Image){
        cropImage(image: image){ croppedImage in
            if(croppedImage == nil || croppedImage!.isPassport || self.idOptions.cardSide == CardSide.Back){
                self.showKeylessHGLiveness()
            }
            else{
                let alert = UIAlertController(title: NSLocalizedString("Back Side?", comment: ""), message: NSLocalizedString("Scan the back side of the ID document", comment: ""), preferredStyle:UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                { action -> Void in
                    self.idOptions.cardSide = CardSide.Back
                    self.showDocumentCaptureCamera()
                })
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
//AcuantCamera - END =============

//DocumentProcessing - START ============

extension RootViewController: CreateInstanceDelegate{
    func instanceCreated(instanceId: String?, error: AcuantError?) {
        if(error == nil){
            documentInstance = instanceId
        }else{
            self.hideProgressView()
            CustomAlerts.displayError(message: "\(error!.errorCode) : " + (error?.errorDescription)!)
        }
        self.createInstanceGroup.leave()
    }
    
    private func createInstance(){
        if(!self.isKeyless){
            self.createInstanceGroup.enter()
            AcuantDocumentProcessing.createInstance(options: self.idOptions, delegate:self)
        }
    }
}

extension RootViewController:UploadImageDelegate{
    private func handleHealthcardFront(){
        let alert = UIAlertController(title: NSLocalizedString("Back Side?", comment: ""), message: NSLocalizedString("Scan the back side of the health insurance card", comment: ""), preferredStyle:UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
        { action -> Void in
            self.idOptions.cardSide = CardSide.Back
            self.showDocumentCaptureCamera()
        })
        alert.addAction(UIAlertAction(title: "SKIP", style: UIAlertAction.Style.default)
        { action -> Void in
            AcuantDocumentProcessing.getData(instanceId: self.documentInstance!, isHealthCard: true, delegate: self)
            self.showProgressView(text: "Processing...")
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    private func getIdDataAndStartFace(){
        if(Credential.endpoints()?.frmEndpoint != nil){
            self.showFacialCaptureInterface()
        }
        self.getDataGroup.enter()
        AcuantDocumentProcessing.getData(instanceId: self.documentInstance!, isHealthCard: false, delegate: self)
        self.showProgressView(text: "Processing...")
    }
    
    func imageUploaded(error: AcuantError?, classification:Classification?) {
        self.hideProgressView()
        
        if(error == nil){
            self.idOptions.isRetrying = false
            if(self.idOptions.isHealthCard){
                if(self.idOptions.cardSide == CardSide.Front){
                    self.handleHealthcardFront()
                }else{
                    // Get Data
                    AcuantDocumentProcessing.getData(instanceId: self.documentInstance!, isHealthCard: true, delegate: self)
                    self.showProgressView(text: "Processing...")
                }
            }else{
                if(self.idOptions.cardSide == CardSide.Front){
                    if(self.isBackSideRequired(classification: classification)){
                        // Capture Back Side
                        let alert = UIAlertController(title: NSLocalizedString("Back Side?", comment: ""), message: NSLocalizedString("Scan the back side of the ID document", comment: ""), preferredStyle:UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                        { action -> Void in
                            self.idOptions.cardSide = CardSide.Back
                            self.showDocumentCaptureCamera()
                        })
                        self.present(alert, animated: true, completion: nil)
                    }else{
                        self.getIdDataAndStartFace()
                    }
                }else{
                    // Get Data
                    self.getIdDataAndStartFace()
                }
            }
        }else{
            if(error?.errorCode == AcuantErrorCodes.ERROR_CouldNotClassifyDocument){
                let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                let errorController = storyBoard.instantiateViewController(withIdentifier: "ClassificationErrorViewController") as! ClassificationErrorViewController
                
                errorController.image = self.idData.image
                self.navigationController?.pushViewController(errorController, animated: true)
            }else{
                CustomAlerts.displayError(message: "\(error!.errorCode) : " + (error?.errorDescription)!)
            }
        }
    }
}

extension RootViewController:GetDataDelegate{
    func processingResultReceived(processingResult: ProcessingResult) {
        if(processingResult.error == nil){
            if(self.idOptions.isHealthCard){
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
                    getDataGroup.leave()
                    return
                }else if(idResult.fields!.documentFields == nil){
                    CustomAlerts.displayError(message: "Could not extract data")
                    getDataGroup.leave()
                    return
                }else if(idResult.fields!.documentFields!.count==0){
                    CustomAlerts.displayError(message: "Could not extract data")
                    getDataGroup.leave()
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
                
                self.showResult(data: dataArray, front: frontImageUri, back: backImageUri, sign: signImageUri, face: faceImageUri)
            }
        }else{
            if let msg = processingResult.error?.errorDescription {
                CustomAlerts.displayError(message: msg)
            }
        }
    }
    
    func showResult(data:Array<String>?,front:String?,back:String?,sign:String?,face:String?){
        self.getDataGroup.leave()
        self.showResultGroup.notify(queue: .main){
            self.hideProgressView()
            let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
            let resultViewController = storyBoard.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
            resultViewController.data = data
            
            if(self.livenessString != nil){
                resultViewController.data?.insert(self.livenessString!, at: 0)
            }
            
            if(self.capturedFacialMatchResult != nil){
                resultViewController.data?.insert("Face matched :\(self.capturedFacialMatchResult!.isMatch)", at: 0)
                resultViewController.data?.insert("Face Match score :\(self.capturedFacialMatchResult!.score)", at: 0)
            }
            
            resultViewController.frontImageUrl = front
            resultViewController.backImageUrl = back
            resultViewController.signImageUrl = sign
            resultViewController.faceImageUrl = face
            resultViewController.username = Credential.username()
            resultViewController.password = Credential.password()
            resultViewController.faceImageCaptured = self.faceCapturedImage
            self.navigationController?.pushViewController(resultViewController, animated: true)
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
}

extension RootViewController:DeleteDelegate{
    func instanceDeleted(success: Bool) {
        print()
    }
}
//DocumentProcessing - END ============

//IPLiveness - START ============

extension RootViewController : LivenessTestCredentialDelegate{
    func livenessTestCredentialReceived(result:Bool){
        isInitialized = true
        
        DispatchQueue.main.async{
            if(result){
                self.addEnhancedLiveness()
            }
        }
    }
    
    func livenessTestCredentialReceiveFailed(error:AcuantError){
        self.hideProgressView()
        CustomAlerts.displayError(message: "\(error.errorCode) : \(error.errorDescription)" )
    }
}
extension RootViewController : LivenessSetupDelegate{
    func livenessSetupSucceeded(result: LivenessSetupResult) {
        ipLivenessSetupResult = result
        result.ui.title = ""
        AcuantIPLiveness.performLivenessTest(setupResult: result, delegate: self)
    }
    
    func livenessSetupFailed(error: AcuantError) {
        livenessTestFailed(error:error)
    }
}

extension RootViewController : LivenessTestDelegate{
    func livenessTestCompleted() {
        if(ipLivenessSetupResult != nil){
            AcuantIPLiveness.getLivenessTestResult(token: ipLivenessSetupResult!.token, userId: ipLivenessSetupResult!.userId, delegate: self)
        }
        else{
            livenessTestFailed(error: AcuantError())
        }
    }
    
    func livenessTestProcessing(progress: Double, message: String) {
        DispatchQueue.main.async {
            self.showProgressView(text: "\(Int(progress * 100))%")
        }
    }
    
    func livenessTestCompletedWithError(error: AcuantError?) {
        livenessTestFailed(error: AcuantError())
    }
}

extension RootViewController : LivenessTestResultDelegate{
    func livenessTestResultReceived(result: LivenessTestResult) {
        if(result.passedLivenessTest){
            self.livenessString =  "IP Liveness : true"
        }
        else{
            self.livenessString =  "IP Liveness : false"
        }
        self.faceCapturedImage = result.image
        processFacialMatch(image: result.image)
        
        self.faceProcessingGroup.notify(queue: .main){
            self.showResultGroup.leave()
        }
    }
    
    func livenessTestResultReceiveFailed(error: AcuantError) {
        livenessTestFailed(error:error)
    }
    
    func livenessTestFailed(error:AcuantError) {
        self.livenessString = "IP Liveness: failed"
        self.showResultGroup.leave()
    }
}

//IPLiveness - END ============

//Passive Liveness + FaceCapture - START ============


extension RootViewController {
    private func processPassiveLiveness(image:UIImage){
        self.faceProcessingGroup.enter()
        AcuantPassiveLiveness.postLiveness(request: AcuantLivenessRequest(image: image)){ [weak self]
            (result, error) in
            if(result != nil && (result?.result == AcuantLivenessAssessment.Live || result?.result == AcuantLivenessAssessment.NotLive)){
                self?.livenessString = "Liveness: \(result!.result.rawValue)"
            }
            else{
                self?.livenessString = "Liveness: \(result?.result.rawValue ?? "Unknown") \(error?.errorCode?.rawValue ?? "") \(error?.description ?? "")"
            }
            self?.faceProcessingGroup.leave()
        }
    }
    
    public func showPassiveLiveness(){
        DispatchQueue.main.async {
            let controller = AcuantFaceCaptureController()
            controller.callback = { [weak self]
                (image) in
                
                if(image != nil){
                    self?.faceCapturedImage = image
                    self?.processPassiveLiveness(image: image!)
                    self?.processFacialMatch(image: image!)
                }
                
                self?.faceProcessingGroup.notify(queue: .main){
                    self?.showResultGroup.leave()
                }
            }
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func showFacialCaptureInterface(){
        self.showResultGroup.enter()
        
        let faceIndex = livenessOption.selectedSegmentIndex
        
        if(faceIndex == 1){
            self.showPassiveLiveness()
            
        }
        else if (faceIndex == 2){
            AcuantIPLiveness.performLivenessSetup(delegate: self)
        }
        else{
            self.showResultGroup.leave()
        }
    }
}

//Passive Liveness + FaceCapture - END ============


//FaceMatch - START ============
extension RootViewController : FacialMatchDelegate{
    func facialMatchFinished(result: FacialMatchResult?) {
        self.faceProcessingGroup.leave()
        
        if(result?.error == nil){
            capturedFacialMatchResult = result
        }
    }
    func processFacialMatch(image:UIImage?){
        self.faceProcessingGroup.enter()
        self.showProgressView(text: "Processing...")
        self.getDataGroup.notify(queue: .main){
            if(self.capturedFaceImageUrl != nil && image != nil){
                let loginData = String(format: "%@:%@", Credential.username()!, Credential.password()!).data(using: String.Encoding.utf8)!
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
                        
                        if(downloadedImage != nil){
                            let facialMatchData = FacialMatchData(faceImageOne: downloadedImage!, faceImageTwo: image!)
                            AcuantFaceMatch.processFacialMatch(facialData: facialMatchData, delegate: self)
                        }
                        else{
                            self.faceProcessingGroup.leave()
                        }
                        
                    }else {
                        self.faceProcessingGroup.leave()
                        
                        return
                    }
                }.resume()
            }else{
                self.faceProcessingGroup.leave()
                
                DispatchQueue.main.async {
                    self.hideProgressView()
                }
            }
        }
    }
}
//FaceMatch - END ============
