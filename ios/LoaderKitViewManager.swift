import NVActivityIndicatorView

@objc(LoaderKitViewManager)
class LoaderKitViewManager: RCTViewManager {
    
    override func view() -> (LoaderKitView) {
        return LoaderKitView()
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

class LoaderKitView : UIView {
    let animations = [
        "BallPulse": NVActivityIndicatorType.ballPulse,
        "BallGridPulse": NVActivityIndicatorType.ballGridPulse,
        "BallClipRotate": NVActivityIndicatorType.ballClipRotate,
        "SquareSpin": NVActivityIndicatorType.squareSpin,
        "BallClipRotatePulse": NVActivityIndicatorType.ballClipRotatePulse,
        "BallClipRotateMultiple": NVActivityIndicatorType.ballClipRotateMultiple,
        "BallPulseRise": NVActivityIndicatorType.ballPulseRise,
        "BallRotate": NVActivityIndicatorType.ballRotate,
        "CubeTransition": NVActivityIndicatorType.cubeTransition,
        "BallZigZag": NVActivityIndicatorType.ballZigZag,
        "BallZigZagDeflect": NVActivityIndicatorType.ballZigZagDeflect,
        "BallTrianglePath": NVActivityIndicatorType.ballTrianglePath,
        "BallScale": NVActivityIndicatorType.ballScale,
        "LineScale": NVActivityIndicatorType.lineScale,
        "LineScaleParty": NVActivityIndicatorType.lineScaleParty,
        "BallScaleMultiple": NVActivityIndicatorType.ballScaleMultiple,
        "BallPulseSync": NVActivityIndicatorType.ballPulseSync,
        "BallBeat": NVActivityIndicatorType.ballBeat,
        "BallDoubleBounce": NVActivityIndicatorType.ballDoubleBounce,
        "LineScalePulseOut": NVActivityIndicatorType.lineScalePulseOut,
        "LineScalePulseOutRapid": NVActivityIndicatorType.lineScalePulseOutRapid,
        "BallScaleRipple": NVActivityIndicatorType.ballScaleRipple,
        "BallScaleRippleMultiple": NVActivityIndicatorType.ballScaleRippleMultiple,
        "BallSpinFadeLoader": NVActivityIndicatorType.ballSpinFadeLoader,
        "LineSpinFadeLoader": NVActivityIndicatorType.lineSpinFadeLoader,
        "TriangleSkewSpin": NVActivityIndicatorType.triangleSkewSpin,
        "Pacman": NVActivityIndicatorType.pacman,
        "BallGridBeat": NVActivityIndicatorType.ballGridBeat,
        "SemiCircleSpin": NVActivityIndicatorType.semiCircleSpin,
        "BallRotateChase": NVActivityIndicatorType.ballRotateChase,
        "Orbit": NVActivityIndicatorType.orbit,
        "AudioEqualizer": NVActivityIndicatorType.audioEqualizer,
        "CircleStrokeSpin": NVActivityIndicatorType.circleStrokeSpin,
    ]
    
    private var loader = NVActivityIndicatorView(frame: .zero, type: NVActivityIndicatorView.DEFAULT_TYPE)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(loader)
        
        loader.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loader.leadingAnchor.constraint(equalTo: leadingAnchor),
            loader.trailingAnchor.constraint(equalTo: trailingAnchor),
            loader.topAnchor.constraint(equalTo: topAnchor),
            loader.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        loader.startAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    var name: NSString? {
        didSet {
            loader.stopAnimating()
            loader.type = (name != nil ? animations[name! as String] : animations["BallPulse"])!
            loader.startAnimating()
        }
    }
    
    @objc
    var color: NSNumber? {
        didSet {
            loader.stopAnimating()
            loader.color = color != nil ? RCTConvert.uiColor(color) : .white
            loader.startAnimating()
        }
    }
}
