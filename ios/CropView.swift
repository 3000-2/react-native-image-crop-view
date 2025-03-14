import UIKit
import React
import TOCropViewController
import Photos

// MARK: - CropContentView
@objc(CropContentView)
class CropContentView: RCTView, TOCropViewDelegate {
    
    private var inlineCropView: TOCropView?
    
    @objc var sourceUrl: String?
    @objc var keepAspectRatio: Bool = false
    @objc var iosDimensionSwapEnabled: Bool = false
    @objc var cropAspectRatio: CGSize = .zero
    @objc var onCropMove: RCTDirectEventBlock?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if inlineCropView == nil, let sourceUrl = sourceUrl {
            let croppingStyle = TOCropViewCroppingStyle.default
            
            if sourceUrl.starts(with: "ph://") {
                let url = sourceUrl.replacingOccurrences(of: "ph://", with: "")
                let requestOptions = PHImageRequestOptions()
                requestOptions.resizeMode = .exact
                requestOptions.deliveryMode = .highQualityFormat
                requestOptions.isSynchronous = true
                
                let photosAsset = PHAsset.fetchAssets(withLocalIdentifiers: [url], options: nil).lastObject
                let manager = PHImageManager.default()
                var blockImage: UIImage?
                
                manager.requestImage(for: photosAsset!,
                                    targetSize: PHImageManagerMaximumSize,
                                    contentMode: .default,
                                    options: requestOptions) { (image, _) in
                    blockImage = image
                }
                
                inlineCropView = TOCropView(image: blockImage!)
            } else {
                if let url = URL(string: sourceUrl),
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    inlineCropView = TOCropView(image: image)
                }
            }
            
            if let inlineCropView = inlineCropView {
                inlineCropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                inlineCropView.frame = self.bounds
                
                inlineCropView.setGridOverlayHidden(true, animated: false)
                inlineCropView.simpleRenderMode = true
                
                inlineCropView.aspectRatioLockEnabled = keepAspectRatio
                inlineCropView.cropBoxResizeEnabled = !keepAspectRatio
                inlineCropView.aspectRatioLockDimensionSwapEnabled = iosDimensionSwapEnabled
                
                if cropAspectRatio != .zero {
                    inlineCropView.aspectRatio = cropAspectRatio
                }
                
                inlineCropView.moveCroppedContentToCenter(animated: false)
                inlineCropView.performInitialSetup()
                
                inlineCropView.delegate = self
                self.addSubview(inlineCropView)
            }
        }
    }
    
    @objc func getCroppedImage() -> UIImage? {
        guard let inlineCropView = inlineCropView else { return nil }
        return inlineCropView.image.croppedImage(withFrame: inlineCropView.imageCropFrame, 
                                               angle: inlineCropView.angle, 
                                               circularClip: false)
    }
    
    @objc func getCropFrame() -> CGRect {
        return inlineCropView?.imageCropFrame ?? .zero
    }
    
    @objc func getCurrentCropInfo() -> [String: Any] {
        let cropFrame = getCropFrame()
        return [
            "width": cropFrame.size.width,
            "height": cropFrame.size.height,
            "x": cropFrame.origin.x,
            "y": cropFrame.origin.y
        ]
    }
    
    @objc func setCropAspectRatio(_ aspectRatio: CGSize) {
        inlineCropView?.aspectRatio = aspectRatio
        cropAspectRatio = aspectRatio
    }
    
    @objc func setKeepAspectRatio(_ keepRatio: Bool) {
        inlineCropView?.aspectRatioLockEnabled = keepRatio
        keepAspectRatio = keepRatio
    }
    
    @objc func setIosDimensionSwapEnabled(_ enabled: Bool) {
        inlineCropView?.aspectRatioLockDimensionSwapEnabled = enabled
        iosDimensionSwapEnabled = enabled
    }
    
    @objc func rotateImage(_ clockwise: Bool) {
        inlineCropView?.rotateImageNinetyDegrees(animated: true, clockwise: clockwise)
    }
    
    // MARK: - TOCropViewDelegate Methods
    
    func cropViewDidBecomeResettable(_ cropView: TOCropView) {
        if let onCropMove = onCropMove {
            onCropMove(getCurrentCropInfo())
        }
    }
    
    func cropViewDidEndResize(_ cropView: TOCropView) {
        if let onCropMove = onCropMove {
            onCropMove(getCurrentCropInfo())
        }
    }
}

// MARK: - CropView (ViewManager)
@objc(CropView)
class CropViewManager: RCTViewManager {
    
    override func view() -> UIView! {
        return CropContentView()
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc func cropImage(_ reactTag: NSNumber,
                        preserveTransparency: Bool,
                        quality: NSNumber,
                        resolver resolve: @escaping RCTPromiseResolveBlock,
                        rejecter reject: @escaping RCTPromiseRejectBlock) {
        
        DispatchQueue.main.async {
            self.bridge.uiManager.addUIBlock { (uiManager, viewRegistry) in
                guard let cropView = viewRegistry[reactTag] as? CropContentView else {
                    reject("no_view", "Could not find CropView", nil)
                    return
                }
                
                let cropFrame = cropView.getCropFrame()
                guard let image = cropView.getCroppedImage() else {
                    reject("no_image", "Could not retrieve cropped image", nil)
                    return
                }
                
                var extension = "jpg"
                if (image.hasAlpha && preserveTransparency) {
                    extension = "png"
                }
                
                let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
                let url = paths[0].appendingPathComponent("\(UUID().uuidString).\(extension)")
                
                var success = false
                
                if (image.hasAlpha && preserveTransparency) {
                    if let pngData = image.pngData() {
                        try? pngData.write(to: url)
                        success = true
                    }
                } else {
                    if let jpegData = image.jpegData(compressionQuality: quality.floatValue / 100.0) {
                        try? jpegData.write(to: url)
                        success = true
                    }
                }
                
                if success {
                    resolve([
                        "uri": url.absoluteString,
                        "width": cropFrame.size.width,
                        "height": cropFrame.size.height,
                        "x": cropFrame.origin.x,
                        "y": cropFrame.origin.y
                    ])
                } else {
                    reject("crop_failed", "Failed to crop the image", nil)
                }
            }
        }
    }
    
    @objc func rotateImage(_ reactTag: NSNumber, clockwise: Bool) {
        DispatchQueue.main.async {
            self.bridge.uiManager.addUIBlock { (uiManager, viewRegistry) in
                guard let cropView = viewRegistry[reactTag] as? CropContentView else { return }
                cropView.rotateImage(clockwise)
            }
        }
    }
}

// MARK: - UIImage Extension for hasAlpha property
extension UIImage {
    var hasAlpha: Bool {
        guard let alphaInfo = self.cgImage?.alphaInfo else { return false }
        return alphaInfo != .none && 
               alphaInfo != .noneSkipFirst && 
               alphaInfo != .noneSkipLast
    }
}