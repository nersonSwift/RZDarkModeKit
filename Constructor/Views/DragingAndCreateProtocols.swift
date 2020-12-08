//
//  DragingAndCreateProtocols.swift
//  Yoga
//
//  Created by Александр Сенин on 07.04.2020.
//  Copyright © 2020 Александр Сенин. All rights reserved.
//

import UIKit

protocol DragingViewProtocol: UIView, UIGestureRecognizerDelegate{
    var startDraging: ((UIView?) -> ())? { get set }
    var draging:      ((UIView?, UIPanGestureRecognizer) -> ())? { get set }
    var droping:      ((UIView?) -> ())? { get set }
    
    var tagView: TagView! { get set }
    var timeLabelIsHiden: Bool { get set }
    var time: Int { get set }
    func createTimeLabel()
    func getRow() -> String
}

protocol CreatePanelProtocol: UIView{
    var startDrag: (UIView?) -> () {get}
    var drag:      (UIView?, CGFloat?) -> () {get}
    var drop:      (UIView?, CGFloat?) -> () {get}
    var constructorScreenPresenter: ConstructorScreenPresenterIPhoneDelegate? {get}
    
    var views: [UIView] {get set}
    var spaseItem: SpaseItem? {get set}
    
    func changeSize(a: CGFloat, d: CGFloat, alpha: CGFloat, view: UIView?)
    
    func arreng(animation: Bool)
    func createSpaseItem(view: UIView?)
    func removeSpaseItem()
}

extension CreatePanelProtocol{
    
    func setSpaseItem(view: UIView?){
        createSpaseItem(view: view)
        var newArr: [UIView] = []
        for viewL in views{
            if view == viewL{
                if let unSpaseItem = spaseItem{
                    newArr.append(unSpaseItem)
                }
            }else{
                newArr.append(viewL)
            }
        }
        views = newArr
    }
    
    func delSpaseItem(view: UIView?, playsMod: CGFloat? = nil, parentMod: Bool = false){
        var newArr: [UIView] = []
        for (count, viewL) in views.enumerated(){
            if let spaseItem = viewL as? SpaseItem{
                if let unView = spaseItem.mirrorView{
                    unView.frame.origin.x += playsMod ?? 0
                    unView.frame.origin.y -= self.frame.minY
                    if parentMod{
                        unView.frame.origin.y -= self.superview?.frame.minY ?? 0
                    }
                    addSubview(unView)
                    removeSpaseItem()
                    newArr.append(unView)
                    if constructorScreenPresenter?.screen.constructorActions.count != 0{
                        
                        switch constructorScreenPresenter?.screen.constructorActions.removeLast(){
                        case .create:
                            constructorScreenPresenter?.screen.addAction(action: .set(self, count))
                        case .startMove(let place, let countF, _):
                            if place != self || countF != count{
                                constructorScreenPresenter?.screen.addAction(action: .move(place, countF, self, count))
                            }
                        default:break
                        }
                    }
                }
            }else{
                newArr.append(viewL)
            }
        }
        self.views = newArr
    }
    
    func changeSize(a: CGFloat, d: CGFloat, alpha: CGFloat, view: UIView?){
        UIView.animate(withDuration: 0.2) {
            view?.transform.a = a
            view?.transform.d = d
            view?.alpha = alpha
        }
    }
    
    func detectPositeon(view: UIView?, mod: CGFloat? = nil, parentMod: Bool = false) -> Bool {
        guard let unView = view else {return false}
        var viewCenterX = (unView.center.x + (mod ?? 0))
        var viewCenterY = unView.center.y
        if parentMod{
            viewCenterX -= self.superview?.frame.minX ?? 0
            viewCenterY -= self.superview?.frame.minY ?? 0
        }
        if frame.maxX >= viewCenterX && frame.minX <= viewCenterX &&
           frame.maxY >= viewCenterY && frame.minY <= viewCenterY{
            return true
        }else{
            return false
        }
    }
    
    func setViewPlays(view: UIView?, playsMod: CGFloat = 0){
        guard let unView = view else {return}
        var flag = false
        var newViews: [UIView] = []
        for viewL in views{
            if let loopStaticPoses = viewL as? LoopStaticPoses, !(view is LoopStaticPoses){
                loopStaticPoses.drag(unView, playsMod)
                if (viewL.frame.minX < (unView.center.x + playsMod)) && (viewL.frame.maxX > (unView.center.x + playsMod)){
                    self.removeSpaseItem()
                    flag = true
                }else{
                    serchSpaseItemPlase(view: viewL, selectView: unView, playsMod: playsMod, views: &newViews, setFlag: &flag)
                }
            }else{
                serchSpaseItemPlase(view: viewL, selectView: unView, playsMod: playsMod, views: &newViews, setFlag: &flag)
            }
            if unView != viewL && !(viewL is SpaseItem){
                newViews.append(viewL)
            }
        }
        if !flag, let unSpaseItem = spaseItem{
            newViews.append(unSpaseItem)
        }
        views = newViews
        arreng(animation: true)
    }
    
    func serchSpaseItemPlase(view: UIView, selectView: UIView, playsMod: CGFloat, views: inout [UIView], setFlag: inout Bool){
        if view.center.x > (selectView.center.x + playsMod){
            if let unSpaseItem = spaseItem, !setFlag{
                setFlag = true
                views.append(unSpaseItem)
            }
        }
    }
    
    func createSpaseItem(view: UIView?){
        if spaseItem != nil || view == nil {return}
        let spaseItem = SpaseItem()
        spaseItem.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4875856164)
        spaseItem.frame.size.width = view!.frame.width * 0.51
        spaseItem.mirrorView = view
        self.spaseItem = spaseItem
    }
    
    func removeSpaseItem(){
        if spaseItem == nil {return}
        views = views.filter{!($0 is SpaseItem)}
        spaseItem = nil
    }
    
}
