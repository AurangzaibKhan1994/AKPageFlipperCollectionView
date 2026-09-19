//
//  AKPageFlipperCollectionView.swift
//  AKPageFlipperCollectionView
//
//  Created by avanza on 19/09/2026.
//

import UIKit
import QuartzCore

// MARK: - 1. Flip Orientation Enum
public enum AKFlipOrientation {
    case vertical   // Flips Top/Bottom halves vertically (Page N -> Page N+1 via drag UP)
    case horizontal // Flips Left/Right halves horizontally like a book (Page N -> Page N+1 via drag LEFT)
}

// MARK: - 2. Fold Mode Enum
public enum AKFoldMode {
    case lowerHalfUp   // Vertical: Dragged UP -> Flips Lower Half UPWARDS (Page N -> Page N+1)
    case upperHalfDown // Vertical: Dragged DOWN -> Flips Upper Half DOWNWARDS (Page N -> Page N-1)
    case rightHalfLeft // Horizontal: Dragged LEFT -> Flips Right Half LEFTWARDS (Page N -> Page N+1)
    case leftHalfRight // Horizontal: Dragged RIGHT -> Flips Left Half RIGHTWARDS (Page N -> Page N-1)
    case disabled      // Idle / Inactive
}

// MARK: - Optional Delegate Protocol for Direct Image Provision
@objc public protocol AKPageFlippingDelegate: AnyObject {
    @objc optional func pageFlippingCollectionView(_ collectionView: AKPageFlipperCollectionView, imageForPageAt index: Int) -> UIImage?
}

// MARK: - 3. Custom Layout Attributes
open class AKPageFlipLayoutAttributes: UICollectionViewLayoutAttributes {
    public var isTopPage: Bool = false
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! AKPageFlipLayoutAttributes
        copy.isTopPage = self.isTopPage
        return copy
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? AKPageFlipLayoutAttributes else { return false }
        return super.isEqual(object) && self.isTopPage == rhs.isTopPage
    }
}

// MARK: - 4. Bi-Directional Symmetrical Layout
open class AKPageFlippingLayout: UICollectionViewLayout {
    
    override open class var layoutAttributesClass: AnyClass {
        return AKPageFlipLayoutAttributes.self
    }
    
    override open var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return .zero }
        let pageHeight = max(1, collectionView.bounds.height)
        let pageWidth = max(1, collectionView.bounds.width)
        return CGSize(width: pageWidth, height: pageHeight)
    }
    
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView as? AKPageFlipperCollectionView else { return nil }
        let itemCount = collectionView.numberOfItems(inSection: 0)
        guard itemCount > 0 else { return [] }
        
        var attributesList: [UICollectionViewLayoutAttributes] = []
        let currentPage = collectionView.currentPage
        
        if currentPage >= 0 && currentPage < itemCount {
            if let attr = layoutAttributesForItem(at: IndexPath(item: currentPage, section: 0)) {
                attributesList.append(attr)
            }
        }
        
        if collectionView.activeFoldMode != .disabled {
            let targetPage: Int
            if collectionView.activeFoldMode == .lowerHalfUp || collectionView.activeFoldMode == .rightHalfLeft {
                targetPage = min(itemCount - 1, currentPage + 1)
            } else {
                targetPage = max(0, currentPage - 1)
            }
            if targetPage != currentPage && targetPage >= 0 && targetPage < itemCount {
                if let targetAttr = layoutAttributesForItem(at: IndexPath(item: targetPage, section: 0)) {
                    attributesList.append(targetAttr)
                }
            }
        }
        
        return attributesList
    }
    
    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView as? AKPageFlipperCollectionView else { return nil }
        let attributes = AKPageFlipLayoutAttributes(forCellWith: indexPath)
        
        let pageHeight = max(1, collectionView.bounds.height)
        let pageWidth = max(1, collectionView.bounds.width)
        let currentPage = collectionView.currentPage
        let activeFoldMode = collectionView.activeFoldMode
        let itemCount = collectionView.numberOfItems(inSection: 0)
        
        let targetPage: Int
        if activeFoldMode == .lowerHalfUp || activeFoldMode == .rightHalfLeft {
            targetPage = min(itemCount - 1, currentPage + 1)
        } else if activeFoldMode == .upperHalfDown || activeFoldMode == .leftHalfRight {
            targetPage = max(0, currentPage - 1)
        } else {
            targetPage = currentPage
        }
        
        attributes.frame = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        if indexPath.item == currentPage {
            attributes.isTopPage = true
            attributes.zIndex = 1000
            attributes.alpha = 1.0
        } else if indexPath.item == targetPage && activeFoldMode != .disabled {
            attributes.isTopPage = false
            attributes.zIndex = 500
            attributes.alpha = 1.0
        } else {
            attributes.isTopPage = false
            attributes.zIndex = 0
            attributes.alpha = 0.0
        }
        
        return attributes
    }
}

// MARK: - 5. Internal 3D Fold Overlay View (Handles Vertical & Horizontal 3D Geometry)
internal class AKFoldOverlayView: UIView {
    
    public var isShadowEnabled: Bool = true
    
    private let foldContainerLayer = CALayer()
    private let firstStaticLayer = CALayer()  // Top half (vertical) or Left half (horizontal)
    private let secondStaticLayer = CALayer() // Bottom half (vertical) or Right half (horizontal)
    
    private let flapContainerLayer = CATransformLayer()
    private let flapFrontLayer = CALayer()
    private let flapBackLayer = CALayer()
    
    private let firstShadowLayer = CAGradientLayer()
    private let secondShadowLayer = CAGradientLayer()
    private let flapFrontShadowLayer = CAGradientLayer()
    private let flapBackShadowLayer = CAGradientLayer()
    
    private var currentMode: AKFoldMode = .disabled
    private var orientation: AKFlipOrientation = .vertical
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false
        
        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 1000.0
        foldContainerLayer.sublayerTransform = perspective
        
        firstStaticLayer.masksToBounds = true
        secondStaticLayer.masksToBounds = true
        
        flapFrontLayer.isDoubleSided = false
        flapFrontLayer.masksToBounds = true
        
        flapBackLayer.isDoubleSided = false
        flapBackLayer.masksToBounds = true
        
        flapContainerLayer.addSublayer(flapFrontLayer)
        flapContainerLayer.addSublayer(flapBackLayer)
        
        // Shadow for firstStaticLayer
        firstShadowLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        firstShadowLayer.opacity = 0.0
        firstStaticLayer.addSublayer(firstShadowLayer)
        
        // Shadow for secondStaticLayer
        secondShadowLayer.colors = [UIColor.black.withAlphaComponent(0.6).cgColor, UIColor.clear.cgColor]
        secondShadowLayer.opacity = 0.0
        secondStaticLayer.addSublayer(secondShadowLayer)
        
        // Shadow for Flap Front & Back
        flapFrontShadowLayer.opacity = 0.0
        flapFrontLayer.addSublayer(flapFrontShadowLayer)
        
        flapBackShadowLayer.opacity = 0.0
        flapBackLayer.addSublayer(flapBackShadowLayer)
        
        foldContainerLayer.addSublayer(firstStaticLayer)
        foldContainerLayer.addSublayer(secondStaticLayer)
        foldContainerLayer.addSublayer(flapContainerLayer)
        
        self.layer.addSublayer(foldContainerLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        let height = bounds.height
        guard width > 0 && height > 0 else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        foldContainerLayer.frame = bounds
        
        if orientation == .vertical {
            let halfHeight = height / 2.0
            firstStaticLayer.bounds = CGRect(x: 0, y: 0, width: width, height: halfHeight)
            firstStaticLayer.position = CGPoint(x: width / 2.0, y: halfHeight / 2.0)
            
            secondStaticLayer.bounds = CGRect(x: 0, y: 0, width: width, height: halfHeight)
            secondStaticLayer.position = CGPoint(x: width / 2.0, y: halfHeight + halfHeight / 2.0)
            
            flapFrontLayer.bounds = CGRect(x: 0, y: 0, width: width, height: halfHeight)
            flapFrontLayer.position = CGPoint(x: width / 2.0, y: halfHeight / 2.0)
            
            flapBackLayer.bounds = CGRect(x: 0, y: 0, width: width, height: halfHeight)
            flapBackLayer.position = CGPoint(x: width / 2.0, y: halfHeight / 2.0)
            
            firstShadowLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            firstShadowLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            
            secondShadowLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            secondShadowLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            
        } else {
            let halfWidth = width / 2.0
            firstStaticLayer.bounds = CGRect(x: 0, y: 0, width: halfWidth, height: height)
            firstStaticLayer.position = CGPoint(x: halfWidth / 2.0, y: height / 2.0)
            
            secondStaticLayer.bounds = CGRect(x: 0, y: 0, width: halfWidth, height: height)
            secondStaticLayer.position = CGPoint(x: halfWidth + halfWidth / 2.0, y: height / 2.0)
            
            flapFrontLayer.bounds = CGRect(x: 0, y: 0, width: halfWidth, height: height)
            flapFrontLayer.position = CGPoint(x: halfWidth / 2.0, y: height / 2.0)
            
            flapBackLayer.bounds = CGRect(x: 0, y: 0, width: halfWidth, height: height)
            flapBackLayer.position = CGPoint(x: halfWidth / 2.0, y: height / 2.0)
            
            firstShadowLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            firstShadowLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            
            secondShadowLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            secondShadowLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        }
        
        firstShadowLayer.frame = firstStaticLayer.bounds
        secondShadowLayer.frame = secondStaticLayer.bounds
        flapFrontShadowLayer.frame = flapFrontLayer.bounds
        flapBackShadowLayer.frame = flapBackLayer.bounds
        
        updateFlapShadowFrames()
        updateFlapHingePosition()
        
        CATransaction.commit()
    }
    
    private func updateFlapShadowFrames() {
        flapFrontShadowLayer.frame = flapFrontLayer.bounds
        flapBackShadowLayer.frame = flapBackLayer.bounds
        
        if orientation == .vertical {
            if currentMode == .lowerHalfUp {
                flapFrontShadowLayer.colors = [UIColor.black.withAlphaComponent(0.4).cgColor, UIColor.clear.cgColor]
                flapFrontShadowLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                flapFrontShadowLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
                
                flapBackShadowLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.4).cgColor]
                flapBackShadowLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                flapBackShadowLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            } else if currentMode == .upperHalfDown {
                flapFrontShadowLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.4).cgColor]
                flapFrontShadowLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                flapFrontShadowLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
                
                flapBackShadowLayer.colors = [UIColor.black.withAlphaComponent(0.4).cgColor, UIColor.clear.cgColor]
                flapBackShadowLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                flapBackShadowLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            }
        } else {
            if currentMode == .rightHalfLeft {
                flapFrontShadowLayer.colors = [UIColor.black.withAlphaComponent(0.4).cgColor, UIColor.clear.cgColor]
                flapFrontShadowLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
                flapFrontShadowLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
                
                flapBackShadowLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.4).cgColor]
                flapBackShadowLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
                flapBackShadowLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            } else if currentMode == .leftHalfRight {
                flapFrontShadowLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.4).cgColor]
                flapFrontShadowLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
                flapFrontShadowLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
                
                flapBackShadowLayer.colors = [UIColor.black.withAlphaComponent(0.4).cgColor, UIColor.clear.cgColor]
                flapBackShadowLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
                flapBackShadowLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            }
        }
    }
    
    private func updateFlapHingePosition() {
        let width = bounds.width
        let height = bounds.height
        guard width > 0 && height > 0 else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if orientation == .vertical {
            let halfHeight = height / 2.0
            flapContainerLayer.bounds = CGRect(x: 0, y: 0, width: width, height: halfHeight)
            flapBackLayer.transform = CATransform3DMakeRotation(.pi, 1, 0, 0)
            
            if currentMode == .lowerHalfUp {
                flapContainerLayer.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                flapContainerLayer.position = CGPoint(x: width / 2.0, y: halfHeight)
            } else if currentMode == .upperHalfDown {
                flapContainerLayer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
                flapContainerLayer.position = CGPoint(x: width / 2.0, y: halfHeight)
            }
        } else {
            let halfWidth = width / 2.0
            flapContainerLayer.bounds = CGRect(x: 0, y: 0, width: halfWidth, height: height)
            flapBackLayer.transform = CATransform3DMakeRotation(.pi, 0, 1, 0)
            
            if currentMode == .rightHalfLeft {
                // Hinge at left edge of right half (middle line of screen)
                flapContainerLayer.anchorPoint = CGPoint(x: 0.0, y: 0.5)
                flapContainerLayer.position = CGPoint(x: halfWidth, y: height / 2.0)
            } else if currentMode == .leftHalfRight {
                // Hinge at right edge of left half (middle line of screen)
                flapContainerLayer.anchorPoint = CGPoint(x: 1.0, y: 0.5)
                flapContainerLayer.position = CGPoint(x: halfWidth, y: height / 2.0)
            }
        }
        
        CATransaction.commit()
    }
    
    private func createCGImage(from image: UIImage) -> CGImage? {
        if let cg = image.cgImage { return cg }
        guard let ci = image.ciImage else { return nil }
        let context = CIContext(options: nil)
        return context.createCGImage(ci, from: ci.extent)
    }
    
    func configure(currentImage: UIImage?, targetImage: UIImage?, mode: AKFoldMode, orientation: AKFlipOrientation) {
        guard let currentImg = currentImage, let currentCg = createCGImage(from: currentImg) else { return }
        
        self.currentMode = mode
        self.orientation = orientation
        
        let widthPx = CGFloat(currentCg.width)
        let heightPx = CGFloat(currentCg.height)
        
        let currentFirstCg: CGImage?
        let currentSecondCg: CGImage?
        var targetFirstCg: CGImage? = nil
        var targetSecondCg: CGImage? = nil
        
        if orientation == .vertical {
            let halfHeightPx = heightPx / 2.0
            currentFirstCg = currentCg.cropping(to: CGRect(x: 0, y: 0, width: widthPx, height: halfHeightPx))
            currentSecondCg = currentCg.cropping(to: CGRect(x: 0, y: halfHeightPx, width: widthPx, height: halfHeightPx))
            
            if let targetImg = targetImage, let targetCg = createCGImage(from: targetImg) {
                let tWidthPx = CGFloat(targetCg.width)
                let tHeightPx = CGFloat(targetCg.height)
                let tHalfHeightPx = tHeightPx / 2.0
                targetFirstCg = targetCg.cropping(to: CGRect(x: 0, y: 0, width: tWidthPx, height: tHalfHeightPx))
                targetSecondCg = targetCg.cropping(to: CGRect(x: 0, y: tHalfHeightPx, width: tWidthPx, height: tHalfHeightPx))
            }
        } else {
            let halfWidthPx = widthPx / 2.0
            currentFirstCg = currentCg.cropping(to: CGRect(x: 0, y: 0, width: halfWidthPx, height: heightPx))
            currentSecondCg = currentCg.cropping(to: CGRect(x: halfWidthPx, y: 0, width: halfWidthPx, height: heightPx))
            
            if let targetImg = targetImage, let targetCg = createCGImage(from: targetImg) {
                let tWidthPx = CGFloat(targetCg.width)
                let tHeightPx = CGFloat(targetCg.height)
                let tHalfWidthPx = tWidthPx / 2.0
                targetFirstCg = targetCg.cropping(to: CGRect(x: 0, y: 0, width: tHalfWidthPx, height: tHeightPx))
                targetSecondCg = targetCg.cropping(to: CGRect(x: tHalfWidthPx, y: 0, width: tHalfWidthPx, height: tHeightPx))
            }
        }
        
        layoutSubviews()
        updateFlapShadowFrames()
        updateFlapHingePosition()
        updateProgress(0.0, mode: mode)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if mode == .lowerHalfUp || mode == .rightHalfLeft {
            firstStaticLayer.contents = currentFirstCg
            secondStaticLayer.contents = targetSecondCg
            flapFrontLayer.contents = currentSecondCg
            flapBackLayer.contents = targetFirstCg
        } else if mode == .upperHalfDown || mode == .leftHalfRight {
            firstStaticLayer.contents = targetFirstCg
            secondStaticLayer.contents = currentSecondCg
            flapFrontLayer.contents = currentFirstCg
            flapBackLayer.contents = targetSecondCg
        }
        
        CATransaction.commit()
    }
    
    func updateProgress(_ progress: CGFloat, mode: AKFoldMode) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if orientation == .vertical {
            if mode == .lowerHalfUp {
                let angle = progress * CGFloat.pi
                flapContainerLayer.transform = CATransform3DMakeRotation(angle, 1, 0, 0)
            } else if mode == .upperHalfDown {
                let angle = -progress * CGFloat.pi
                flapContainerLayer.transform = CATransform3DMakeRotation(angle, 1, 0, 0)
            }
        } else {
            if mode == .rightHalfLeft {
                let angle = -progress * CGFloat.pi
                flapContainerLayer.transform = CATransform3DMakeRotation(angle, 0, 1, 0)
            } else if mode == .leftHalfRight {
                let angle = progress * CGFloat.pi
                flapContainerLayer.transform = CATransform3DMakeRotation(angle, 0, 1, 0)
            }
        }
        
        if isShadowEnabled {
            let shadowIntensity = Float(sin(progress * .pi))
            if mode == .lowerHalfUp || mode == .rightHalfLeft {
                firstShadowLayer.opacity = 0.0
                secondShadowLayer.opacity = shadowIntensity * 0.7
                flapFrontShadowLayer.opacity = shadowIntensity * 0.5
                flapBackShadowLayer.opacity = shadowIntensity * 0.5
            } else if mode == .upperHalfDown || mode == .leftHalfRight {
                firstShadowLayer.opacity = shadowIntensity * 0.7
                secondShadowLayer.opacity = 0.0
                flapFrontShadowLayer.opacity = shadowIntensity * 0.5
                flapBackShadowLayer.opacity = shadowIntensity * 0.5
            } else {
                firstShadowLayer.opacity = 0.0
                secondShadowLayer.opacity = 0.0
                flapFrontShadowLayer.opacity = 0.0
                flapBackShadowLayer.opacity = 0.0
            }
        } else {
            firstShadowLayer.opacity = 0.0
            secondShadowLayer.opacity = 0.0
            flapFrontShadowLayer.opacity = 0.0
            flapBackShadowLayer.opacity = 0.0
        }
        
        CATransaction.commit()
    }
    
    func reset() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        firstStaticLayer.contents = nil
        secondStaticLayer.contents = nil
        flapFrontLayer.contents = nil
        flapBackLayer.contents = nil
        flapContainerLayer.transform = CATransform3DIdentity
        firstShadowLayer.opacity = 0
        secondShadowLayer.opacity = 0
        flapFrontShadowLayer.opacity = 0
        flapBackShadowLayer.opacity = 0
        currentMode = .disabled
        
        CATransaction.commit()
    }
}

// MARK: - 6. Public Plug-and-Play Collection View Subclass
open class AKPageFlipperCollectionView: UICollectionView, UIGestureRecognizerDelegate {
    
    public private(set) var currentPage: Int = 0
    public private(set) var activeFoldMode: AKFoldMode = .disabled
    public private(set) var currentProgress: CGFloat = 0.0
    public weak var flippingDelegate: AKPageFlippingDelegate?
    
    /// Set the flip orientation: .vertical (top/bottom fold) or .horizontal (left/right book fold)
    public var flipOrientation: AKFlipOrientation = .vertical
    
    /// Enable/Disable depth shadow overlays during 3D fold
    public var isShadowEnabled: Bool {
        get { return foldOverlayView.isShadowEnabled }
        set { foldOverlayView.isShadowEnabled = newValue }
    }
    
    private let foldOverlayView = AKFoldOverlayView()
    private var isDirectionLocked: Bool = false
    
    private var displayLink: CADisplayLink?
    private var animStartProgress: CGFloat = 0.0
    private var animTargetProgress: CGFloat = 0.0
    private var animStartTime: CFTimeInterval = 0
    private var animDuration: CFTimeInterval = 0.3
    private var animCompletionPage: Int = 0
    
    open override var isScrollEnabled: Bool {
        get { return false }
        set { super.isScrollEnabled = false }
    }
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: AKPageFlippingLayout())
        setupDefaults()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.collectionViewLayout = AKPageFlippingLayout()
        setupDefaults()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        if !(self.collectionViewLayout is AKPageFlippingLayout) {
            self.setCollectionViewLayout(AKPageFlippingLayout(), animated: false)
        }
        setupDefaults()
    }
    
    private func setupDefaults() {
        self.contentInsetAdjustmentBehavior = .never
        super.isScrollEnabled = false
        self.isPagingEnabled = false
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        
        if self.backgroundColor == nil || self.backgroundColor == .clear {
            self.backgroundColor = .systemBackground
        }
        
        self.panGestureRecognizer.isEnabled = false
        
        if !(self.collectionViewLayout is AKPageFlippingLayout) {
            self.collectionViewLayout = AKPageFlippingLayout()
        }
        
        foldOverlayView.isHidden = true
        if foldOverlayView.superview == nil {
            self.addSubview(foldOverlayView)
        }
        
        let customPan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        customPan.delegate = self
        self.addGestureRecognizer(customPan)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.contentOffset = .zero
        foldOverlayView.frame = self.bounds
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, pan.view == self else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
        let velocity = pan.velocity(in: self)
        if flipOrientation == .vertical {
            return abs(velocity.y) > abs(velocity.x)
        } else {
            return abs(velocity.x) > abs(velocity.y)
        }
    }
    
    private func renderImageAspectFill(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            let imageAspect = image.size.width / image.size.height
            let targetAspect = targetSize.width / targetSize.height
            
            var drawRect: CGRect = .zero
            if imageAspect > targetAspect {
                let drawWidth = targetSize.height * imageAspect
                drawRect = CGRect(x: (targetSize.width - drawWidth) / 2.0, y: 0, width: drawWidth, height: targetSize.height)
            } else {
                let drawHeight = targetSize.width / imageAspect
                drawRect = CGRect(x: 0, y: (targetSize.height - drawHeight) / 2.0, width: targetSize.width, height: drawHeight)
            }
            image.draw(in: drawRect)
        }
    }
    
    private func captureSnapshotForCell(at index: Int) -> UIImage? {
        guard index >= 0 && index < numberOfItems(inSection: 0) else { return nil }
        let indexPath = IndexPath(item: index, section: 0)
        let pageBounds = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        guard pageBounds.width > 0 && pageBounds.height > 0 else { return nil }
        
        if let image = flippingDelegate?.pageFlippingCollectionView?(self, imageForPageAt: index) {
            return renderImageAspectFill(image, targetSize: pageBounds.size)
        }
        
        guard let cell = cellForItem(at: indexPath) else {
            return nil
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(bounds: pageBounds, format: format)
        return renderer.image { ctx in
            let bg = self.backgroundColor ?? .systemBackground
            bg.setFill()
            ctx.cgContext.fill(pageBounds)
            
            cell.layer.render(in: ctx.cgContext)
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let pageDimension = (flipOrientation == .vertical) ? max(1, self.bounds.height) : max(1, self.bounds.width)
        let translation = (flipOrientation == .vertical) ? gesture.translation(in: self).y : gesture.translation(in: self).x
        let velocity = (flipOrientation == .vertical) ? gesture.velocity(in: self).y : gesture.velocity(in: self).x
        let itemCount = numberOfItems(inSection: 0)
        
        switch gesture.state {
        case .began:
            displayLink?.invalidate()
            displayLink = nil
            isDirectionLocked = false
            activeFoldMode = .disabled
            currentProgress = 0.0
            self.contentOffset = .zero
            
        case .changed:
            self.contentOffset = .zero
            
            // Calculate raw directional progress relative to active mode
            let rawProgress: CGFloat
            if activeFoldMode == .lowerHalfUp || activeFoldMode == .rightHalfLeft {
                rawProgress = -translation / pageDimension
            } else if activeFoldMode == .upperHalfDown || activeFoldMode == .leftHalfRight {
                rawProgress = translation / pageDimension
            } else {
                rawProgress = -1.0
            }
            
            // Handle mid-gesture reversal across origin
            if activeFoldMode != .disabled && rawProgress < 0.0 {
                isDirectionLocked = false
                activeFoldMode = .disabled
                foldOverlayView.reset()
                foldOverlayView.isHidden = true
            }
            
            if !isDirectionLocked && abs(translation) > 5.0 {
                let isForward = translation < 0 // Drag UP (vertical) or Drag LEFT (horizontal) -> Next Page
                let isBackward = translation > 0 // Drag DOWN (vertical) or Drag RIGHT (horizontal) -> Previous Page
                
                if isForward && currentPage < itemCount - 1 {
                    isDirectionLocked = true
                    activeFoldMode = (flipOrientation == .vertical) ? .lowerHalfUp : .rightHalfLeft
                    UIView.performWithoutAnimation {
                        collectionViewLayout.invalidateLayout()
                        layoutIfNeeded()
                    }
                    
                    let currentImg = captureSnapshotForCell(at: currentPage)
                    let targetImg = captureSnapshotForCell(at: currentPage + 1)
                    foldOverlayView.configure(currentImage: currentImg, targetImage: targetImg, mode: activeFoldMode, orientation: flipOrientation)
                    foldOverlayView.frame = self.bounds
                    self.bringSubviewToFront(foldOverlayView)
                    foldOverlayView.isHidden = false
                } else if isBackward && currentPage > 0 {
                    isDirectionLocked = true
                    activeFoldMode = (flipOrientation == .vertical) ? .upperHalfDown : .leftHalfRight
                    UIView.performWithoutAnimation {
                        collectionViewLayout.invalidateLayout()
                        layoutIfNeeded()
                    }
                    
                    let currentImg = captureSnapshotForCell(at: currentPage)
                    let targetImg = captureSnapshotForCell(at: currentPage - 1)
                    foldOverlayView.configure(currentImage: currentImg, targetImage: targetImg, mode: activeFoldMode, orientation: flipOrientation)
                    foldOverlayView.frame = self.bounds
                    self.bringSubviewToFront(foldOverlayView)
                    foldOverlayView.isHidden = false
                } else {
                    activeFoldMode = .disabled
                }
            }
            
            if activeFoldMode != .disabled {
                let validTranslation = (activeFoldMode == .lowerHalfUp || activeFoldMode == .rightHalfLeft) ? -translation : translation
                currentProgress = min(1.0, max(0.0, validTranslation / pageDimension))
                foldOverlayView.updateProgress(currentProgress, mode: activeFoldMode)
            }
            
        case .ended, .cancelled, .failed:
            if activeFoldMode != .disabled {
                let shouldFinish: Bool
                let targetPage: Int
                
                if activeFoldMode == .lowerHalfUp || activeFoldMode == .rightHalfLeft {
                    shouldFinish = (currentProgress > 0.35) || (velocity < -200)
                    targetPage = shouldFinish ? (currentPage + 1) : currentPage
                } else {
                    shouldFinish = (currentProgress > 0.35) || (velocity > 200)
                    targetPage = shouldFinish ? (currentPage - 1) : currentPage
                }
                
                let destProgress: CGFloat = shouldFinish ? 1.0 : 0.0
                animateFoldProgress(to: destProgress, completionPage: targetPage)
            }
            isDirectionLocked = false
            
        default:
            break
        }
    }
    
    private func animateFoldProgress(to targetProgress: CGFloat, completionPage: Int) {
        displayLink?.invalidate()
        animStartProgress = currentProgress
        animTargetProgress = targetProgress
        animStartTime = CACurrentMediaTime()
        animCompletionPage = completionPage
        
        let distance = abs(targetProgress - currentProgress)
        animDuration = max(0.12, TimeInterval(distance * 0.3))
        
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLinkUpdate))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func handleDisplayLinkUpdate() {
        let elapsed = CACurrentMediaTime() - animStartTime
        let t = min(1.0, CGFloat(elapsed / animDuration))
        let easeOut = 1.0 - pow(1.0 - t, 3)
        
        currentProgress = animStartProgress + (animTargetProgress - animStartProgress) * easeOut
        foldOverlayView.updateProgress(currentProgress, mode: activeFoldMode)
        
        if t >= 1.0 {
            displayLink?.invalidate()
            displayLink = nil
            
            currentPage = animCompletionPage
            contentOffset = .zero
            activeFoldMode = .disabled
            currentProgress = 0.0
            
            UIView.performWithoutAnimation {
                collectionViewLayout.invalidateLayout()
                layoutIfNeeded()
            }
            
            foldOverlayView.reset()
            foldOverlayView.isHidden = true
        }
    }
}
