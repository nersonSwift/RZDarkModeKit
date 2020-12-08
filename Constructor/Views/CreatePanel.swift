//
//  CreatePanel.swift
//  Yoga
//
//  Created by Александр Сенин on 07.04.2020.
//  Copyright © 2020 Александр Сенин. All rights reserved.
//

import UIKit

class SpaseItem: UIView, AllPosesPanelElementProtocol{
    weak var mirrorView: UIView?
}

class CreatePanel: UIScrollView, CreatePanelProtocol{
    var startDrag: (UIView?) -> () {
        {[weak self] view in
            guard let unSelf = self else{return}
            if let loopStaticPoses = view?.superview as? LoopStaticPoses{
                if let count = loopStaticPoses.views.firstIndex(of: view ?? UIView()){
                    unSelf.constructorScreenPresenter?.screen.addAction(action: .startMove(loopStaticPoses, count, view ?? UIView()))
                }
                loopStaticPoses.startDrag(view)
            }else{
                if let count = unSelf.views.firstIndex(of: view ?? UIView()){
                    unSelf.constructorScreenPresenter?.screen.addAction(action: .startMove(unSelf, count, view ?? UIView()))
                }
            }
            (view as? DragingViewProtocol)?.timeLabelIsHiden = false
            view?.frame.origin.x -= unSelf.contentOffset.x
            view?.frame.origin.y += unSelf.frame.minY
            unSelf.changeSize(a: 1.2, d: 1.2, alpha: 0.5, view: view)
            unSelf.setSpaseItem(view: view)
            unSelf.drag(view, nil)
            unSelf.arreng(animation: true)
        }
    }
    
    var delFlag = true
    var drag: (UIView?, CGFloat?) -> () {
        {[weak self] view, _ in
            guard let unSelf = self else{return}
            guard let unView = view else {return}
            
            if unSelf.detectPositeon(view: unView){
                unSelf.createSpaseItem(view: view)
                unSelf.delFlag = true
            }else{
                unSelf.removeSpaseItem()
                for viewL in unSelf.views{
                    if let loopStaticPoses = viewL as? LoopStaticPoses, !(view is LoopStaticPoses){
                        loopStaticPoses.drag(unView, unSelf.contentOffset.x)
                    }
                }
                unSelf.arreng(animation: true)
                unSelf.scrollState = 0
                if unSelf.delFlag{
                    unSelf.delFlag = false
                    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedbackgenerator.prepare()
                    impactFeedbackgenerator.impactOccurred()
                }
                return
            }
            unSelf.setViewPlays(view: view, playsMod: unSelf.contentOffset.x)
            unSelf.checkScroll(view: view)
        }
    }
    
    var drop: (UIView?, CGFloat?) -> () {
    {[weak self] view, _ in
            guard let unSelf = self else{return}
            guard let unView = view else{return}
            unSelf.scrollState = 0
            unSelf.changeSize(a: 1, d: 1, alpha: 1, view: view)
            if unSelf.spaseItem != nil{
                (view as? DragingViewProtocol)?.timeLabelIsHiden = true
                unSelf.delSpaseItem(view: view, playsMod: unSelf.contentOffset.x)
            }else{
                for viewL in unSelf.views{
                    if let loopStaticPoses = viewL as? LoopStaticPoses{
                        if (viewL.frame.minX < (unView.center.x + unSelf.contentOffset.x)) &&
                           (viewL.frame.maxX > (unView.center.x + unSelf.contentOffset.x)){
                            loopStaticPoses.drop(unView, unSelf.contentOffset.x)
                        }
                    }
                }
            }
            unSelf.arreng(animation: true)
        }
    }
    
    var views: [UIView] = []
    var spaseItem: SpaseItem?
    weak var constructorScreenPresenter: ConstructorScreenPresenterIPhoneDelegate?
    
    func arreng(animation: Bool){
        if animation{
            UIView.animate(withDuration: 0.2) {
                self.arreng()
            }
        }else{
            arreng()
        }
    }
    
    private func arreng(){
        var minX = self.frame.width * 0.08
        for view in self.views{
            view.frame.origin.x = minX
            view.center.y = self.frame.height / 2
            minX = view.frame.maxX + self.frame.width * 0.02
        }
        self.contentSize.width = minX + self.frame.width * 0.06
    }
    
    
    private func checkScroll(view: UIView?){
        guard let unView = view else {return}
        if unView.center.x >= frame.width * 0.85{
            if contentOffset.x < contentSize.width - frame.width{
                scrollState = 2
            }else{
                scrollState = 0
            }
        }else if unView.center.x <= frame.width * 0.15{
            if contentOffset.x > 0{
                scrollState = -2
            }else{
                scrollState = 0
            }
        }else{
            scrollState = 0
        }
    }
    
    var scrollState: Int = 0{
        didSet{
            if scrollState != 0{
                scroll(scrollState: scrollState)
            }else{
                linesNamberAnim?.stop()
                linesNamberAnim = nil
            }
        }
    }
    var linesNamberAnim: LinesNamberAnim?
    private func scroll(scrollState: Int){
        linesNamberAnim?.stop()
        linesNamberAnim = LinesNamberAnim()
        linesNamberAnim?.infinity(closer: {[weak self] in
            guard let unSelf = self else {return}
            let pont = CGPoint(x: unSelf.contentOffset.x + (2 * CGFloat(scrollState)), y: unSelf.contentOffset.y)
            if pont.x < 0 || pont.x > unSelf.contentSize.width - unSelf.frame.width{
                unSelf.scrollState = 0
                return
            }
            unSelf.setContentOffset(pont, animated: false)
        })
    }
    
    func getRow() -> [String] {
        var row: [String] = []
        for view in views{
            if let dragingView = view as? DragingViewProtocol{
                let dragingViewRow = dragingView.getRow()
                row += dragingViewRow != "" ? [dragingViewRow] : []
            }
        }
        return row
    }
    
    init(size: CGSize, constructorScreenPresenterIPhoneDelegate: ConstructorScreenPresenterIPhoneDelegate) {
        super.init(frame: CGRect())
        self.frame.size = size
        self.constructorScreenPresenter = constructorScreenPresenterIPhoneDelegate
        self.contentInsetAdjustmentBehavior = .never
        self.showsHorizontalScrollIndicator = false
        self.layer.masksToBounds = false
        createViews(programmModel: constructorScreenPresenterIPhoneDelegate.screen.programmModel)
    }
    
    func removeAllViews(){
        for view in views{
            view.removeFromSuperview()
        }
        views = []
    }
    
    func createViews(programmModel: ProgrammModel){
        if programmModel.programmRow.count == 0{return}
        let complexs = programmModel.getComplexIn(0)
        for complex in complexs{
            var dragingViews: [DragingViewProtocol] = []
            if complex.staticPoses.count == 1 && complex.numberRepit == 1{
                if let view = createStaticPose(staticPoseModel: complex.staticPoses.first!){
                    dragingViews += [view]
                }
            }else{
                if let view = createLoop(complexPoses: complex){
                    if view.count < 2{
                        dragingViews += view.views as? [DragingViewProtocol] ?? []
                    }else{
                        dragingViews += [view]
                    }
                }
            }
            for view in dragingViews{
                view.timeLabelIsHiden = true
                views.append(view)
                addSubview(view)
            }
        }
        arreng(animation: false)
    }
    
    private func createStaticPose(staticPoseModel: StaticPoseModel) -> StaticPosesView?{
        guard let constructorScreenPresenterIPhoneDelegate = constructorScreenPresenter else {return nil}
        let staticPoseView = StaticPosesView(width: self.frame.width * 0.8 / 3,
                                             staticPoseModel: staticPoseModel,
                                             constructorScreenPresenter: constructorScreenPresenterIPhoneDelegate)
        staticPoseView.startDraging = constructorScreenPresenterIPhoneDelegate.startDrag
        staticPoseView.draging = constructorScreenPresenterIPhoneDelegate.drag
        staticPoseView.droping = constructorScreenPresenterIPhoneDelegate.drop
        staticPoseView.dubleTup = constructorScreenPresenterIPhoneDelegate.dubleTup
        return staticPoseView
    }
    
    private func createLoop(complexPoses: StaticPoseComplexModel) -> LoopStaticPoses?{
        guard let constructorScreenPresenterIPhoneDelegate = constructorScreenPresenter else {return nil}
        let loop = LoopStaticPoses(width: self.frame.width * 0.8 / 3,
                                   constructorScreenPresenterIPhoneDelegate: constructorScreenPresenterIPhoneDelegate)
        loop.startDraging = constructorScreenPresenterIPhoneDelegate.startDrag
        loop.draging = constructorScreenPresenterIPhoneDelegate.drag
        loop.droping = constructorScreenPresenterIPhoneDelegate.drop
        
        var timePoses: Int = 0
        for staticPoseModel in complexPoses.staticPoses{
            if let staticPoseView = createStaticPose(staticPoseModel: staticPoseModel){
                staticPoseView.timeLabelIsHiden = false
                loop.views.append(staticPoseView)
                loop.addSubview(staticPoseView)
                timePoses += Int(staticPoseView.time)
            }
        }
        loop.arreng(animation: false)
        
        if complexPoses.countRepit != 0{
            loop.count = complexPoses.countRepit
        }else if timePoses != 0{
            loop.count = Int(complexPoses.time) / timePoses
        }else{
            loop.count = 2
        }
        
        return loop
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
