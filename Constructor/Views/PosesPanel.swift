//
//  PosesPanel.swift
//  Yoga
//
//  Created by Александр Сенин on 07.04.2020.
//  Copyright © 2020 Александр Сенин. All rights reserved.
//

import UIKit

class PosesPanel: UIScrollView{
    var drop: (UIView?) -> () { {$0?.removeFromSuperview()} }
    
    weak var constructorScreenPresenter: ConstructorScreenPresenterDelegateProtocol?
    
    var staticPoses: [StaticPoseModel] = []
    var staticPoseViews: [StaticPosesView] = []
    
    override var contentOffset: CGPoint{
        didSet{
            let size = self.frame.width * 0.8 / 3
            for staticPoseView in staticPoseViews{
                let min = (contentOffset.y - size) < staticPoseView.frame.maxY
                let max = (contentOffset.y + self.frame.height + size) > staticPoseView.frame.minY
                if min && max{
                    staticPoseView.aView?.startAnimating()
                }else{
                    staticPoseView.aView?.stopAnimating()
                }
            }
        }
    }
    
    init(size: CGSize, staticPoses: [StaticPoseModel], constructorScreenPresenter: ConstructorScreenPresenterDelegateProtocol?) {
        super.init(frame: CGRect())
        self.frame.size = size
        self.staticPoses = staticPoses
        self.constructorScreenPresenter = constructorScreenPresenter
        self.contentInsetAdjustmentBehavior = .never
        createStaticPosesViews()
    }
    
    private func createStaticPosesViews(){
        var minX: CGFloat = self.frame.width * 0.05
        var minY: CGFloat = self.frame.height * 0.45 + self.frame.width * 0.17
        for (number, staticPose) in staticPoses.enumerated(){
            let staticPosesView = createStaticPosesView(staticPoseModel: staticPose)
            staticPosesView.frame.origin.x = minX
            staticPosesView.frame.origin.y = minY
            minX = staticPosesView.frame.maxX + self.frame.width * 0.05
            if ((number + 1) % 3 == 0) && (number != 0){
                minY = staticPosesView.frame.maxY + self.frame.width * 0.05
                minX = self.frame.width * 0.05
            }
            self.addSubview(staticPosesView)
            self.staticPoseViews.append(staticPosesView)
        }
        self.contentSize.height = minY + self.frame.width * 0.23
    }
    
    func setTag(tag: StaticPoseTag){
        var minX: CGFloat = self.frame.width * 0.05
        var minY: CGFloat = self.frame.height * 0.45 + self.frame.width * 0.17
        var maxY: CGFloat = minY
        var number = 0
        for staticPoseView in staticPoseViews{
            if staticPoseView.staticPoseModel.testTag(tagId: tag.rawValue) || tag == .all{
                staticPoseView.alpha = 1
                staticPoseView.frame.origin.x = minX
                staticPoseView.frame.origin.y = minY
                minX = staticPoseView.frame.maxX + self.frame.width * 0.05
                if ((number + 1) % 3 == 0) && (number != 0){
                    minY = staticPoseView.frame.maxY + self.frame.width * 0.05
                    minX = self.frame.width * 0.05
                }
                maxY = staticPoseView.frame.maxY + self.frame.width * 0.05
                number += 1
            }else{
                staticPoseView.alpha = 0
            }
            self.contentSize.height = maxY + self.frame.width * 0.23
        }
    }
    
    private func createStaticPosesView(staticPoseModel: StaticPoseModel) -> StaticPosesView{
        let staticPosesView = StaticPosesView(width: self.frame.width * 0.8 / 3,
                                              staticPoseModel: staticPoseModel,
                                              constructorScreenPresenter: self.constructorScreenPresenter)
        
        let button = UIButtonP(frame: staticPosesView.bounds)
        button.addClosure(event: .touchUpInside) {[weak self, weak staticPosesView] in
            guard let unSelf = self else {return}
            guard let unStaticPosesView = staticPosesView else {return}
            guard let staticModel = try? StaticPoseModel(json: unStaticPosesView.staticPoseModel.convertToJson()) else {return}
            let mirror = StaticPosesView(width: unStaticPosesView.frame.width,
                                         staticPoseModel: staticModel,
                                         image: unStaticPosesView.imageView.image,
                                         constructorScreenPresenter: unSelf.constructorScreenPresenter)
            unSelf.constructorScreenPresenter?.addItem(staticPosesView: mirror)
        }
        staticPosesView.addSubview(button)
        
        return staticPosesView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
