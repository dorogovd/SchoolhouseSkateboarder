//
//  GameScene.swift
//  SchoolhouseSkateboarder
//
//  Created by Dmitrii Dorogov on 12.04.2023.
//

import SpriteKit

class GameScene: SKScene {
    
    var bricks = [SKSpriteNode]() // массив со всеми секциями тротуара
    var brickSize = CGSize.zero // размер сеций тротуара
    var scrollSpeed: CGFloat = 5.0 // скорость движения тротуара
    var gravitySpeed: CGFloat = 1.5 // скорость гравитации
    var lastUpdateTime: TimeInterval? // время последнего вызова для метода обновления
    
    let skater = Skater(imageNamed: "skater.png") // создаём героя скейтбордистку
    
    override func didMove(to view: SKView) { // вызывается при запуске (только 1 раз)
        
        anchorPoint = CGPoint.zero
        
        let background = SKSpriteNode(imageNamed: "background.png") // создаем фоновый спрайт background
        let xMid = frame.midX
        let yMid = frame.midY
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background) // addChild - дочерний спрайт , добавляем фон
        resetSkater()
        addChild(skater) // добавляем героя
        
        let tapMethod = #selector(GameScene.handleTap(tapGesture:)) // обработка нажатия
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod) // распознаватель жестов
        view.addGestureRecognizer(tapGesture)
    }
        
        func resetSkater() { // начальное положение героя
            let skaterX = frame.midX / 2.0
            let skaterY = skater.frame.height / 2.0 + 64.0
            skater.position = CGPoint(x: skaterX, y: skaterY)
            skater.zPosition = 10
            skater.minimumY = skaterY
        }
    
    func spawnBrick (atPosition position: CGPoint) -> SKSpriteNode {
        let brick = SKSpriteNode(imageNamed: "sidewalk") // создаем спрайт тротуара
        brick.position = position
        brick.zPosition = 8
        addChild(brick)
        brickSize = brick.size // обновляем размер brickSize
        bricks.append(brick) // добавляем новую тротуарную секцию к массиву
        return brick
    }
    
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {
        var farthestRightBrickX: CGFloat = 0.0
        
        for brick in bricks {
            
            let newX = brick.position.x - currentScrollAmount
            
            if newX < -brickSize.width { // удаляем секцию, если она сместилась за пределы экрана
                brick.removeFromParent()
                
                if let brickIndex = bricks.firstIndex(of: brick) {
                    bricks.remove(at: brickIndex)
                }
            } else {
                brick.position = CGPoint(x: newX, y: brick.position.y) // обновляем положение секции
                if brick.position.x > farthestRightBrickX { // обновляем положение самой правой секции
                    farthestRightBrickX = brick.position.x
                }
            }
        }
        while farthestRightBrickX < frame.width { // постоянное заполнение экрана секциями тротуара
            var brickX = farthestRightBrickX + brickSize.width + 1.0
            let brickY = brickSize.height / 2.0
            let randomNumber = arc4random_uniform(99) // рандомные выбоины
            
            if randomNumber < 5 { // 5% шанс на возникновение разрыва
                let gap = 20.0 * scrollSpeed
                brickX += gap
            }
            
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            farthestRightBrickX = newBrick.position.x
        }
    }
    
    func updateSkater() {
        if skater.isOnGround {
            let velocityY = skater.velocity.y - gravitySpeed
            skater.velocity = CGPoint(x: skater.velocity.x, y: velocityY)
            let newSkaterY: CGFloat = skater.position.y + skater.velocity.y
            skater.position = CGPoint(x: skater.position.x, y: newSkaterY)
            
            if skater.position.y < skater.minimumY {
                skater.position.y = skater.minimumY
                skater.velocity = CGPoint.zero
                skater.isOnGround = true
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        var elapsedTime: TimeInterval = 0.0 // прошедшее время
        if let lastTimeStamp = lastUpdateTime { // последняя временная ветка
            elapsedTime = currentTime - lastTimeStamp
        }
        lastUpdateTime = currentTime
        let expectedElapsedTime: TimeInterval = 1.0 / 60.0 // ожидаемое время между вызовами
        let scrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime) // корректировка перемещения
        let currentScrollAmount = scrollSpeed * scrollAdjustment
        updateBricks(withScrollAmount: currentScrollAmount) // обновление положений секций
        updateSkater() // вызываем метод
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        if skater.isOnGround { // прыжок если герой на земле
            skater.velocity = CGPoint(x: 0.0, y: skater.jumpSpeed) // скорость героя
            skater.isOnGround = false // герой после прыжка уже не на земле
        }
    }
}
