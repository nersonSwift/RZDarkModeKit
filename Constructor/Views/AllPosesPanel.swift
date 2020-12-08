//
//  AllPosesPanel.swift
//  Yoga
//
//  Created by Александр Сенин on 15.05.2020.
//  Copyright © 2020 Александр Сенин. All rights reserved.
//

import RelizKit

class AllPosesPanel: UIScrollView {
    var startDrag: (UIView?, Bool) -> () {
        {[weak self] view, loop in
            guard let unSelf = self else{return}
            guard let unView = view else{return}
            let (posNumber, addToLoop) = unSelf.getPosNumber(center: unView.center)
            unView.frame.origin.y += unSelf.frame.minY
            unView.frame.origin.y -= unSelf.contentOffset.y
            unSelf.constructorScreenPresenter?.screen.addSubview(unView)
            
            unSelf.spaseItem = SpaseItem(frame: unView.bounds)
            
            unSelf.spaseItem?.mirrorView = unView
            
            unSelf.setSpase(in: posNumber, addToLoop: addToLoop, isLoop: loop)
            
            if let allPosesPanelElementProtocol = unView as? AllPosesPanelElementProtocol{
                unSelf.removeItem(item: allPosesPanelElementProtocol)
            }
            unSelf.arreng(animate: true)
        }
    }
    
    var drag: (UIView?, Bool) -> () {
        {[weak self] view, loop in
            guard let unSelf = self else{return}
            guard let unView = view else {return}
            var point = unView.center
            point.y -= unSelf.frame.minY
            point.y += unSelf.contentOffset.y
            
            let (posNumber, addToLoop) = unSelf.getPosNumber(center: point)
            unSelf.setSpase(in: posNumber, addToLoop: addToLoop, isLoop: loop)
            unSelf.arreng(animate: true)
        }
    }
    
    var drop: (UIView?, Bool) -> () {
        {[weak self] view, loop in
            guard let unSelf = self else{return}
            guard let unView = view else{return}
            unView.frame.origin.y -= unSelf.frame.minX
            unView.frame.origin.y += unSelf.contentOffset.y
            self?.addSubview(unView)
            
            if !loop{
                unSelf.removeSpaseItem(addView: true)
                unSelf.arreng(animate: true)
            }
            unSelf.constructorScreenPresenter?.changeTimeLabel(time: unSelf.getTime())
        }
    }
    
    var height: CGFloat = 0
    var blurEffectView: UIView!
    var allPosesPanelElements: [AllPosesPanelElementProtocol] = []
    var viewsPoints: [UIView] = []
    var programmModel: ProgrammModel!
    var staticView: Bool = false
    weak var constructorScreenPresenter: ConstructorScreenPresenterIPhoneDelegate?
    
    
     
    init(size: CGSize, programmModel: ProgrammModel,
         constructorScreenPresenter: ConstructorScreenPresenterIPhoneDelegate? = nil,
         blurEffectViewHeight: CGFloat,
         staticView: Bool = false) {
        
        super.init(frame: CGRect())
        self.contentInsetAdjustmentBehavior = .never
        self.staticView = staticView
        frame.size = size
        
        ParentElements.colorise {[weak self] in
            if staticView{
                self?.backgroundColor = ColorScheme.aWB.color
            }else{
                self?.backgroundColor = ColorScheme.aPldB.color
            }
            return self
        }

        self.height = blurEffectViewHeight
        self.constructorScreenPresenter = constructorScreenPresenter
        self.programmModel = programmModel
        
        createViews(programmModel: programmModel)
        createViewsPoints()
        arreng(animate: false)
        if staticView{
            createSeporaters()
        }
    }
    
    private func createSeporaters(){
        var maxY: CGFloat = 0
        for allPosesPanelElement in allPosesPanelElements{
            if let loop = allPosesPanelElement as? AllPosesPanelLoop{
                for allPosesPanelElement in loop.allPosesPanelElements{
                    setSeporator(maxY: &maxY, allPosesPanelElement: allPosesPanelElement)
                }
            }
            if let allPosesPanelElement = allPosesPanelElement as? AllPosesPanelElement{
                setSeporator(maxY: &maxY, allPosesPanelElement: allPosesPanelElement)
            }
        }
    }
    
    private func setSeporator(maxY: inout CGFloat, allPosesPanelElement: UIView){
        if (allPosesPanelElement.frame.maxY + self.frame.width * 0.008) > maxY{
            if maxY != 0{
                let seporater = UIView()
                seporater.frame.size.width = self.frame.width * 0.9
                seporater.frame.size.height = 1.5
                seporater.center.x = self.frame.width / 2
                seporater.center.y = maxY
                seporater.alpha = 0.3
                seporater.backgroundColor = ColorScheme.grayLight.color
                self.addSubview(seporater)
                self.sendSubviewToBack(seporater)
            }
            maxY = allPosesPanelElement.frame.maxY + self.frame.width * 0.008
        }
    }
    
    
    func getRow() -> [String] {
        var row: [String] = []
        for allPosesPanelElement in allPosesPanelElements{
            if let loop = allPosesPanelElement as? AllPosesPanelLoop{
                let dragingViewRow = loop.getRow()
                row += dragingViewRow != "" ? [dragingViewRow] : []
            }
            if let allPosesPanelElement = allPosesPanelElement as? AllPosesPanelElement{
                row += [allPosesPanelElement.view.getRow()]
            }
        }
        return row
    }
    
    private func createViews(programmModel: ProgrammModel){
        if programmModel.programmRow.count == 0{return}
        
        let complexs = programmModel.getComplexIn(0)
        for complex in complexs{
            var allPosesPanelLoop: AllPosesPanelLoop? = nil
            if complex.numberRepit != 1{
                allPosesPanelLoop = AllPosesPanelLoop(staticView: self.staticView)
                if complex.numberRepit > 1{
                    allPosesPanelLoop?.count = complex.numberRepit
                }else{
                    var timePoses: Int = 0
                    for staticPoseModel in complex.staticPoses{
                        if let staticPoseView = createStaticPose(staticPoseModel: staticPoseModel, staticView: staticView){
                            staticPoseView.timeLabelIsHiden = false
                            timePoses += Int(staticPoseView.time)
                        }
                    }
                    allPosesPanelLoop?.count = Int(complex.time) / timePoses
                }
                allPosesPanelLoop?.startDraging = startDrag
                allPosesPanelLoop?.draging = drag
                allPosesPanelLoop?.droping = drop
                allPosesPanelElements.append(allPosesPanelLoop!)
            }
            for staticPose in complex.staticPoses{
                if let view = createStaticPose(staticPoseModel: staticPose, staticView: staticView){
                    let allPosesPanelElement = AllPosesPanelElement(view: view, staticView: self.staticView)
                    allPosesPanelElement.startDraging = startDrag
                    allPosesPanelElement.draging = drag
                    allPosesPanelElement.droping = drop
                    self.addSubview(allPosesPanelElement)
                    if let allPosesPanelLoop = allPosesPanelLoop{
                        view.timeLabelIsHiden = false
                        allPosesPanelLoop.allPosesPanelElements.append(allPosesPanelElement)
                    }else{
                        view.timeLabelIsHiden = true
                        allPosesPanelElements.append(allPosesPanelElement)
                    }
                }
            }
        }
    }
    
    func getTime() -> Int{
        var time = 0
        for allPosesPanelElement in allPosesPanelElements{
            if let loop = allPosesPanelElement as? AllPosesPanelLoop{
                time += loop.time
            }
            if let allPosesPanelElement = allPosesPanelElement as? AllPosesPanelElement{
                time += allPosesPanelElement.view.time
            }
        }
        return time
    }
    
    
    private func createStaticPose(staticPoseModel: StaticPoseModel, staticView: Bool) -> StaticPosesView?{
        //guard let constructorScreenPresenterIPhoneDelegate = constructorScreenPresenter else {return nil}
        let staticPoseView = StaticPosesView(width: self.frame.width * 0.65 / 3,
                                             staticPoseModel: staticPoseModel,
                                             constructorScreenPresenter: constructorScreenPresenter,
                                             addRecognizerFlag: false,
                                             staticView: staticView)
        staticPoseView.setDragingMod()
        return staticPoseView
    }
    
    private func createViewsPoints(){
        for allPosesPanelElement in allPosesPanelElements{
            if let allPosesPanelLoop = allPosesPanelElement as? AllPosesPanelLoop{
                for _ in allPosesPanelLoop.allPosesPanelElements{
                    let view = createPoint()
                    viewsPoints.append(view)
                }
            }else{
                let view = createPoint()
                viewsPoints.append(view)
            }
        }
        let view = createPoint()
        viewsPoints.append(view)
    }
    
    private func createPoint() -> UIView{
        let size = CGSize(width: self.frame.width * 0.9 / 3, height: self.frame.width / 3)
        var minX = viewsPoints.last?.frame.maxX ?? self.frame.width * 0.05
        var minY = viewsPoints.last?.frame.minY ?? height * 1.2
        
        if minX >= self.frame.width * 0.95{
            minX = self.frame.width * 0.05
            minY = viewsPoints.last?.frame.maxY ?? 0
        }
        
        let view = UIView()
        view.frame.size = size
        view.frame.origin.x = minX
        view.frame.origin.y = minY
        
        if staticView{
            self.frame.size.height = view.frame.maxY + self.frame.width * 0.23
        }else{
            self.contentSize.height = view.frame.maxY + self.frame.width * 0.23
        }
        return view
    }
    
    func arreng(animate: Bool = false){
        var count = 0
        for allPosesPanelElement in allPosesPanelElements{
            if let allPosesPanelLoop = allPosesPanelElement as? AllPosesPanelLoop{
                allPosesPanelLoop.chackEmptyBox(view: self)
                for allPosesPanelElement in allPosesPanelLoop.allPosesPanelElements{
                    if let allPosesPanelElement = allPosesPanelElement as? AllPosesPanelElement{
                        allPosesPanelElement.view.timeLabelIsHiden = false
                    }
                    if count >= self.viewsPoints.count{
                        let view = self.createPoint()
                        self.viewsPoints.append(view)
                    }
                    UIView.animate(withDuration: animate ? 0.3 : 0) {
                        allPosesPanelElement.center = self.viewsPoints[count].center
                    }
                    count += 1
                }
                allPosesPanelLoop.createLoopsBack(view: self, animate: animate)
            }else if let allPosesPanelElement = allPosesPanelElement as? UIView{
                if let allPosesPanelElement = allPosesPanelElement as? AllPosesPanelElement{
                    allPosesPanelElement.view.timeLabelIsHiden = true
                }
                
                if count >= self.viewsPoints.count{
                    let view = self.createPoint()
                    self.viewsPoints.append(view)
                }
                UIView.animate(withDuration: animate ? 0.3 : 0) {
                    allPosesPanelElement.center = self.viewsPoints[count].center
                }
                count += 1
            }
        }
    }
    
    var spaseItem: SpaseItem?
    private func removeSpaseItem(addView: Bool = false){
        removeItem(item: spaseItem, setItem: addView ? spaseItem?.mirrorView as? AllPosesPanelElementProtocol : nil)
    }
    
    func removeItem(item: AllPosesPanelElementProtocol?, setItem: AllPosesPanelElementProtocol? = nil){
        for (count, allPosesPanelElement) in allPosesPanelElements.enumerated(){
            if allPosesPanelElement == item ?? UIView(){
                allPosesPanelElements.remove(at: count)
                if let view = setItem{
                    allPosesPanelElements.insert(view, at: count)
                }
                return
            }else if let loop = allPosesPanelElement as? AllPosesPanelLoop{
                for (count, allPosesPanelElement) in loop.allPosesPanelElements.enumerated(){
                    if allPosesPanelElement == item{
                        loop.allPosesPanelElements.remove(at: count)
                        if let view = setItem as? AllPosesPanelElement{
                            loop.allPosesPanelElements.insert(view, at: count)
                        }
                        return
                    }
                }
            }
        }
    }
    
    private func getPosNumber(center point: CGPoint) -> (Int, Int){
        var point = point
        protectPoint(&point)
        
        var count: Int = 0
        var addToLoop: Int = 0
        for (countL, viewsPoint) in viewsPoints.enumerated(){
            if testPoints(viewsPoint.frame, point){
                count = countL + 1
                if (viewsPoint.frame.width * 0.25) >= (point.x - viewsPoint.frame.minX){
                    addToLoop = -1
                }
                if (viewsPoint.frame.width * 0.75) <= (point.x - viewsPoint.frame.minX){
                    addToLoop = 1
                }
                return (count, addToLoop)
            }
        }
        return (count, addToLoop)
    }

    private func protectPoint(_ point: inout CGPoint){
        if point.x < self.frame.width * 0.05{
            point.x = self.frame.width * 0.05
        }
        if point.x > self.frame.width * 0.95{
            point.x = self.frame.width * 0.95
        }
    }
    
    private func testPoints(_ frame: CGRect, _ point: CGPoint) -> Bool{
        let testX = frame.minX <= point.x && frame.maxX >= point.x
        let testY = frame.minY <= point.y && frame.maxY >= point.y
        return testX && testY
    }
    
    private func setSpase(in pos: Int, addToLoop: Int = 0, isLoop: Bool = false){
        var pos = pos
        guard let spaseItem = spaseItem else {return}
        
        if pos == 0{
            removeSpaseItem()
            allPosesPanelElements.append(spaseItem)
            return
        }
        
        for (count, allPosesPanelElement) in allPosesPanelElements.enumerated(){
            if allPosesPanelElement is UIView{
                pos -= 1
            }else if let allPosesPanelLoop = allPosesPanelElement as? AllPosesPanelLoop{
                if pos > allPosesPanelLoop.allPosesPanelElements.count{
                    pos -= allPosesPanelLoop.allPosesPanelElements.count
                    if pos == 1 && addToLoop == -1 && !isLoop && !allPosesPanelLoop.empty{
                        removeSpaseItem()
                        allPosesPanelLoop.allPosesPanelElements.append(spaseItem)
                        return
                    }
                }else{
                    if isLoop{
                        if pos <= allPosesPanelLoop.allPosesPanelElements.count / 2{
                            removeSpaseItem()
                            insertObj(arr: &allPosesPanelElements, obj: spaseItem, plase: count - 1)
                            return
                        }else{
                            removeSpaseItem()
                            insertObj(arr: &allPosesPanelElements, obj: spaseItem, plase: count + 1)
                            return
                        }
                    }
                    if addToLoop == -1 && (pos - 1) == 0 && !isLoop && allPosesPanelLoop.allPosesPanelElements.count > 1{
                        removeSpaseItem()
                        insertObj(arr: &allPosesPanelElements, obj: spaseItem, plase: count)
                        return
                    }
                    if addToLoop == 1 && pos == allPosesPanelLoop.allPosesPanelElements.count && !isLoop && allPosesPanelLoop.allPosesPanelElements.count > 1{
                        removeSpaseItem()
                        insertObj(arr: &allPosesPanelElements, obj: spaseItem, plase: count + 1)
                        return
                    }
                    removeSpaseItem()
                    insertObj(arr: &allPosesPanelLoop.allPosesPanelElements, obj: spaseItem, plase: pos - 1)
                    return
                }
            }
            if pos == 0{
                if (allPosesPanelElements.count - 1) >= count + 1{
                    if let allPosesPanelLoop = allPosesPanelElements[count + 1] as? AllPosesPanelLoop,
                       addToLoop == 1 && !isLoop{
                        removeSpaseItem()
                        insertObj(arr: &allPosesPanelLoop.allPosesPanelElements, obj: spaseItem, plase: 0)
                        return
                    }
                }
                removeSpaseItem()
                insertObj(arr: &allPosesPanelElements, obj: spaseItem, plase: count)
                return
            }
        }
        removeSpaseItem()
        allPosesPanelElements.append(spaseItem)
        return
    }
    
    private func insertObj<T>(arr: inout [T], obj: T, plase: Int){
        if arr.count >= plase && plase >= 0{
            arr.insert(obj, at: plase)
        }else{
            arr.append(obj)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol AllPosesPanelElementProtocol: NSObject {}

class AllPosesPanelElement: UIView, AllPosesPanelElementProtocol{
    var startDraging: ((UIView?, Bool) -> ())?
    var draging: ((UIView?, Bool) -> ())?
    var droping: ((UIView?, Bool) -> ())?
    
    var view: StaticPosesView!
    var staticView: Bool = false
    
    init(view: StaticPosesView, staticView: Bool = false){
        super.init(frame: view.bounds)
        addSubview(view)
        self.view = view
        
        if !staticView{
            addRecognizer()
            addRecognizer1()
        }
    }
    
    private func addRecognizer() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressAction))
        self.addGestureRecognizer(longPress)
    }
    private func addRecognizer1() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panAction))
        pan.delegate = self
        self.addGestureRecognizer(pan)
    }
    
    var start = false
    @objc private func longPressAction(recognizer: UILongPressGestureRecognizer){
        switch recognizer.state {
        case .began:
            start = true
            self.startDraging?(self, false)
            let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
            impactFeedbackgenerator.prepare()
            impactFeedbackgenerator.impactOccurred()
        case .ended:
            start = false
            self.droping?(self, false)
        default: break
        }
    }
    @objc private func panAction(recognizer: UIPanGestureRecognizer){
        
        switch recognizer.state {
        case .changed:
            
            if start{
                let speed = recognizer.translation(in: self)
                
                self.center.x += speed.x
                self.center.y += speed.y
                
                recognizer.setTranslation(CGPoint.zero, in: self)
                self.draging?(self, false)
            }
        default: break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AllPosesPanelElement: UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

class AllPosesPanelLoop: NSObject, AllPosesPanelElementProtocol{
    var allPosesPanelElements: [UIView] = []
    var loopsBack: [CGFloat: UIView] = [:]
    var countView: UIView!
    var emptyBox: UIView?
    var countLabel: UILabel!
    var staticView: Bool = false
    var time: Int{
        var time = 0
        for allPosesPanelElement in allPosesPanelElements{
            if let allPosesPanelElement = allPosesPanelElement as? AllPosesPanelElement{
                time += allPosesPanelElement.view.time
            }
        }
        time *= count
        return time
    }
    var count: Int = 20{
        didSet{
            countLabel?.text = "\(count)"
            countLabel?.sizeToFit()
            countLabel?.center.x = (countView?.frame.width ?? 0) / 2
            
            let supeeView = countView?.superview as? AllPosesPanel
            supeeView?.constructorScreenPresenter?.changeTimeLabel(time: supeeView?.getTime() ?? 0)
        }
    }
    var selfLink: AllPosesPanelLoop?
    
    var startDraging: ((UIView?, Bool) -> ())?
    var draging: ((UIView?, Bool) -> ())?
    var droping: ((UIView?, Bool) -> ())?
    
    var empty: Bool {emptyBox != nil}
    
    func getRow() -> String {
        var row: String = ""
        for view in allPosesPanelElements{
            if let dragingView = view as? AllPosesPanelElement{
                if row != ""{
                    row += ","
                }
                row += dragingView.view.getRow()
            }
        }
        if row == "" {return ""}
        row = "\(count)," + row
        return row
    }
    
    init(staticView: Bool = false) {
        super.init()
        self.staticView = staticView
    }
    
    func createLoopsBack(view: UIView, animate: Bool = false){
        createCountView()
        var test = loopsBack.keys.map{return $0}
        for (count, allPosesPanelElement) in allPosesPanelElements.enumerated(){
            var loopBack: UIView! = loopsBack[allPosesPanelElement.center.y]
            test = test.filter{$0 != allPosesPanelElement.center.y}
            var newFlag = false
            if loopBack == nil {
                loopBack = createLoopBack(view: view, size: allPosesPanelElement.frame.size, center: allPosesPanelElement.center)
                newFlag = true
            }
            if count == 0 || allPosesPanelElements.count == 1{
                if newFlag {
                    loopBack.center.y = allPosesPanelElement.center.y
                    loopBack.frame.origin.x = view.frame.width
                }
            }
            if count == allPosesPanelElements.count - 1 && !(allPosesPanelElements.count == 1){
                if newFlag {
                    loopBack.center.y = allPosesPanelElement.center.y
                    loopBack.frame.origin.x = -loopBack.frame.width
                }
            }
            UIView.animate(withDuration: animate ? 0.3 : 0){
                if count == 0{
                    loopBack.frame.size = allPosesPanelElement.frame.size
                    loopBack.center = allPosesPanelElement.center
                    self.countView.frame.origin = loopBack.frame.origin
                    self.countView.frame.origin.x -= self.countView.frame.width
                    loopBack.frame.size.width += self.countView.frame.width
                    loopBack.frame.origin.x = self.countView.frame.minX
                    view.addSubview(self.countView)
                }
                
                if allPosesPanelElement.center.x + view.frame.width * 0.15 >= view.frame.width * 0.95,
                   count != self.allPosesPanelElements.count - 1{
                    loopBack.frame.size.width = view.frame.width * 1.07 - loopBack.frame.minX
                }else if count != 0 && allPosesPanelElement.center.x - view.frame.width * 0.15 <= view.frame.width * 0.05{
                    loopBack.frame.size = allPosesPanelElement.frame.size
                    loopBack.frame.size.width = allPosesPanelElement.frame.maxX + view.frame.width * 0.07
                    loopBack.layer.cornerRadius = self.countView.layer.cornerRadius
                    loopBack.center = allPosesPanelElement.center
                    loopBack.frame.origin.x = -view.frame.width * 0.07
                }else{
                    loopBack.frame.size.width = allPosesPanelElement.frame.maxX - loopBack.frame.minX
                }
            }
        }
        removeLoopsBack(at: test, view: view)
    }
    
    func chackEmptyBox(view: UIView){
        if allPosesPanelElements == []{
            createEmptyBox(view: view)
        }else if emptyBox != nil, allPosesPanelElements.count >= 2{
            delitEmptyBox()
        }
    }
    private func createEmptyBox(view: UIView){
        let size = CGSize(width: view.frame.width * 0.65 / 3, height: view.frame.width * 0.65 / 3)
        emptyBox = UIView()
        emptyBox?.frame.size = size
        allPosesPanelElements.append(emptyBox!)
    }
    private func delitEmptyBox(){
        for (count, view) in allPosesPanelElements.enumerated(){
            if view == emptyBox{
                allPosesPanelElements.remove(at: count)
                emptyBox = nil
            }
        }
    }
    
    private func removeLoopsBack(at keys: [CGFloat], view: UIView){
        for key in keys{
            if let loopBack = loopsBack[key]{
                UIView.animate(withDuration: 0.3, animations: {
                    if loopBack.frame.maxX > view.frame.width{
                        loopBack.frame.origin.x = view.frame.width * 1.07
                    }
                    loopBack.frame.size.width = 0
                }){_ in
                    self.loopsBack[key] = nil
                    loopBack.removeFromSuperview()
                }
            }
        }
    }
    
    func createLoopBack(view: UIView, size: CGSize, center: CGPoint) -> UIView{
        let loopBack = UIView()
        
        ParentElements.colorise {[weak loopBack]  in
            loopBack?.backgroundColor = ColorScheme.aPelW.color.withAlphaComponent(0.3)
            return loopBack
        }
        
        loopBack.frame.size = size
        loopBack.center = center
        loopBack.layer.cornerRadius = countView.layer.cornerRadius
        view.addSubview(loopBack)
        view.sendSubviewToBack(loopBack)
        loopsBack[center.y] = loopBack
        return loopBack
    }
    
    private func createCountView(){
        if countView != nil {return}
        countLabel = ParentElements.label(text: "\(count)", font: .creatorDel(.regular, 25), color: #colorLiteral(red: 0.6549019608, green: 0.4352941176, blue: 0.9607843137, alpha: 1))
        
        countView = UIView()
        countView.frame.size.width = countLabel.frame.size.height * 1.1
        countView.frame.size.height = ParentElements.rootSize.width * 0.65 / 3
        countView.layer.cornerRadius = countView.frame.width / 2
        
        if !staticView{
            countView.backgroundColor = ColorScheme.white.color
        }else{
            ParentElements.colorise {[weak countView]  in
                countView?.backgroundColor = ColorScheme.aPelW.color
                return countView
            }
        }
        
        countLabel.center.x = countView.frame.width / 2
        countLabel.center.y = countView.frame.height / 2
        
        countView.addSubview(countLabel)
        
        if !staticView{
            addRecognizer(view: countView)
            addRecognizer1(view: countView)
            addRecognizer2(view: countView)
        }
    }
    
    private func addRecognizer(view: UIView) {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressAction))
        view.addGestureRecognizer(longPress)
    }
    private func addRecognizer1(view: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panAction))
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }
    private func addRecognizer2(view: UIView) {
        let swipeRightRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tap))
        view.addGestureRecognizer(swipeRightRecognizer)
    }
    
    
    @objc private func tap(recognizer: UITapGestureRecognizer){
        let popUp = RepeatPopUp(counter: count)
        popUp.saveCloser = {[weak self] numbur in
            guard let unSelf = self else {return}
            unSelf.count = numbur
        }
        let screensInstaller = ScreensInstallerOld.screensInstaller
        let yoga = ScreensInstallerOld.screensInstaller.rootViewController as! YogaView
        screensInstaller.installPopUp(in: yoga.scrin, installingPopUpView: popUp)
    }
    
    var start: Bool = false
    @objc private func longPressAction(recognizer: UILongPressGestureRecognizer){
        guard let view = recognizer.view else {return}
        let supeeView = view.superview as? AllPosesPanel
        
        switch recognizer.state {
        case .began:
            selfLink = self
            supeeView?.removeItem(item: self)
            setAllViewInCountView()
            
            start = true
            self.startDraging?(view, true)
            let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
            impactFeedbackgenerator.prepare()
            impactFeedbackgenerator.impactOccurred()
        case .ended:
            start = false
            self.droping?(view, true)
            let supeeView = view.superview as? AllPosesPanel
            setAllViewBack(backView: supeeView)
            supeeView?.removeItem(item: supeeView?.spaseItem, setItem: self)
            supeeView?.arreng(animate: true)
            selfLink = nil
            supeeView?.constructorScreenPresenter?.changeTimeLabel(time: supeeView?.getTime() ?? 0)
        default: break
        }
    }
    
    private func setAllViewInCountView(){
        let views: [UIView] = loopsBack.values.map{return $0} + allPosesPanelElements
        for view in views{
            view.frame.origin.x -= countView.frame.minX
            view.frame.origin.y -= countView.frame.minY
            countView.addSubview(view)
            
            UIView.animate(withDuration: 0.3) {
                view.center.x = self.countView.frame.width / 2
                view.center.y = self.countView.frame.height / 2
                view.frame.size.width = 0
                view.alpha = 0
            }
        }
    }
    private func setAllViewBack(backView: UIView?){
        let views: [UIView] = loopsBack.values.map{return $0} + allPosesPanelElements
        for view in views{
            view.frame.origin.x += countView.frame.minX
            view.frame.origin.y += countView.frame.minY
            backView?.addSubview(view)
            
            UIView.animate(withDuration: 0.3) {
                view.frame.size.width = ParentElements.rootSize.width * 0.65 / 3
                view.alpha = 1
            }
        }
    }
    
    @objc private func panAction(recognizer: UIPanGestureRecognizer){
        guard let view = recognizer.view else {return}
        switch recognizer.state {
        case .changed:
            
            if start{
                let speed = recognizer.translation(in: view)
                
                view.center.x += speed.x
                view.center.y += speed.y
                
                recognizer.setTranslation(CGPoint.zero, in: view)
                self.draging?(view, true)
            }
        default: break
        }
    }
}

extension AllPosesPanelLoop: UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
