//
//  LoopStaticPoses.swift
//  Yoga
//
//  Created by Александр Сенин on 07.04.2020.
//  Copyright © 2020 Александр Сенин. All rights reserved.
//

import RelizKit

class LoopStaticPoses: UIView, CreatePanelProtocol, DragingViewProtocol{
    
    var startDraging: ((UIView?) -> ())? {didSet{check()}}
    var draging:      ((UIView?, UIPanGestureRecognizer) -> ())? {didSet{check()}}
    var droping:      ((UIView?) -> ())? {didSet{check()}}
    
    private func check(){
        if startDraging != nil && draging != nil && droping != nil{
            addRecognizer2()
            addRecognizer1()
            addRecognizer()
        }
    }
    
    var tagView: TagView!
    var time: Int = 0
    var timeLabelIsHiden: Bool = true
    
    var count: Int = 2{
        didSet{
            countLabel.text = "\(count)"
            countLabel.sizeToFit()
            countLabel.center.x = countView.frame.width / 2
            countLabel.center.y = countView.frame.height / 2
            createTimeLabel()
            constructorScreenPresenter?.changeTimeLabel(time: constructorScreenPresenter?.getTime() ?? "")
        }
    }
    var countView: UIView!
    var countLabel: UILabel!
    var startFlag: Bool = false
    var spaseItem: SpaseItem?
    
    var startDrag: (UIView?) -> () {
        {[weak self] view in
            guard let unSelf = self else{return}
            view?.frame.origin.y += unSelf.frame.minY
            view?.frame.origin.x += unSelf.frame.minX
            unSelf.setSpaseItem(view: view)
            
            unSelf.arreng(animation: true)
        }
    }
    var drag: (UIView?, CGFloat?) -> (){
        {[weak self] view, mod in
            guard let unSelf = self else{return}
            guard let unView = view else {return}
            
            if unSelf.detectPositeon(view: unView, mod: mod, parentMod: true){
                unSelf.createSpaseItem(view: view)
            }else{
                unSelf.removeSpaseItem()
                unSelf.arreng(animation: true)
                return
            }
            unSelf.setViewPlays(view: view, playsMod: (mod ?? 0) - unSelf.frame.minX)
        }
    }
    var drop: (UIView?, CGFloat?) -> () {
        {[weak self] view, mod in
            guard let unSelf = self else{return}
            unSelf.delSpaseItem(view: view, playsMod: -unSelf.frame.minX + (mod ?? 0), parentMod: true)
            unSelf.arreng(animation: true)
        }
    }
    
    var views: [UIView] = []{
        didSet{
            createTimeLabel()
        }
    }
    
    func arreng(animation: Bool){
        if animation{
            UIView.animate(withDuration: 0.2) {
                self.arreng()
            }
        }else{
            arreng()
        }
    }
    
    private func arreng() {
        var minX: CGFloat = countView.frame.width
        for view in self.views{
            view.frame.origin.x = minX
            view.center.y = self.frame.height / 2
            minX = view.frame.maxX + self.frame.height * 0.02
        }
        if minX >= self.frame.size.height + countView.frame.width{
            self.frame.size.width = minX - self.frame.height * 0.02
        }else{
            self.frame.size.width = self.frame.height + countView.frame.width
        }
        tagView?.center.x = self.frame.width / 2
    }
    weak var constructorScreenPresenter: ConstructorScreenPresenterIPhoneDelegate?
    init(width: CGFloat, constructorScreenPresenterIPhoneDelegate: ConstructorScreenPresenterIPhoneDelegate?) {
        super.init(frame: CGRect())
        self.constructorScreenPresenter = constructorScreenPresenterIPhoneDelegate
        self.frame.size.width = width
        self.frame.size.height = width
        ParentElements.colorise {[weak self]  in
            self?.backgroundColor = ColorScheme.aPelW.color.withAlphaComponent(0.3)
            return self
        }
        createCountView()
    }
    
    private func createCountView(){
        countLabel = ParentElements.label(text: "\(count)", font: .creatorDel(.regular, 23), color: #colorLiteral(red: 0.6549019608, green: 0.4352941176, blue: 0.9607843137, alpha: 1))
        
        countView = UIView()
        countView.frame.size.width = countLabel.frame.size.height * 1.2
        countView.frame.size.height = self.frame.height
        countView.layer.cornerRadius = countView.frame.width / 2
        countView.center.y = self.frame.height / 2
        countView.backgroundColor = ColorScheme.white.color
        
        self.addSubview(countView)
        
        countLabel.center.x = countView.frame.width / 2
        countLabel.center.y = countView.frame.height / 2
        
        self.layer.cornerRadius = countView.frame.width / 2
        countView.addSubview(countLabel)
    }
    
    func createTimeLabel(){
        let text = getTime()
        if tagView?.label.text == text {return}
        tagView?.removeFromSuperview()
        tagView = nil
        if text == "" {return}
        tagView = TagView(text: text, colors: [ColorScheme.aPelW.color.withAlphaComponent(0.3),#colorLiteral(red: 0.6549019608, green: 0.4352941176, blue: 0.9607843137, alpha: 1)], border: false)
        tagView.state = true
        tagView.center.x = self.frame.width / 2
        tagView.frame.origin.y = -tagView.frame.height * 1.2
        
        self.addSubview(tagView)
    }
    
    private func getTime() -> String{
        time = 0
        for view in views{
            var view = view
            if let spase = view as? SpaseItem{
                view = spase.mirrorView ?? spase
            }
            if let staticPosesView = view as? StaticPosesView{
                time += Int(Float(staticPosesView.staticPoseModel.time) ?? 0)
            }
        }
        time *= count
        let sec = time % 60
        let min = time / 60
        if sec == 0 && min == 0{
            return ""
        }
        
        let text = (min != 0 ? "\(min)" + "m".localized : "") + " " + (sec != 0 ? "\(sec)" + "s".localized : "")
        return text
    }
    
    func getRow() -> String {
        var row: String = ""
        for view in views{
            if let dragingView = view as? DragingViewProtocol{
                if row != ""{
                    row += ","
                }
                row += dragingView.getRow()
            }
        }
        if row == "" {return ""}
        row = "\(count)," + row
        return row
    }
    
    private func addRecognizer1() {
        let swipeRightRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        countView.addGestureRecognizer(swipeRightRecognizer)
    }
    
    private func addRecognizer() {
        let swipeRightRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.recognizerAction))
        swipeRightRecognizer.delegate = self
        countView.addGestureRecognizer(swipeRightRecognizer)
    }
    
    private func addRecognizer2() {
        let swipeRightRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tap))
        countView.addGestureRecognizer(swipeRightRecognizer)
    }
    
    
    @objc private func tap(recognizer: UITapGestureRecognizer){
        let popUp = RepeatPopUp(counter: count)
        popUp.saveCloser = {[weak self] numbur in
            guard let unSelf = self else {return}
            unSelf.constructorScreenPresenter?.screen.addAction(action: .setCount(unSelf, unSelf.count))
            unSelf.count = numbur
        }
        let screensInstaller = ScreensInstallerOld.screensInstaller
        let yoga = ScreensInstallerOld.screensInstaller.rootViewController as! YogaView
        screensInstaller.installPopUp(in: yoga.scrin, installingPopUpView: popUp)
    }
    
    @objc private func longPress(recognizer: UILongPressGestureRecognizer){
        switch recognizer.state {
        case .began:
                startFlag = true
                self.layer.masksToBounds = true
                UIView.animate(withDuration: 0.2) {
                    self.frame.size.width = self.countView.frame.width
                }
                startDraging?(self)
                let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
                impactFeedbackgenerator.prepare()
                impactFeedbackgenerator.impactOccurred()
        case .ended:
                startFlag = false
                droping?(self)
                UIView.animate(withDuration: 0.2, animations:  {
                    self.arreng()
                }){_ in
                    self.layer.masksToBounds = false
                }
                (self.superview as? CreatePanel)?.arreng(animation: true)
        default: break
        }
    }
    
    @objc private func recognizerAction(recognizer: UIPanGestureRecognizer){
        switch recognizer.state {
        case .changed:
            if startFlag{
                draging?(self, recognizer)
            }
        default: break
        }
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LoopStaticPoses{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
