//
//  ConstructorScreen.swift
//  Yoga
//
//  Created by Александр Сенин on 27.03.2020.
//  Copyright © 2020 Александр Сенин. All rights reserved.
//

import RelizKit
import Lottie

protocol ConstructorScreenPresenterDelegateProtocol : ScreenPresenterDelegate{
    var createPanel: CreatePanel! {get}
    var labelButton: UIButtonP! {get}
    var allPosesPanel: AllPosesPanel? {get}
    //func createPosesPanel()
    func addItem(staticPosesView: StaticPosesView)
    func changeTimeLabel(time: String)
    func getTime() -> String
    func createAllPosesPanel()
    func removeAllPosesPanel()
    
    var startDrag: (UIView?) -> () {get}
    var drag: (UIView?, UIPanGestureRecognizer) -> () {get}
    var drop: (UIView?) -> () {get}
    var dialogView: DialogView? {get}
    var anim: Animation?{get set}
}


class ConstructorScreen: InstallableScreen {
    
    enum ConstructorScreenType {
        case save
        case edit
    }
    
    override func optionOpen(rootViewController: UIViewController) {
        let root = rootViewController as! YogaView
        root.blockSwipe = true
        root.downMenue?.setState(state: .offRight)
    }
    
    override func optionClose(rootViewController: UIViewController){
        let root = rootViewController as! YogaView
        root.blockSwipe = false
    }
    
    var delegate: ConstructorScreenPresenterDelegateProtocol! {return presenterDelegate as? ConstructorScreenPresenterDelegateProtocol}
    override var presenterDelegateTypeIPad: ScreenPresenterDelegateProtocol.Type? {ConstructorScreenPresenterIPhoneDelegate.self}
    override var presenterDelegateTypeIPhone: ScreenPresenterDelegateProtocol.Type? {ConstructorScreenPresenterIPhoneDelegate.self}
    
    var programmModel: ProgrammModel!
    var type: ConstructorScreenType = .save
    
    var staticPoses: [StaticPoseModel] = []
    var saveFlag: Bool = false
    var constructorActions: [ConstructorActions] = []
    
    init() {
        super.init(frame: CGRect())
        self.type = .save
        createProgramm()
    }
    
    init(programmModel: ProgrammModel, type: ConstructorScreenType) {
        super.init(frame: CGRect())
        self.type = type
        
        if type == .save{
            self.programmModel = (try? ProgrammModel(json: programmModel.convertToJson())) ?? programmModel
            self.programmModel.id = "P\(getNumber())U"
            self.programmModel.user = true
            self.programmModel.new = 0
            let color = getRandomGradientName()
            self.programmModel.previewImage = color.0
            self.programmModel.color = color.1
            self.programmModel.programmDescription = ["en": "", "ru": ""]
        }else{
            self.programmModel = programmModel
        }
    }
    
    override func start() {
        setStaticPozes()
        delegate.create()
    }
    
    private func setStaticPozes(){
        var poses: [StaticPoseModel] = []
        for id in DataBase.poseIds{
            if let staticPose = try? StaticPoseModel.serchModelFor(id){
                poses.append(staticPose)
            }
        }
        self.staticPoses = poses
    }
    
    func backButtonAction(){
        _ = screensInstaller.installScreen(instead: self, installingScrin: pastView, anim: .ezAnimR)
    }
    func nameButtonAction(){
        let namePopUp = NamePopUp()
        namePopUp.saveCloser = {[weak self] text in
            guard let unSelf = self else {return}
            unSelf.changeName(name: text)
            if unSelf.saveFlag{
                unSelf.saveButtonAction()
            }
        }
        screensInstaller.installPopUp(in: self, installingPopUpView: namePopUp)
    }
    func changeName(name: String){
        delegate.labelButton.setTitle(name, for: .normal)
        delegate.labelButton.sizeToFit()
        delegate.labelButton.frame.size.width += delegate.labelButton.frame.height * 0.4
        delegate.labelButton.center.x = self.frame.width / 2
    }
    func saveButtonAction(){
        EventManager.prepare(.amp()).name("saved_program")
            .value(["naming":delegate.labelButton.titleLabel?.text ?? ""])
            .send()
        var programmRow = delegate.createPanel.getRow()
        if delegate.allPosesPanel != nil{
            programmRow = delegate.allPosesPanel!.getRow()
        }
        let name = delegate.labelButton.titleLabel?.text ?? ""
        if name == "New program:".localized{
            nameButtonAction()
            saveFlag = true
            return
        }
        if programmRow != []{
            programmModel.name = ["en": name, "ru": name]
            programmModel.label = ["en": name, "ru": name]
            programmModel.programmRow = [programmRow]
            
            programmModel.save()
            
            
            DataBase.userProgrammCounter += 1
            if type == .edit{
                refrashComposeScreen()
            }else{
                reloadComposeScreen()
            }
            backButtonAction()
        }
        if DataBase.developerMode{
            if let objectData = try? JSONSerialization.data(withJSONObject: programmModel.convertToJson(), options: []) {
                let objectString = String(data: objectData, encoding: .utf8)
                UIPasteboard.general.string = objectString
            }
        }
    }
    
    func allPosesPanelButtonAction(){
        delegate.createAllPosesPanel()
    }
    
    func removeAllPosesPanelButtonAction(){
        programmModel.programmRow = [delegate.allPosesPanel?.getRow() ?? []]
        delegate.createPanel.removeAllViews()
        delegate.removeAllPosesPanel()
        delegate.createPanel.createViews(programmModel: programmModel)
        delegate.changeTimeLabel(time: delegate.getTime())
        constructorActions = []
    }
    
    
    func addAction(action: ConstructorActions){
        constructorActions.append(action)
        if constructorActions.count >= 10{
            constructorActions.removeFirst()
        }
    }
    
    func useAction(){
        if constructorActions.count != 0{
            let action = constructorActions.removeLast()
            action.reverst()
        }
    }
    
    func getProgrammModel() -> ProgrammModel{
        let programmRow = delegate.createPanel.getRow()
        programmModel.programmRow = [programmRow]
        return programmModel
    }
    
    private func createProgramm(){
        programmModel = ProgrammModel()
        programmModel.name = ["en": "New program:".localized, "ru": "New program:".localized]
        programmModel.label = ["en": "New program:".localized, "ru": "New program:".localized]
        programmModel.user = true
        programmModel.id = "P\(getNumber())U"
        programmModel.programmDescription = ["en": "", "ru": ""]
        programmModel.lvl = 0
        programmModel.freeDays = 0
        let color = getRandomGradientName()
        programmModel.previewImage = color.0
        programmModel.color = color.1
        programmModel.programmRow = []
    }
    
    private func getNumber() -> String{
        var numberS = "\(DataBase.userProgrammCounter)"
        
        if numberS.count < 3{
            for _ in 1 ... (3 - numberS.count){
                numberS = "0" + numberS
            }
        }

        return numberS
    }
    
    
    private func getRandomGradientName() -> (String, String){
        let rand = Int.random(in: 0...4)
        
        var name = "purple_grad"
        var color = "C192F9"
        switch rand {
            case 0:
                name = "blue_grad"
                color = "4CCEED"
            case 1:
                name = "green_grad"
                color = "59D969"
            case 2:
                name = "purple_grad"
                color = "C192F9"
            case 3:
                name = "red_grad"
                color = "FF8D90"
            case 4:
                name = "yellow_grad"
                color = "FDD748"
        default: break
        }
        return (name, color)
    }
    
    private func reloadComposeScreen(){
        let yoga = screensInstaller.rootViewController as! YogaView
        yoga.composeScreen.reload()
    }
    private func refrashComposeScreen(){
        let yoga = screensInstaller.rootViewController as! YogaView
        yoga.composeScreen.refrash()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


enum ConstructorActions{
    case move(CreatePanelProtocol, Int, CreatePanelProtocol, Int)
    case delete(CreatePanelProtocol, Int, UIView)
    case set(CreatePanelProtocol, Int)
    case setTime(StaticPosesView, Int)
    case setCount(LoopStaticPoses, Int)
    
    case create(UIView)
    case startMove(CreatePanelProtocol, Int, UIView)
    
    func reverst(){
        switch self {
        case .move(let firstPlaсe, let firstCount, let secondPlaсe, let secondCount):
            guard let view = secondPlaсe.views.remove(at: secondCount) as? DragingViewProtocol else{return}
            view.removeFromSuperview()
            firstPlaсe.views.insert(view, at: firstCount)
            firstPlaсe.addSubview(view)
            if firstPlaсe is CreatePanel{
                view.timeLabelIsHiden = true
            }else{
                view.timeLabelIsHiden = false
            }
            if let constructorScreenPresenter = firstPlaсe.constructorScreenPresenter{
                arreng(constructorScreenPresenter)
                constructorScreenPresenter.changeTimeLabel(time: constructorScreenPresenter.getTime())
            }
            
        case .delete(let plaсe, let count, let view):
            guard let view = view as? DragingViewProtocol else{return}
            plaсe.views.insert(view, at: count)
            plaсe.addSubview(view)
            if plaсe is CreatePanel{
                view.timeLabelIsHiden = true
            }else{
                view.timeLabelIsHiden = false
            }
            if let constructorScreenPresenter = plaсe.constructorScreenPresenter{
                arreng(constructorScreenPresenter)
                constructorScreenPresenter.changeTimeLabel(time: constructorScreenPresenter.getTime())
            }
            
        case .set(let plaсe, let count):
            plaсe.views.remove(at: count).removeFromSuperview()
            if let constructorScreenPresenter = plaсe.constructorScreenPresenter{
                arreng(constructorScreenPresenter)
                constructorScreenPresenter.changeTimeLabel(time: constructorScreenPresenter.getTime())
            }
        case .setTime(let staticPosesView, let oldTime):
            staticPosesView.staticPoseModel.time = "\(oldTime)"
            staticPosesView.createTimeLabel()
            if let loop = staticPosesView.superview as? LoopStaticPoses{
                loop.createTimeLabel()
            }
            staticPosesView.constructorScreenPresenter?.changeTimeLabel(time: staticPosesView.constructorScreenPresenter?.getTime() ?? "")
        case .setCount(let loopStaticPoses, let oldCount):
            loopStaticPoses.count = oldCount
        default: break
        }
    }
    
    private func arreng(_ constructorScreenPresenter: ConstructorScreenPresenterIPhoneDelegate){
        for view in constructorScreenPresenter.createPanel.views{
            if let loop = view as? LoopStaticPoses{
                loop.arreng(animation: false)
            }
        }
        constructorScreenPresenter.createPanel.arreng(animation: false)
    }
}

