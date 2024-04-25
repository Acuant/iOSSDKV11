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
import AcuantPassiveLiveness
import AcuantFaceCapture
import AVFoundation
import AcuantEchipReader

class RootViewController: UIViewController{
    
    @IBOutlet weak var autoCaptureSwitch : UISwitch!
    @IBOutlet weak var detailDescSwitch: UISwitch!
    @IBOutlet weak var medicalCardButton: UIButton!
    @IBOutlet weak var idPassportButton: UIButton!
    @IBOutlet weak var livenessOption: UISegmentedControl!
    @IBOutlet weak var mrzButton: UIButton!
    @IBOutlet weak var detailedAuthStackView: UIStackView!
    @IBOutlet weak var livenessStackView: UIStackView!
    
    public var documentInstance : String?
    public var livenessString: String?
    public var capturedFacialMatchResult : FacialMatchResult? = nil
    public var capturedFaceImageUrl : String? = nil
    private var isInitialized = false
    private var isKeyless = false
    private var faceCapturedImage: UIImage?
    private var isDocumentWithBarcode = false
    
    public var idOptions = IdOptions()
    public var idData = IdData()
    
    var autoCapture = true
    var detailedAuth = true
    var progressView : AcuantProgressView!
    
    private let getDataGroup = DispatchGroup()
    private let faceProcessingGroup = DispatchGroup()
    private let showResultGroup = DispatchGroup()
    private let createInstanceGroup = DispatchGroup()
    
    private let service: IAcuantTokenService = AcuantTokenService()
    
    //    private let passportReader = PassportReader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autoCaptureSwitch.setOn(autoCapture, animated: false)
        autoCaptureSwitch.setOn(detailedAuth, animated: false)
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
    
    override func viewDidLayoutSubviews() {
        progressView.update(frame: view.frame, center: view.center)
    }

    func getToken(){
        self.medicalCardButton.isEnabled = false
        self.idPassportButton.isEnabled = false
        self.mrzButton.isEnabled = false
        
        let task = self.service.getTask() {
            token in
            
            DispatchQueue.main.async {
                if let success = token {
                    if Credential.setToken(token: success) {
                        self.isKeyless = Credential.subscription() == nil || Credential.subscription() == ""
                        if !self.isInitialized {
                            self.initialize()
                        } else {
                            self.hideProgressView()
                            CustomAlerts.display(title: "Success",
                                                 message: "Valid New Token",
                                                 action: UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: nil))
                            self.medicalCardButton.isEnabled = true
                            self.idPassportButton.isEnabled = true
                            self.mrzButton.isEnabled = true
                        }
                    } else {
                        self.hideProgressView()
                        CustomAlerts.displayError(message: "Invalid Token")
                        self.medicalCardButton.isEnabled = true
                        self.idPassportButton.isEnabled = true
                        self.mrzButton.isEnabled = true
                    }
                } else {
                    self.hideProgressView()
                    CustomAlerts.displayError(message: "Failed to get Token")
                    self.medicalCardButton.isEnabled = true
                    self.idPassportButton.isEnabled = true
                    self.mrzButton.isEnabled = true
                }
            }
        }
        
        task?.resume()
    }

    private func initialize() {
        let initalizer: IAcuantInitializer = AcuantInitializer()
        var packages: [IAcuantPackage] = [ImagePreparationPackage()]
        
        if #available(iOS 13, *) {
            packages.append(AcuantEchipPackage())
        }
        
        _ = initalizer.initialize(packages: packages) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }

                if let error = error {
                    self.hideProgressView()
                    self.medicalCardButton.isEnabled = true
                    self.idPassportButton.isEnabled = true
                    self.mrzButton.isEnabled = true
                    if let msg = error.errorDescription {
                        CustomAlerts.displayError(message: "\(error.errorCode) : " + msg)
                    }
                } else {
                    self.mrzButton.isHidden = !Credential.authorization().hasOzone && !Credential.authorization().chipExtract
                    self.livenessStackView.isHidden = self.isKeyless
                    self.detailedAuthStackView.isHidden = self.isKeyless

                    self.hideProgressView()
                    self.medicalCardButton.isEnabled = true
                    self.idPassportButton.isEnabled = true
                    self.mrzButton.isEnabled = true
                    self.isInitialized = true
                    self.resetData()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.isInitialized{
            self.getToken()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onMrzEchipTapped(_ sender: Any) {
        self.handleInitialization(isDocumentCapture: false)
    }
    
    @IBAction func idPassportTapped(_ sender: UIButton) {
        self.idOptions.isHealthCard = false
        self.handleInitialization()
    }
    
    @IBAction func healthCardTapped(_ sender: UIButton){
        self.idOptions.isHealthCard = true
        self.handleInitialization()
    }
    
    @IBAction func detailedAuthSwitched(_ sender: UISwitch) {
        if sender.isOn {
            detailedAuth =  true
        } else {
            detailedAuth =  false
        }
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
        livenessString = nil
        faceCapturedImage = nil
        self.idOptions.cardSide = DocumentSide.front
        self.createInstance()
    }
    
    public func confirmImage(image: AcuantImage) {
        if isKeyless {
            if image.isPassport || self.idOptions.cardSide == DocumentSide.back {
                self.showKeylessHGLiveness()
            } else {
                let alert = UIAlertController(title: NSLocalizedString("Back Side?", comment: ""),
                                              message: NSLocalizedString("Scan the back side of the ID document", comment: ""),
                                              preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { action -> Void in
                    self.idOptions.cardSide = DocumentSide.back
                    self.showDocumentCaptureCamera()
                })
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            self.createInstanceGroup.notify(queue: .main) {
                self.showProgressView(text: "Processing...")

                let evaluted = EvaluatedImageData(imageBytes: image.data, barcodeString: self.idData.barcodeString)

                //use for testing purposes
                //self.saveToFile(data: image.data)

                DocumentProcessing.uploadImage(instancdId: self.documentInstance!, data: evaluted, options: self.idOptions, delegate: self)
            }
        }
    }
    
    private func saveToFile(data: NSData){
        let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        let fileURL = documentDirectory?.appendingPathComponent("test.jpg")
        try? data.write(to: fileURL!)
    }
    
    
    public func retryCapture() {
        showDocumentCaptureCamera()
    }
    
    public func retryClassification() {
        self.idOptions.isRetrying = true
        showDocumentCaptureCamera()
    }
    
    func isBackSideRequired(classification: Classification) -> Bool {
        guard let supportedImages = classification.type?.supportedImages else {
            return false
        }

        return supportedImages.contains(where: {
            $0.light == .white && $0.side == .back
        })
    }
}

//ImagePreparation - START =============
extension RootViewController{
    private func handleInitialization(isDocumentCapture : Bool = true){
        if(CheckConnection.isConnectedToNetwork() == false){
            CustomAlerts.displayError(message: CheckConnection.ERROR_INTERNET_UNAVAILABLE)
        }
        else{
            let token = Credential.getToken()
            
            if(!self.isInitialized || (token != nil && !token!.isValid())){
                self.getToken()
                self.showProgressView(text: "Initializing...")
            }
            else if (isDocumentCapture){
                self.resetData()
                self.showDocumentCaptureCamera()
            }
            else{
                self.resetData()
                
                if #available (iOS 13, *) {
                    showMrzReaderHelperController()
                }
                else{
                    CustomAlerts.displayError(message: "Need iOS 13 or later")
                }
            }
        }
    }

    private func showMrzReaderHelperController() {
        guard let mrzHelpVc =
                storyboard?.instantiateViewController(withIdentifier: "MrzHelpViewController")
                as? MrzHelpViewController else {
            fatalError("Failed to instatiate MrzHelpViewController")
        }

        mrzHelpVc.delegate = self
        navigationController?.pushViewController(mrzHelpVc, animated: true)
    }
}
//ImagePreparation - END =============

//MARK: - AcuantCamera: CameraCaptureDelegate

extension RootViewController: DocumentCameraViewControllerDelegate {

    public func onCaptured(image: Image, barcodeString: String?) {
        guard image.image != nil else {
            return
        }

        self.showProgressView(text: "Processing...")
        ImagePreparation.evaluateImage(data: CroppingData.newInstance(image: image)) { result, error in
            DispatchQueue.main.async {
                self.hideProgressView()
                if result != nil {
                    let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                    let confirmController = storyBoard.instantiateViewController(withIdentifier: "ConfirmationViewController") as! ConfirmationViewController
                    confirmController.acuantImage = result
                    if barcodeString != nil {
                        confirmController.barcodeCaptured = true
                        confirmController.barcodeString = barcodeString
                    }
                    self.idData.barcodeString = barcodeString
                    self.navigationController?.pushViewController(confirmController, animated: true)
                } else {
                    CustomAlerts.display(
                        title: "Error",
                        message: (error?.errorDescription)!,
                        action: UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default, handler: { (action:UIAlertAction) in self.retryCapture() }))
                }
            }
        }
    }
    
    func showDocumentCaptureCamera() {
        //Handler in .requestAccess is needed to process user's answer to our request
        AVCaptureDevice.requestAccess(for: .video) { [weak self] isPermissionGranted in
            guard let self = self else { return }

            if isPermissionGranted {
                DispatchQueue.main.async {
                    let textForState: (DocumentCameraState) -> String = { state in
                        switch state {
                        case .align: return NSLocalizedString("acuant_camera_align", comment: "")
                        case .moveCloser: return NSLocalizedString("acuant_camera_move_closer", comment: "")
                        case .tooClose: return NSLocalizedString("acuant_camera_too_close", comment: "")
                        case .steady: return NSLocalizedString("acuant_camera_hold_steady", comment: "")
                        case .hold: return NSLocalizedString("acuant_camera_hold", comment: "")
                        case .capture: return NSLocalizedString("acuant_camera_capturing", comment: "")
                        @unknown default: return ""
                        }
                    }
                    let colorForState: (DocumentCameraState) -> CGColor = { state in
                        switch state {
                        case .align: return UIColor.black.cgColor
                        case .moveCloser: return UIColor.red.cgColor
                        case .tooClose: return UIColor.red.cgColor
                        case .steady: return UIColor.yellow.cgColor
                        case .hold: return UIColor.yellow.cgColor
                        case .capture: return UIColor.green.cgColor
                        @unknown default: return UIColor.black.cgColor
                        }
                    }
                    let options = DocumentCameraOptions(countdownDigits: 2,
                                                        autoCapture: self.autoCapture,
                                                        textForState: textForState,
                                                        colorForState: colorForState,
                                                        textForManualCapture: NSLocalizedString("acuant_camera_manual_capture", comment: ""),
                                                        backButtonText: NSLocalizedString("acuant_camera_back_button_text", comment: ""))
                    let documentCameraViewController = DocumentCameraViewController(options: options)
                    documentCameraViewController.delegate = self
                    self.navigationController?.pushViewController(documentCameraViewController, animated: false)
                }
            } else {
                let alert = UIAlertController(title: "Camera", message: "Camera access is absolutely necessary to use this app", preferredStyle: .alert)
                
                // Add "OK" Button to alert, pressing it will bring you to the settings app
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }))

                self.present(alert, animated: true)
            }
        }
    }
    
    public func showKeylessHGLiveness(){
        let liveFaceViewController = FaceLivenessCameraController()
        
        //Optionally override to change refresh rate
        //liveFaceViewController.frameRefreshSpeed = 10
        
        self.navigationController?.pushViewController(liveFaceViewController, animated: false)
    }
}

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
            DocumentProcessing.createInstance(options: self.idOptions, delegate:self)
        }
    }
}

//MARK: - AcuantDocumentProcessing: UploadImageDelegate

extension RootViewController: UploadImageDelegate {
    
    func imageUploaded(error: AcuantError?, classification: Classification?) {
        self.hideProgressView()
        
        if error == nil {
            self.idOptions.isRetrying = false
            if self.idOptions.isHealthCard {
                if self.idOptions.cardSide == DocumentSide.front {
                    self.handleHealthcardFront()
                } else {
                    DocumentProcessing.getData(instanceId: self.documentInstance!, isHealthCard: true, delegate: self)
                    self.showProgressView(text: "Processing...")
                }
            } else {
                if self.idOptions.cardSide == DocumentSide.front {
                    if let classification = classification, self.isBackSideRequired(classification: classification) {
                        isDocumentWithBarcode = classification.type?.referenceDocumentDataTypes?.contains(.barcode2D) ?? false
                        let alert = UIAlertController(title: NSLocalizedString("Back Side?", comment: ""), message: NSLocalizedString("Scan the back side of the ID document", comment: ""), preferredStyle:UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                        { action -> Void in
                            self.idOptions.cardSide = DocumentSide.back
                            self.showDocumentCaptureCamera()
                        })
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.getIdDataAndStartFace()
                    }
                } else if idOptions.cardSide == .back, isDocumentWithBarcode, idData.barcodeString == nil {
                    let alert = UIAlertController(title: NSLocalizedString("Capture Barcode", comment: ""),
                                                  message: NSLocalizedString("Barcode Expected", comment: ""),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        let options = BarcodeCameraOptions(waitTimeAfterCapturingInSeconds: 1, timeoutInSeconds: 20)
                        let barcodeCamera = BarcodeCameraViewController(options: options)
                        barcodeCamera.delegate = self
                        self.navigationController?.pushViewController(barcodeCamera, animated: false)
                    })
                    present(alert, animated: true, completion: nil)
                } else {
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
    
    private func handleHealthcardFront() {
        let alert = UIAlertController(title: NSLocalizedString("Back Side?", comment: ""), message: NSLocalizedString("Scan the back side of the medical insurance card", comment: ""), preferredStyle:UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
        { action -> Void in
            self.idOptions.cardSide = DocumentSide.back
            self.showDocumentCaptureCamera()
        })
        alert.addAction(UIAlertAction(title: "SKIP", style: UIAlertAction.Style.default)
        { action -> Void in
            DocumentProcessing.getData(instanceId: self.documentInstance!, isHealthCard: true, delegate: self)
            self.showProgressView(text: "Processing...")
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    private func getIdDataAndStartFace(){
        if(Credential.endpoints()?.frmEndpoint != nil){
            self.showFacialCaptureInterface()
        }
        self.getDataGroup.enter()
        DocumentProcessing.getData(instanceId: self.documentInstance!, isHealthCard: false, delegate: self)
        self.showProgressView(text: "Processing...")
    }
}

func appendDetailed(dataArray: inout Array<String>, result: IDResult) {
    
    dataArray.append("Authentication Starts")
    dataArray.append("Authentication Overall : \(result.result?.name ?? "Not supported")")
    if let alerts = result.alerts {
        for alert in alerts {
            if alert.result != .passed {
                dataArray.append("\(alert.actionDescription ?? "nil") : \(alert.disposition ?? "nil")")
            }
        }
    }
    dataArray.append("Authentication Ends")
    dataArray.append("")
}

extension RootViewController: GetDataDelegate {

    func processingResultReceived(processingResult: ProcessingResult) {
        if processingResult.error == nil {
            if self.idOptions.isHealthCard {
                let healthCardResult = processingResult as! HealthInsuranceCardResult
                let frontImage = healthCardResult.frontImage
                let backImage = healthCardResult.backImage
                let mirrored_object = Mirror(reflecting: healthCardResult)
                var dataArray = Array<String>()
                //This is just a quick example of how to get some of the basic info.
                //In a real implementations you should pick each field individually
                for attr in mirrored_object.children {
                    if let property_name = attr.label as String? {
                        if property_name == "frontImageString" || property_name == "backImageString" {
                            continue
                        }
                        if let property_value = attr.value as? String {
                            if property_value != "" {
                                dataArray.append("\(property_name): \(property_value)")
                            }
                        } else if let addresses = attr.value as? [Address] {
                            for (index, address) in addresses.enumerated() {
                                if let fullAddress = address.fullAddress {
                                    dataArray.append("Address \(index + 1): \(fullAddress)")
                                }
                            }
                        } else if let labelValuePairs = attr.value as? [LabelValuePair] {
                            for pair in labelValuePairs {
                                if let label = pair.label, let value = pair.value {
                                    dataArray.append("\(label): \(value)")
                                }
                            }
                        } else if let planCodes = attr.value as? [PlanCode] {
                            for (index, planCode) in planCodes.enumerated() {
                                if let code = planCode.planCode {
                                    dataArray.append("Plan Code \(index + 1): \(code)")
                                }
                            }
                        }
                    }
                }
                
                showHealthCardResult(data: dataArray, front: frontImage, back: backImage)
                DocumentProcessing.deleteInstance(instanceId: healthCardResult.instanceID!, type: DeleteType.MedicalCard, delegate: self)
                
            } else {
                let idResult = processingResult as! IDResult
                guard let fields = idResult.fields, !fields.isEmpty else {
                    self.hideProgressView()
                    CustomAlerts.displayError(message: "Could not extract data")
                    getDataGroup.leave()
                    return
                }
                
                var frontImageUri: String?
                var backImageUri: String?
                var signImageUri: String?
                var faceImageUri: String?
                var dataArray = [String]()
                
                if !detailedAuth {
                    dataArray.append("Authentication Result : \(idResult.result?.name ?? "Not supported")")
                } else {
                    appendDetailed(dataArray: &dataArray, result: idResult)
                }

                for field in fields {
                    if field.type == "string" {
                        dataArray.append("\(field.key!) : \(field.value!)")
                    } else if field.type == "datetime" {
                        dataArray.append("\(field.key!) : \(Utils.dateFieldToDateString(dateStr: field.value!)!)")
                    } else if field.key == "Photo", field.type == "uri" {
                        faceImageUri = field.value
                        capturedFaceImageUrl = faceImageUri
                    } else if field.key == "Signature" && field.type == "uri" {
                        signImageUri = field.value
                    }
                }
                
                for image in idResult.images! {
                    if case .front = image.side {
                        frontImageUri = image.uri
                    } else if case .back = image.side {
                        backImageUri = image.uri
                    }
                }
                
                self.showResult(data: dataArray, front: frontImageUri, back: backImageUri, sign: signImageUri, face: faceImageUri)
            }
        } else {
            self.hideProgressView()
            if let msg = processingResult.error?.errorDescription {
                CustomAlerts.displayError(message: msg)
            }
        }
    }
    
    func showResult(data: [String]?, front: String?, back: String?, sign: String?, face: String?) {
        self.getDataGroup.leave()
        self.showResultGroup.notify(queue: .main) {
            self.hideProgressView()
            let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
            let resultViewController = storyBoard.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
            resultViewController.data = data
            
            if let livenessText = self.livenessString {
                resultViewController.data?.insert("", at: 0)
                resultViewController.data?.insert(livenessText, at: 0)
            }
            
            if let facialMatchResult = self.capturedFacialMatchResult {
                resultViewController.data?.insert("Face matched : \(facialMatchResult.isMatch)", at: 0)
                resultViewController.data?.insert("Face Match score : \(facialMatchResult.score)", at: 0)
            }
            
            resultViewController.frontImageUrl = front
            resultViewController.backImageUrl = back
            resultViewController.signImageUrl = sign
            resultViewController.faceImageUrl = face
            resultViewController.auth = Credential.getAcuantAuthHeader()
            resultViewController.faceImageCaptured = self.faceCapturedImage
            self.navigationController?.pushViewController(resultViewController, animated: true)
        }
    }
    
    func showHealthCardResult(data: [String]? ,front: UIImage?, back: UIImage?) {
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

extension RootViewController: DeleteDelegate {
    func instanceDeleted(success: Bool) {
        print()
    }
}
//DocumentProcessing - END ============

//Passive Liveness + FaceCapture - START ============

extension RootViewController {
    private func processPassiveLiveness(imageData: Data) {
        self.faceProcessingGroup.enter()
        PassiveLiveness.postLiveness(request: AcuantLivenessRequest(jpegData: imageData)) { [weak self] result, error in
            if let livenessResult = result,
               (livenessResult.result == AcuantLivenessAssessment.live || livenessResult.result == AcuantLivenessAssessment.notLive) {
                self?.livenessString = "Liveness : \(livenessResult.result.rawValue)"
            } else {
                self?.livenessString = "Liveness : \(result?.result.rawValue ?? "Unknown") \(error?.errorCode?.rawValue ?? "") \(error?.description ?? "")"
            }
            self?.faceProcessingGroup.leave()
        }
    }
    
    public func showPassiveLiveness() {
        DispatchQueue.main.async {
            let controller = FaceCaptureController()
            controller.callback = { [weak self] faceCaptureResult in
                guard let self = self else { return }
                
                if let result = faceCaptureResult {
                    self.faceCapturedImage = result.image
                    self.processPassiveLiveness(imageData: result.jpegData)
                    self.processFacialMatch(imageData: result.jpegData)
                }
                
                self.faceProcessingGroup.notify(queue: .main) {
                    self.showResultGroup.leave()
                }
            }
            self.navigationController?.pushViewController(controller, animated: false)
        }
    }
    
    func showFacialCaptureInterface() {
        self.showResultGroup.enter()
        let faceIndex = livenessOption.selectedSegmentIndex
        if faceIndex == 1 {
            self.showPassiveLiveness()
        } else {
            self.showResultGroup.leave()
        }
    }
}

//Passive Liveness + FaceCapture - END ============


//MARK: - FaceMatchDelegate

extension RootViewController: FacialMatchDelegate {
    func facialMatchFinished(result: FacialMatchResult?) {
        self.faceProcessingGroup.leave()
        
        if(result?.error == nil){
            capturedFacialMatchResult = result
        }
    }

    func processFacialMatch(imageData: Data) {
        self.faceProcessingGroup.enter()
        self.showProgressView(text: "Processing...")
        self.getDataGroup.notify(queue: .main) {
            if let capturedFaceImageUrl = self.capturedFaceImageUrl,
               let url = URL(string: capturedFaceImageUrl),
               let auth = Credential.getAcuantAuthHeader() {

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue(auth, forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    let httpURLResponse = response as? HTTPURLResponse
                    if httpURLResponse?.statusCode == 200 {
                        if let downloadedImageData = data {
                            let facialMatchData = FacialMatchData(faceOneData: downloadedImageData, faceTwoData: imageData)
                            FaceMatch.processFacialMatch(facialData: facialMatchData, delegate: self)
                        } else {
                            self.faceProcessingGroup.leave()
                        }
                    } else {
                        self.faceProcessingGroup.leave()
                        return
                    }
                }.resume()
            } else {
                self.faceProcessingGroup.leave()
                
                DispatchQueue.main.async {
                    self.hideProgressView()
                }
            }
        }
    }
}

// MARK: - MrzHelpViewControllerDelegate

extension RootViewController: MrzHelpViewControllerDelegate {

    func dismissed() {
        guard #available(iOS 13, *) else { return }

        showMrzCamera()
    }

    @available (iOS 13, *)
    private func showMrzCamera() {
        let textForState: (MrzCameraState) -> String = { state in
            switch state {
            case .align: return NSLocalizedString("acuant_camera_align", comment: "")
            case .moveCloser: return NSLocalizedString("acuant_camera_move_closer", comment: "")
            case .tooClose: return NSLocalizedString("acuant_camera_too_close", comment: "")
            case .reposition: return NSLocalizedString("acuant_camera_reposition", comment: "")
            case .good: return NSLocalizedString("acuant_camera_reading_mrz", comment: "")
            case .captured: return NSLocalizedString("acuant_camera_captured", comment: "")
            case .none: return ""
            @unknown default: return ""
            }
        }
        let options = MrzCameraOptions(textForState: textForState,
                                       backButtonText: NSLocalizedString("acuant_camera_back_button_text", comment: ""))
        let mrzCameraViewController = MrzCameraViewController(options: options)
        mrzCameraViewController.delegate = self
        navigationController?.pushViewController(mrzCameraViewController, animated: false)
    }
}

//MARK: - AcuantCamera: BarcodeCameraDelegate

extension RootViewController: BarcodeCameraViewControllerDelegate {

    func onCaptured(barcode: String?) {
        guard let barcode = barcode, let documentInstanceId = documentInstance else {
            getIdDataAndStartFace()
            return
        }
        
        idData.barcodeString = barcode
        DocumentProcessing.uploadBarcode(instanceId: documentInstanceId, barcodeString: barcode, delegate: self)
    }
}

// MARK: - MrzCameraViewControllerDelegate

extension RootViewController: MrzCameraViewControllerDelegate {
    func onCaptured(mrz: AcuantCamera.AcuantMrzResult?) {
        guard let success = mrz else { return }

        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if #available(iOS 13, *) {
                let vc = storyboard.instantiateViewController(withIdentifier: "NFCViewController") as! NFCViewController
                vc.result = success
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
