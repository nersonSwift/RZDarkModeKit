//
//  StaticPosesView.swift
//  Yoga
//
//  Created by Александр Сенин on 07.04.2020.
//  Copyright © 2020 Александр Сенин. All rights reserved.
//

import RelizKit
import Lottie
import APNGKit

class StaticPosesView: UIView, UIGestureRecognizerDelegate, DragingViewProtocol{
    
    var startDraging: ((UIView?) -> ())? {didSet{check()}}
    var draging:      ((UIView?, UIPanGestureRecognizer) -> ())? {didSet{check()}}
    var droping:      ((UIView?) -> ())? {didSet{check()}}
    var dubleTup: ((StaticPosesView) -> ())?
    var rowValue: String = ""
    
    var staticView: Bool = false
    
    private func check(){
        if startDraging != nil && draging != nil && droping != nil{
            setDragingMod()
        }
    }
    
    func setDragingMod(){
        if !staticView{
            addRecognizer2()
        }
        createTimeLabel()
        self.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
    }
    
    
    var staticPoseModel: StaticPoseModel!
    var imageView: UIImageView!
    var startFlag: Bool = false
    var aView: APNGImageView?
    
    var tagView: TagView!
    var time: Int = 0
    var timeMode: Int = 0
    static weak var plaseHoldeerImage: APNGImage?
    
    var timeLabelIsHiden: Bool = true{
        didSet{
            UIView.animate(withDuration: 0.2, animations: {
                self.tagView?.alpha = self.timeLabelIsHiden ? 1 : 0
            })
        }
    }
    
    init(width: CGFloat, staticPoseModel: StaticPoseModel, image: UIImage? = nil,
         constructorScreenPresenter: ConstructorScreenPresenterDelegateProtocol?,
         addRecognizerFlag: Bool = true,
         staticView: Bool = false) {
        super.init(frame: CGRect())
        self.frame.size.width = width
        self.frame.size.height = width
        self.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3025203339)
        self.layer.cornerRadius = width / 10
        self.staticView = staticView
        
        self.constructorScreenPresenter = constructorScreenPresenter
        self.staticPoseModel = staticPoseModel
        rowValue = staticPoseModel.id
        createImageView(image)
        
        if addRecognizerFlag && !staticView{
            addRecognizer1()
            addRecognizer()
        }
    }
    
    
    func createTimeLabel(){
        let alpha = tagView?.alpha ?? 1
        tagView?.removeFromSuperview()
        let time = getTime()
        tagView = TagView(text: time, colors: [ColorScheme.aPelW.color.withAlphaComponent(0.3),#colorLiteral(red: 0.6549019608, green: 0.4352941176, blue: 0.9607843137, alpha: 1)], border: false)
        tagView.alpha = alpha
        tagView.state = true
        tagView.center.x = self.frame.width / 2
        tagView.frame.origin.y = -tagView.frame.height * 1.2
        
        
        self.addSubview(tagView)
    }
    
    
    private func createMeditationObj(){
        
        aView = APNGImageView()
        if let image = Self.plaseHoldeerImage{
            aView?.image = image
        }else{
            aView?.image = APNGImage(named: "plaseHolderPoses")
            Self.plaseHoldeerImage = aView?.image
        }
        if !(self.superview is PosesPanel){
            aView?.startAnimating()
        }
        aView?.frame = self.bounds
        addSubview(aView!)
        
    }
    
    private func getTime() -> String{
        time = Int(Float(staticPoseModel.time) ?? 0)
        let sec = time % 60
        let min = time / 60
        
        let text = (min != 0 ? "\(min)" + "m".localized : "") + " " + (sec != 0 ? "\(sec)" + "s".localized : "")
        return text
    }
    
    private func createImageView(_ image: UIImage? = nil){
        imageView = UIImageView(frame: self.bounds)
        imageView.alpha = 0
        self.addSubview(imageView)
        
        if let unImage = image {
            imageView.image = unImage
            imageView.alpha = 1
            return
        }
        createMeditationObj()
        self.getImage(){[weak self] image in
            guard let unSelf = self else{return}
            DispatchQueue.main.async {
                unSelf.imageView.image = image
                UIView.animate(withDuration: 0.3, animations:  {
                    unSelf.imageView.alpha = 1
                    unSelf.aView?.alpha = 0
                }){_ in
                    unSelf.aView?.removeFromSuperview()
                    unSelf.aView = nil
                }
            }
        }
        
    }
    
    private func getImage(end: @escaping (UIImage?)->()){
        let url = staticPoseModel.imagPNGURL
        let pathTag = ScreensInstallerOld.screensInstaller.profileData.gender  ==  0 ? "F" : "M"
        let id = staticPoseModel.id
        if let image = ImagesCloud.get(id){
            end(image)
            return
        }
        
        let dataImage = try? Data(contentsOf: url)
        let image = UIImage(data: dataImage ?? Data())
            
        if image == nil{
            DownloadSupport.loadImage(gender: pathTag, id: self.staticPoseModel.id){
                let dataImage = try? Data(contentsOf: url)
                let image = UIImage(data: dataImage ?? Data())
                image?.setInCloud(id)
                end(image)
            }
        }else{
            image?.setInCloud(id)
            end(image)
        }
    }
    
    private func addRecognizer1() {
        let swipeRightRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        self.addGestureRecognizer(swipeRightRecognizer)
    }
    
    private func addRecognizer2() {
        let swipeRightRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tap))
        swipeRightRecognizer.delegate = self
        self.addGestureRecognizer(swipeRightRecognizer)
    }
    
    private func addRecognizer() {
        let swipeRightRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.recognizerAction))
        swipeRightRecognizer.delegate = self
        self.addGestureRecognizer(swipeRightRecognizer)
    }
    
    var tapDouble: Bool = false
    weak var constructorScreenPresenter: ConstructorScreenPresenterDelegateProtocol?
    @objc private func tap(recognizer: UITapGestureRecognizer){
        if self.tapDouble{
            dubleTup?(self)
            tapDouble = false
            return
        }
        self.tapDouble = true
        _ = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { _ in
            if !self.tapDouble {
                return
            }
            self.tapDouble = false
            let popUp = StateInPosePopUp(image: self.imageView.image ?? UIImage(), name: self.staticPoseModel.localName,
                                         time: Int(Float(self.staticPoseModel?.time ?? "0") ?? 0))
            popUp.saveCloser = {[weak self] time in
                guard let unSelf = self else {return}
                if time == 0 {return}
                unSelf.timeMode = time
                if let constructorScreenPresenter = unSelf.constructorScreenPresenter as? ConstructorScreenPresenterIPhoneDelegate{
                    constructorScreenPresenter.screen.addAction(action: .setTime(unSelf, Int(Float(unSelf.staticPoseModel.time) ?? 0)))
                }
                unSelf.staticPoseModel.time = "\(time)"
                unSelf.createTimeLabel()
                if let loop = unSelf.superview as? LoopStaticPoses{
                    loop.createTimeLabel()
                }
                if let supeeView = self?.superview?.superview as? AllPosesPanel{
                    supeeView.constructorScreenPresenter?.changeTimeLabel(time: supeeView.getTime())
                }else{
                    unSelf.constructorScreenPresenter?.changeTimeLabel(time: unSelf.constructorScreenPresenter?.getTime() ?? "")
                }
            }
    
            let screensInstaller = ScreensInstallerOld.screensInstaller
            let yoga = ScreensInstallerOld.screensInstaller.rootViewController as! YogaView
            screensInstaller.installPopUp(in: yoga.scrin, installingPopUpView: popUp)
        })
    }
    
    @objc private func tapDoubleAction(recognizer: UITapGestureRecognizer){
        
        tapDouble = true
        dubleTup?(self)
    }
    /*
    let popUp = MenuePopUp(width: ParentElements.rootSize.width * 0.65, elements: ["Переименовать","Дублировать","Редактировать","Удалить"])
    popUp.center.x = ParentElements.rootSize.width / 2
    popUp.center.y = ParentElements.rootSize.height / 2
    let screensInstaller = ScreensInstaller.screensInstaller
    let yoga = ScreensInstaller.screensInstaller.rootViewController as! YogaView
    screensInstaller.installPopUp(in: yoga.scrin, installingPopUpView: popUp)
     */
    
    func createClone() -> StaticPosesView?{
        guard let staticPoseModel = try? StaticPoseModel(json: self.staticPoseModel.convertToJson()) else {return nil}
        let staticPosesView = StaticPosesView.init(width: self.frame.width,
                                                   staticPoseModel: staticPoseModel,
                                                   image: self.imageView.image,
                                                   constructorScreenPresenter: constructorScreenPresenter)
        
        return staticPosesView
    }
    
    var clon: StaticPosesView?
    @objc private func longPress(recognizer: UILongPressGestureRecognizer){
        if let posesPanel = superview as? PosesPanel{
            if let clon = createClone(), let constructorScreenPresenter = constructorScreenPresenter, recognizer.state == .began{
                self.clon = clon
                clon.center.x = self.center.x
                clon.center.y = self.center.y - posesPanel.contentOffset.y
                constructorScreenPresenter.delegatingScreen.addSubview(clon)
                
                clon.startDraging = constructorScreenPresenter.startDrag
                clon.draging = constructorScreenPresenter.drag
                clon.droping = constructorScreenPresenter.drop
                clon.tagView.alpha = 0
            
                if let constructorScreenPresenter = constructorScreenPresenter as? ConstructorScreenPresenterIPhoneDelegate{
                    constructorScreenPresenter.screen.addAction(action: .create(clon))
                }
                
            }
            if let clon = self.clon{
                longPressAction(staticPosesView: clon, recognizer: recognizer, start: false)
            }
        }else{
            longPressAction(staticPosesView: self, recognizer: recognizer)
        }
    }
    
    private func longPressAction(staticPosesView: StaticPosesView, recognizer: UILongPressGestureRecognizer, start: Bool = true){
        switch recognizer.state {
        case .began:
            staticPosesView.startFlag = true
            if start{
                staticPosesView.startDraging?(staticPosesView)
            }
            let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
            impactFeedbackgenerator.prepare()
            impactFeedbackgenerator.impactOccurred()
        case .ended:
            staticPosesView.startFlag = false
            staticPosesView.droping?(staticPosesView)
            clon = nil
        default: break
        }
    }
    
    @objc private func recognizerAction(recognizer: UIPanGestureRecognizer){
        if let clon = self.clon{
            panRecognizerAction(staticPosesView: clon, recognizer: recognizer)
        }else{
            panRecognizerAction(staticPosesView: self, recognizer: recognizer)
        }
    }
    
    private func panRecognizerAction(staticPosesView: StaticPosesView, recognizer: UIPanGestureRecognizer){
        switch recognizer.state {
        case .changed:
            if staticPosesView.startFlag{
                staticPosesView.draging?(staticPosesView, recognizer)
            }
        default: break
        }
    }
    
    func getRow() -> String {
        var row: String = ""
        row += "T0\(time)-"
        row += staticPoseModel.id
        return row
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StaticPosesView{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
