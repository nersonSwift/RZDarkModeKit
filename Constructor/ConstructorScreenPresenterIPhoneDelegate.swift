//
//  ConstructorScreenPresenterIPhoneDelegate.swift
//  Yoga
//
//  Created by Александр Сенин on 27.03.2020.
//  Copyright © 2020 Александр Сенин. All rights reserved.
//

import UIKit
import SVGKit
import Lottie

class ConstructorScreenPresenterIPhoneDelegate: ScreenPresenterDelegate, ConstructorScreenPresenterDelegateProtocol {
    var startDrag: (UIView?) -> () {
        {[weak self] view in
            guard let unSelf = self else {return}
            guard let unView = view else {return}
            unSelf.createPanel.startDrag(view)
            unSelf.screen.addSubview(unView)
            UIView.animate(withDuration: 0.3) {
                unSelf.bucket.state = 1
            }
            
            if unSelf.loopStaticPoses != nil{
                unSelf.loopButton.setTitle("Add loop".localized, for: .normal)
                unSelf.closeLoop()
            }
        }
    }
    var drag: (UIView?, UIPanGestureRecognizer) -> () {
        {[weak self] view, recognizer in
            guard let unSelf = self else {return}
            guard let unView = view else {return}
            
            let speed = recognizer.translation(in: unSelf.screen)
            
            unView.center.x += speed.x
            unView.center.y += speed.y
            
            recognizer.setTranslation(CGPoint.zero, in: unSelf.screen)
            unSelf.createPanel.drag(unView, nil)
            
            let center = unView.center
            if !(center.x >= unSelf.createPanel.frame.minX && center.x <= unSelf.createPanel.frame.maxX &&
               center.y >= unSelf.createPanel.frame.minY && center.y <= unSelf.createPanel.frame.maxY){
                if unSelf.bucket.state != 2{
                    UIView.animate(withDuration: 0.3) {
                        unSelf.bucket.state = 2
                    }
                }
            }else{
                if unSelf.bucket.state != 1{
                    UIView.animate(withDuration: 0.3) {
                        unSelf.bucket.state = 1
                    }
                }
            }
        }
    }
    var drop: (UIView?) -> () {
        {[weak self] view in
            guard let unSelf = self else {return}
            let center = view?.center ?? CGPoint()
            if center.x >= unSelf.createPanel.frame.minX && center.x <= unSelf.createPanel.frame.maxX &&
               center.y >= unSelf.createPanel.frame.minY && center.y <= unSelf.createPanel.frame.maxY{
                unSelf.createPanel?.drop(view, nil)
            }else{
                if unSelf.screen.constructorActions.count > 0{
                    switch unSelf.screen.constructorActions.removeLast(){
                    case .startMove(let createPanelProtocol, let count, let view):
                        unSelf.screen.addAction(action: .delete(createPanelProtocol, count, view))
                    default: break
                    }
                }
                unSelf.createPanel?.changeSize(a: 1, d: 1, alpha: 1, view: view)
                unSelf.posesPanel?.drop(view)
                unSelf.changeTimeLabel(time: unSelf.getTime())
            }
            unSelf.changeTimeLabel(time: unSelf.getTime())
            UIView.animate(withDuration: 0.3) {
                unSelf.bucket.state = 0
            }
        }
    }
    
    var dubleTup: (StaticPosesView) -> () {
        {[weak self] view in
            guard let unSelf = self else {return}
            var pointerPlase: CGPoint = CGPoint(x: view.center.x + (view.superview?.frame.minX ?? 0),
                                                y: view.center.y + (view.superview?.frame.minY ?? 0))
            if let loop = view.superview as? LoopStaticPoses{
                if let createPanel = loop.superview as? CreatePanel{
                    pointerPlase.x += createPanel.frame.minX
                    pointerPlase.x -= createPanel.contentOffset.x
                    pointerPlase.y += createPanel.frame.minY
                    
                }
            }else if let createPanel = view.superview as? CreatePanel{
                pointerPlase.x -= createPanel.contentOffset.x
            }
            let tochReg = TochReg(frame: unSelf.screen.bounds)
            
            let dialogView = DialogView(closures: ["Delete".localized: {[weak self] in
                                                    self?.delStaticPosesView(staticPosesView: view, tochReg: tochReg)
                                                  }, "Duplicate".localized: {[weak self] in
                                                    self?.copyPosesView(staticPosesView: view, tochReg: tochReg)
                                                  }],
                                        pointerPlase: pointerPlase,
                                        parentWidth: unSelf.screen.frame.width)
            if let dialogView = dialogView{
                if let dialogViewSelf = unSelf.dialogView{
                    dialogViewSelf.removeFromSuperview()
                }
                unSelf.dialogView = dialogView
                tochReg.closure = {[weak self] in
                    if let dialogViewSelf = self?.dialogView{
                        dialogViewSelf.removeFromSuperview()
                    }
                }
                unSelf.screen.addSubview(tochReg)
                unSelf.screen.addSubview(dialogView)
            }
        }
    }
    
    private func delStaticPosesView(staticPosesView: StaticPosesView, tochReg: TochReg){
        if let createPanel = staticPosesView.superview as? CreatePanel{
            var count = 0
            for (countL, view) in createPanel.views.enumerated(){
                if view == staticPosesView{
                    count = countL
                }
            }
            createPanel.views.remove(at: count)
            createPanel.arreng(animation: true)
            screen.addAction(action: .delete(createPanel, count, staticPosesView))
        }
        if let loop = staticPosesView.superview as? LoopStaticPoses{
            var count = 0
            for (countL, view) in loop.views.enumerated(){
                if view == staticPosesView{
                    count = countL
                }
            }
            loop.views.remove(at: count)
            screen.addAction(action: .delete(loop, count, staticPosesView))
            loop.arreng(animation: true)
            if let createPanel = loop.superview as? CreatePanel{
                createPanel.arreng(animation: true)
            }
        }
        tochReg.removeFromSuperview()
        dialogView?.removeFromSuperview()
        staticPosesView.removeFromSuperview()
        changeTimeLabel(time: getTime())
    }
    private func copyPosesView(staticPosesView: StaticPosesView, tochReg: TochReg){
        let copy = staticPosesView.createClone()
        copy?.draging = staticPosesView.draging
        copy?.droping = staticPosesView.droping
        copy?.startDraging = staticPosesView.startDraging
        copy?.dubleTup = staticPosesView.dubleTup
        
        if let createPanel = staticPosesView.superview as? CreatePanel{
            var views: [UIView] = []
            for view in createPanel.views{
                views.append(view)
                if view == staticPosesView, let copy = copy{
                    createPanel.addSubview(copy)
                    views.append(copy)
                }
            }
            createPanel.views = views
            createPanel.arreng(animation: true)
        }
        if let loop = staticPosesView.superview as? LoopStaticPoses{
            var views: [UIView] = []
            for view in loop.views{
                views.append(view)
                if view == staticPosesView, let copy = copy{
                    copy.timeLabelIsHiden = false
                    loop.addSubview(copy)
                    views.append(copy)
                }
            }
            loop.views = views
            loop.arreng(animation: true)
            if let createPanel = loop.superview as? CreatePanel{
                createPanel.arreng(animation: true)
            }
        }
        tochReg.removeFromSuperview()
        dialogView?.removeFromSuperview()
        changeTimeLabel(time: getTime())
    }

    
    var createPanel: CreatePanel!
    var posesPanel: PosesPanel!
    var allPosesPanel: AllPosesPanel?
    var loopButton: UIButtonP!
    var labelButton: UIButtonP!
    var timeLabel: UILabel!
    var buttonX: UIButtonP!
    var saveButton: UIButtonP!
    var backActionButton: UIView!
    var fullScreenButton: UIView!
    var bucket: Bucket!
    var blurEffectView: UIView?
    var dialogView: DialogView?
    var anim: Animation?
    
    weak var loopStaticPoses: LoopStaticPoses?
    
    var screen: ConstructorScreen {delegatingScreen as! ConstructorScreen}
    
    override func create() {
        ParentElements.colorise { [weak screen] in
            screen?.backgroundColor = ColorScheme.aPldB.color
            return screen
        }
        
        createBucket()
        createXButton()
        createLabelButton()
        createButton()
        createCreatePanel()
        createTimeLabel()
        
        createBackActionButton()
        createLoopButton()
        createFullScreenButton()
        createPosesPanel()
        createTags()
    }
    
    private func createCreatePanel(){
        createPanel = CreatePanel(size: CGSize(width: screen.frame.width, height: screen.frame.width * 0.8 / 3),
                                  constructorScreenPresenterIPhoneDelegate: self)
        createPanel.frame.origin.y = screen.frame.height * 0.22
        screen.addSubview(createPanel)
    }
    
    func createAllPosesPanel(){
        allPosesPanel = AllPosesPanel(size: screen.frame.size,
                                      programmModel: screen.getProgrammModel(),
                                      constructorScreenPresenter: self,
                                      blurEffectViewHeight: timeLabel.frame.maxY)
        allPosesPanel?.alpha = 0
        screen.addSubview(allPosesPanel!)
        
        blurEffectView = UIView()
        blurEffectView?.frame = screen.bounds
        blurEffectView?.frame.size.height = timeLabel.frame.maxY
        ParentElements.colorise { [weak blurEffectView] in
            blurEffectView?.backgroundColor = ColorScheme.aPldB.color
            return blurEffectView
        }
        blurEffectView?.alpha = 0
        screen.addSubview(blurEffectView!)
        
        UIView.animate(withDuration: 0.3) {
            self.blurEffectView?.alpha = 0.9
            self.allPosesPanel?.alpha = 1
            self.fullScreenButton.center.x = self.screen.frame.width / 2
            self.fullScreenButton.frame.origin.y = self.screen.frame.height * 0.89
        }
        
        screen.bringSubviewToFront(saveButton)
        screen.bringSubviewToFront(labelButton)
        screen.bringSubviewToFront(timeLabel)
        screen.bringSubviewToFront(buttonX)
        screen.bringSubviewToFront(fullScreenButton)
    }
    
    func removeAllPosesPanel(){
        UIView.animate(withDuration: 0.3, animations:  {
            self.blurEffectView?.alpha = 0
            self.allPosesPanel?.alpha = 0
            self.fullScreenButton.center.y = self.createPanel.frame.maxY + (self.screen.frame.height * 0.45 - self.createPanel.frame.maxY) / 2
            self.fullScreenButton.center.x = self.backActionButton.frame.maxX + (self.loopButton.frame.minX - self.backActionButton.frame.maxX) / 2
        }){_ in
            self.allPosesPanel?.removeFromSuperview()
            self.allPosesPanel = nil
            self.blurEffectView?.removeFromSuperview()
            self.blurEffectView = nil
        }
    }
    
    
    func createPosesPanel(){
        let blurEffectView = UIView()
        blurEffectView.frame = screen.bounds
        blurEffectView.frame.size.height = loopButton.frame.maxY + screen.frame.width * 0.04
        ParentElements.colorise { [weak blurEffectView] in
            blurEffectView?.backgroundColor = ColorScheme.aPldB.color
            return blurEffectView
        }
        blurEffectView.alpha = 0.9
        
        screen.addSubview(blurEffectView)
        screen.sendSubviewToBack(blurEffectView)
        
        posesPanel = PosesPanel(size: CGSize(width: screen.frame.width, height: screen.frame.height),
                                staticPoses: screen.staticPoses,
                                constructorScreenPresenter: self)
        screen.addSubview(posesPanel)
        screen.sendSubviewToBack(posesPanel)
    }
    
    func addItem(staticPosesView: StaticPosesView){
        staticPosesView.startDraging = startDrag
        staticPosesView.draging = drag
        staticPosesView.droping = drop
        staticPosesView.dubleTup = dubleTup

        if let unLoop = loopStaticPoses{
            staticPosesView.timeLabelIsHiden = false
            unLoop.views.append(staticPosesView)
            unLoop.addSubview(staticPosesView)
            unLoop.arreng(animation: false)
            screen.addAction(action: .set(unLoop, unLoop.views.count - 1))
        }else{
            createPanel.views.append(staticPosesView)
            createPanel.addSubview(staticPosesView)
            screen.addAction(action: .set(createPanel, createPanel.views.count - 1))
        }
        createPanel.arreng(animation: false)
        UIView.animate(withDuration: 0.2) {
            if self.createPanel.contentSize.width > self.createPanel.frame.width{
                self.createPanel.contentOffset.x = self.createPanel.contentSize.width - self.createPanel.frame.width
            }
        }
        changeTimeLabel(time: getTime())
    }
    
    private func createTimeLabel(){
        timeLabel = ParentElements.label(text: "Total time: ".localized + "\(getTime())",
                                         font: .title5,
                                         color: ColorScheme.white.color)
        timeLabel.center.x = screen.frame.width / 2
        timeLabel.center.y = labelButton.frame.maxY + (createPanel.frame.minY - labelButton.frame.maxY) * 0.27
        screen.addSubview(timeLabel)
    }
    
    func changeTimeLabel(time: Int){
        changeTimeLabel(time: convertTime(time: time))
    }
    
    func changeTimeLabel(time: String){
        if timeLabel == nil {return}
        timeLabel.text = "Total time: ".localized + time
        timeLabel.sizeToFit()
        timeLabel.center.x = screen.frame.width / 2
    }

    func getTime() -> String{
        var time = 0
        guard let createViews = createPanel?.views else {return ""}
        for view in createViews{
            if let dragingView = view as? DragingViewProtocol{
                time += dragingView.time
            }
        }
    
        return convertTime(time: time)
    }
    
    func convertTime(time: Int) -> String {
        let sec = time % 60
        let min = time / 60
        
        let text = (min != 0 ? "\(min) " + "min".localized : "") + " " + (sec != 0 ? "\(sec) " + "sec".localized : "")
        return text
    }
    
    private func createBackActionButton(){
        var size = CGSize(width: screen.frame.width * 0.13, height: screen.frame.width * 0.11)
        backActionButton = UIView()
        backActionButton.frame.size = size
        backActionButton.layer.cornerRadius = size.height / 2
        backActionButton.backgroundColor = ColorScheme.purpleRegular.color
        screen.addSubview(backActionButton)
        
        size.width = screen.frame.width * 0.11
        let button = ParentElements.button(content: .image(UIImage(named: "BackArrow")!, 0.6),
                                           size: size,
                                           selfColor: ColorScheme.white.color,
                                           shadow: false)
        
        button.center.y = backActionButton.frame.height / 2
        button.center.x = backActionButton.frame.width / 2
        button.addClosure(event: .touchUpInside) {[weak self] in
            guard let unSelf = self else {return}
            if unSelf.loopStaticPoses != nil{
                unSelf.loopButton.setTitle("Add loop".localized, for: .normal)
                unSelf.closeLoop()
            }
            if unSelf.loopStaticPoses != nil{
                unSelf.loopButton.setTitle("Add loop".localized, for: .normal)
                unSelf.closeLoop()
            }
            unSelf.screen.useAction()
        }
        
        backActionButton.center.y = createPanel.frame.maxY + (screen.frame.height * 0.45 - createPanel.frame.maxY) / 2
        backActionButton.frame.origin.x = screen.frame.width * 0.12
        backActionButton.addSubview(button)
    }
    
    private func createLoopButton(){
        loopButton = ParentElements.button(content: .text("Add loop".localized, ColorScheme.white.color),
                                           buttonType: .small,
                                           selfColor: ColorScheme.purpleRegular.color,
                                           shadow: false)
        
        loopButton.frame.size.width = screen.frame.width * 0.45
        loopButton.frame.origin.x = (screen.frame.width - screen.frame.width * 0.12) - loopButton.frame.width
        loopButton.center.y = createPanel.frame.maxY + (screen.frame.height * 0.45 - createPanel.frame.maxY) / 2
        loopButton.addClosure(event: .touchUpInside) {[weak self] in
            guard let unSelf = self else {return}
            if unSelf.loopStaticPoses == nil{
                unSelf.loopButton.setTitle("Close loop".localized, for: .normal)
                unSelf.createLoop()
            }else{
                unSelf.loopButton.setTitle("Add loop".localized, for: .normal)
                unSelf.closeLoop()
            }
        }
        screen.addSubview(loopButton)
    }
    
    private func createFullScreenButton(){
        var size = CGSize(width: screen.frame.width * 0.13, height: screen.frame.width * 0.11)
        fullScreenButton = UIView()
        fullScreenButton.frame.size = size
        fullScreenButton.layer.cornerRadius = size.height / 2
        fullScreenButton.backgroundColor = ColorScheme.purpleRegular.color
        screen.addSubview(fullScreenButton)
        
        size.width = screen.frame.width * 0.11
        
        let button = UIButtonP()
        button.frame.size = size
        button.backgroundColor = ColorScheme.white.color
                
        let menuButton = UIImageView(frame: button.bounds)
        menuButton.frame.size.width *= 0.6
        menuButton.frame.size.height *= 0.6
        menuButton.center.x = button.frame.width / 2
        menuButton.center.y = button.frame.height / 2
        menuButton.image = UIImage(named: "OpenArrows")!
            
        button.mask = menuButton
            
        button.center.y = fullScreenButton.frame.height / 2
        button.center.x = fullScreenButton.frame.width / 2
        button.addClosure(event: .touchUpInside) {[weak self, weak menuButton] in
            guard let unSelf = self else {return}
            if unSelf.allPosesPanel != nil{
                menuButton?.image = UIImage(named: "OpenArrows")!
                unSelf.screen.removeAllPosesPanelButtonAction()
            }else{
                menuButton?.image = UIImage(named: "CloseArrows")!
                unSelf.screen.allPosesPanelButtonAction()
            }
        }

        fullScreenButton.center.y = createPanel.frame.maxY + (screen.frame.height * 0.45 - createPanel.frame.maxY) / 2
        fullScreenButton.center.x = backActionButton.frame.maxX + (loopButton.frame.minX - backActionButton.frame.maxX) / 2
        fullScreenButton.addSubview(button)
    }
    
    private func createTags(){
        let (tagViews, _) = createTagsViews()
        let spase = screen.frame.width * 0.02
        var minX = screen.frame.width * 0.05
        let minY = loopButton.frame.maxY + screen.frame.width * 0.075
        
        let scroll = UIScrollView()
        scroll.frame.size.width = screen.frame.width
        scroll.frame.size.height = tagViews.first?.frame.height ?? 0
        scroll.frame.origin.y = minY
        scroll.showsHorizontalScrollIndicator = false
        scroll.layer.masksToBounds = false
        screen.addSubview(scroll)
        
        for tagView in tagViews{
            tagView.frame.origin.x = minX
            scroll.addSubview(tagView)
            minX = tagView.frame.maxX + spase
        }
        scroll.contentSize.width = minX + screen.frame.width * 0.03
    }
    
    var tagViews: [TagView] = []
    private func createTagsViews() -> ([TagView], CGFloat){
        tagViews = []
        var width: CGFloat = 0
        
        let tags = StaticPoseTag.getAllTags()
        for (count, tag) in tags.enumerated(){
            let tagView = TagView(text: tag.getLocaleName(),
                                  colors: [ColorScheme.purpleRegular.color, ColorScheme.white.color],
                                  border: false,
                                  shadow: true)
            if count == 0{
                tagView.state = true
            }else{
                tagView.state = false
            }
            width += tagView.frame.width
            createButtonForTags(tagView: tagView, tag: tag)
            tagViews.append(tagView)
        }
        return (tagViews, width)
    }
    
    private func createButtonForTags(tagView: TagView, tag: StaticPoseTag){
        let button = UIButtonP(frame: tagView.bounds)
        button.addClosure(event: .touchUpInside) {[weak tagView, weak self] in
            guard let unTagView = tagView else {return}
            guard let unSelf = self else {return}
            for tagView in unSelf.tagViews{
                tagView.state = tagView == unTagView
            }
            unSelf.posesPanel.setTag(tag: tag)
        }
        tagView.addSubview(button)
    }
    
    private func createLoop(){
        let loop = LoopStaticPoses(width: screen.frame.width * 0.8 / 3, constructorScreenPresenterIPhoneDelegate: self)
        loop.startDraging = startDrag
        loop.draging = drag
        loop.droping = drop
        createPanel.views.append(loop)
        createPanel.addSubview(loop)
        createPanel.arreng(animation: false)
        screen.addAction(action: .set(createPanel, createPanel.views.count - 1))
        loopStaticPoses = loop
        UIView.animate(withDuration: 0.2) {
            if self.createPanel.contentSize.width > self.createPanel.frame.width{
                self.createPanel.contentOffset.x = self.createPanel.contentSize.width - self.createPanel.frame.width
            }
        }
    }
    
    private func createLabelButton(){
        labelButton = ParentElements.button(content: .text(screen.programmModel.localName, #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), .title3),
                                            selfColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.2048640839),
                                            shadow: false)
        labelButton.sizeToFit()
        labelButton.frame.size.width += labelButton.frame.height * 0.4
        labelButton.center.x = screen.frame.width / 2
        labelButton.center.y = buttonX.center.y
        labelButton.layer.cornerRadius = labelButton.frame.height / 5
        labelButton.addClosure(event: .touchUpInside) {[weak self] in
            guard let unSelf = self else {return}
            unSelf.screen.nameButtonAction()
        }
        screen.addSubview(labelButton)
    }
    
    private func createXButton(){
        buttonX = ParentElements.button(content: .image(UIImage(named: "arrowLeft")!),
                                        buttonType: .backButton,
                                        selfColor: ColorScheme.white.color,
                                        shadow: false)
        buttonX.frame.origin.x = screen.frame.width * 0.05
        buttonX.frame.origin.y = screen.frame.height * 0.07
        buttonX.addClosure(event: .touchUpInside) {[weak self] in
            guard let unSelf = self else {return}
            EventManager.prepare(.amp())
                .name("feedback field")
                .value(["tap_on":"close"])
                .send()
            unSelf.screen.backButtonAction()
        }
        screen.addSubview(buttonX)
    }
    
    private func createButton(){
        saveButton = ParentElements.button(content: .text("Done".localized, ColorScheme.white.color, .title3),
                                           selfColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0),
                                           shadow: false)
        saveButton.sizeToFit()
        saveButton.frame.size.height = screen.frame.width * 0.1
        
        saveButton.center.y = buttonX.center.y
        saveButton.frame.origin.x = screen.frame.width * 0.95 - saveButton.frame.width

        
        saveButton.addClosure(event: .touchUpInside) {[weak self] in
            guard let unSelf = self else {return}
            unSelf.screen.saveButtonAction()
        }
        screen.addSubview(saveButton)
    }
    
    
    
    private func createBucket(){
        bucket = Bucket(size: CGSize(width: screen.frame.width * 0.15, height: screen.frame.width * 0.15))
        bucket.center.x = screen.frame.width / 2
        bucket.frame.origin.y = screen.frame.height * 0.89
        screen.addSubview(bucket)
    }
    
    private func closeLoop(){
        loopStaticPoses = nil
    }
}

class Bucket: UIView{
    var circle: UIView!
    var foundation: UIView!
    var imageView: UIView!
    
    var state: Int = 0{
        didSet{
            switch state{
            case 0:
                self.alpha = 0
                circle.frame.size.width = self.frame.width
                circle.frame.size.height = self.frame.height
                circle.layer.cornerRadius = circle.frame.height / 2
                circle.center.x = self.frame.width / 2
                circle.center.y = self.frame.height / 2
            case 1:
                self.alpha = 1
                circle.frame.size.width = self.frame.width
                circle.frame.size.height = self.frame.height
                circle.layer.cornerRadius = circle.frame.height / 2
                circle.center.x = self.frame.width / 2
                circle.center.y = self.frame.height / 2
            case 2:
                self.alpha = 1
                circle.frame.size.width = self.frame.width * 1.7
                circle.frame.size.height = self.frame.height * 1.7
                circle.layer.cornerRadius = circle.frame.height / 2
                circle.center.x = self.frame.width / 2
                circle.center.y = self.frame.height / 2
            default:break
            }
        }
    }
    
    init(size: CGSize) {
        super.init(frame: CGRect())
        self.frame.size = size
        self.alpha = 0
        
        createCircle()
        createFoundation()
        createImageView()
    }
    func createCircle() {
        circle = UIView(frame: self.bounds)
        circle.layer.cornerRadius = circle.frame.height / 2
        circle.backgroundColor = ColorScheme.white.color.withAlphaComponent(0.3)
        self.addSubview(circle)
    }
    func createFoundation() {
        foundation = UIView(frame: self.bounds)
        foundation.layer.cornerRadius = foundation.frame.height / 2
        foundation.backgroundColor = ColorScheme.purpleRegular.color
        self.addSubview(foundation)
    }
    func createImageView() {
        imageView = UIView(frame: self.bounds)
        imageView.backgroundColor = ColorScheme.white.color
        
        let mask = UIImageView(frame: self.bounds)
        mask.frame.size.width *= 0.55
        mask.frame.size.height *= 0.55
        mask.center.x = imageView.frame.width / 2
        mask.center.y = imageView.frame.height / 2
        mask.image = UIImage(named: "bucket")
        imageView.mask = mask
        self.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

enum StaticPoseTag: String{
    case standing = "tg1"
    case balance = "tg2"
    case lyingDown  = "tg3"
    case sitting = "tg4"
    case all = "tg0"
    
    func getLocaleName() -> String {
        switch self {
            case .standing: return "Standing".localized
            case .balance: return "Balance".localized
            case .lyingDown: return "Lying Down".localized
            case .sitting: return "Sitting".localized
            case .all: return "All".localized
        }
    }
    
    static func getAllTags() -> [StaticPoseTag]{
        return [.all, .standing, .balance, .lyingDown, .sitting]
    }
}


class TochReg: UIView{
    var closure: (()->())?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        closure?()
        self.removeFromSuperview()
    }
}
