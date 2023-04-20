//
//  GameScene.swift
//  SchoolhouseSkateboarder
//
//  Created by Dmitrii Dorogov on 12.04.2023.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory { // физические категории для определения возможности сталкивания и контактирования объектов
    static let skater: UInt32 = 0x1 << 0 // UInt32 - беззнаковый тип для физических категорий
    static let brick: UInt32 = 0x1 << 1
    static let gem: UInt32 = 0x1 << 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    enum BrickLevel: CGFloat { // перечисление полоджений тротуарных секций по оси Y
        case low = 0.0 // низкие секции (на земле)
        case high = 100.0 // высокие секции (повыше)
    }
    
    enum GameState {
        case notRunning
        case running
    }
    
    var bricks = [SKSpriteNode]() // массив со всеми секциями тротуара
    var gems = [SKSpriteNode]() // массив алмазов
    var brickSize = CGSize.zero // размер сеций тротуара
    var brickLevel = BrickLevel.low // текущий уровень тротуарной секции (определяет уровень для новых секций, переменная меняется, но начинаем с low)
    var gameState = GameState.notRunning // текущее состояние игры
    var scrollSpeed: CGFloat = 5.0 // скорость движения тротуара
    let startingScrollSpeed: CGFloat = 5.0 // начальная скорость героя
    var gravitySpeed: CGFloat = 1.5 // скорость гравитации
    
    var score: Int = 0
    var highScore: Int = 0
    var lastScoreUpdateTime: TimeInterval = 0.0 // время обновления отображения надписей
    
    var lastUpdateTime: TimeInterval? // время последнего вызова для метода обновления
    
    let skater = Skater(imageNamed: "skater.png") // создаём героя скейтбордистку
    
    override func didMove(to view: SKView) { // вызывается при запуске (только 1 раз)
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        physicsWorld.contactDelegate = self
        
        anchorPoint = CGPoint.zero
        
        let background = SKSpriteNode(imageNamed: "background.png") // создаем фоновый спрайт background
        let xMid = frame.midX
        let yMid = frame.midY
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background) // addChild - дочерний спрайт , добавляем фон
        setupLabels()
        
        skater.setupPhysicsBody() // настраиваем свойства героя
        addChild(skater) // добавляем героя
        
        let tapMethod = #selector(GameScene.handleTap(tapGesture:)) // добавляем распознаватель нажатий
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod) // распознаватель жестов
        view.addGestureRecognizer(tapGesture)
        
        startGame()
    //    view.isUserInteractionEnabled = true
    }
        
        func resetSkater() { // начальное положение героя (skater init position)
            let skaterX = frame.midX / 2.0
            let skaterY = skater.frame.height / 2.0 + 64.0
            skater.position = CGPoint(x: skaterX, y: skaterY)
            skater.zPosition = 10
            skater.minimumY = skaterY
            
            skater.zRotation = 0.0 // zRotation - как сильно объект вращается вправо и влево
            skater.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0) // свойство чтобы остановить героя после прыжка или падения
            skater.physicsBody?.angularVelocity = 0.0 // angularVelocity - скорость вращения
        }
    
    func setupLabels() { // настроить надписи
        
        let scoreTextLabel: SKLabelNode = SKLabelNode(text: "score") // текст
        scoreTextLabel.position = CGPoint(x: 14.0, y: frame.size.height - 20.0) // положение надписи по осям х (14) и у (высота сцены - 20)
        scoreTextLabel.horizontalAlignmentMode = .left // горизонтальное выравнивание
        scoreTextLabel.fontName = "Courier-Bold" // вибираем шрифт
        scoreTextLabel.fontSize = 14.0 // размер шрифта
        scoreTextLabel.zPosition = 20
        addChild(scoreTextLabel) // подключаем надпись к сцене
        
        let scoreLabel: SKLabelNode = SKLabelNode(text: "0")
        scoreLabel.position = CGPoint(x: 14.0, y: frame.size.height - 40.0)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.fontName = "Courier-Bold"
        scoreLabel.fontSize = 18.0
        scoreLabel.name = "scoreLabel"
        scoreLabel.zPosition = 20
        addChild(scoreLabel)
        
        let highScoreTextLabel: SKLabelNode = SKLabelNode(text: "best score")
        highScoreTextLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 20.0)
        highScoreTextLabel.horizontalAlignmentMode = .right
        highScoreTextLabel.fontName = "Courier-Bold"
        highScoreTextLabel.fontSize = 14.0
        highScoreTextLabel.zPosition = 20
        addChild(highScoreTextLabel)
        
        let highScoreLabel: SKLabelNode = SKLabelNode(text: "0")
        highScoreLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 40.0)
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.fontName = "Courier-Bold"
        highScoreLabel.fontSize = 18.0
        highScoreLabel.name = "highScoreLabel"
        highScoreLabel.zPosition = 20
        addChild(highScoreLabel)
    }
    
    func updateScoreLabelText() { // обнровления лэйбла с кол-вом очков
        if let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode { // ищем дочерний узел сцены по названию "scoreLabel"
            scoreLabel.text = String(format: "%04d", score) // "%04d" - вид отображения очков (%-переменная, 4 цифры, d-целые числа
        }
    }
    
    func updateHighScoreLabelText() {
        if let highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode {
            highScoreLabel.text = String(format: "%04d", highScore)
        }
    }
    
    func startGame() {
        gameState = .running
        resetSkater() // герой в стартовом положении
        score = 0 // начальное значение очков
        scrollSpeed = startingScrollSpeed // scrollSpeed на начальной скорости
        brickLevel = .low
        lastUpdateTime = nil
        
        for brick in bricks { // удаляем все спрайты brick из сцены (из массива bricks)
            brick.removeFromParent()
        }
        bricks.removeAll(keepingCapacity: true)
        
        for gem in gems { // убираем старые алмазы из новой игры
            removeGem(gem)
        }
    }
    
    func gameOver() {
        gameState = .notRunning
        if score > highScore { // обновляем показатель highscore
            highScore = score
            updateHighScoreLabelText()
        }
        startGame()
    }
    
    func spawnBrick(atPosition position: CGPoint) -> SKSpriteNode {
        let brick = SKSpriteNode(imageNamed: "sidewalk") // create brick sprite
        brick.position = position
        brick.zPosition = 8
        addChild(brick) // add brick to scene
        brickSize = brick.size // обновляем размер brickSize
        bricks.append(brick) // добавляем новую тротуарную секцию к массиву
        
        let center = brick.centerRect.origin // настройка физического тела секции (центральная точка объекта "brick")
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size, center: center) // создание физ тела и присоединение к спрайту "brick"
        brick.physicsBody?.affectedByGravity = false // убираем влияние гравитации на тело "brick"
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
        brick.physicsBody?.collisionBitMask = 0 // значение сталкивания 0 чтобы секции brick не сталкивались с другими телами
        
        return brick
    }
    
    func spawnGem(atPosition position: CGPoint) {
        
        let gem = SKSpriteNode(imageNamed: "gem") // создаем спрайт алмаза и добавляем его к сцене
        gem.position = position
        gem.position = position
        gem.zPosition = 9 // позиция гема в слоях на сцене (перед фоном, но за героем)
        addChild(gem) // делаем gem дочерним объектом сцены
        gem.physicsBody = SKPhysicsBody(rectangleOf: gem.size, center: gem.centerRect.origin) // физические штуки алмаза
        gem.physicsBody?.categoryBitMask = PhysicsCategory.gem
        gem.physicsBody?.affectedByGravity = false
        
        gems.append(gem) // добавляем алмаз к массиву
    }
    
    func removeGem(_ gem: SKSpriteNode) {
        gem.removeFromParent()
        if let gemIndex = gems.firstIndex(of: gem) { // метод firstIndex возвращает опционал, поэтому используем конструкцию if let
            gems.remove(at: gemIndex) // удаляем гем из массива
        }
    }
    
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) { // вызывается перед отрисовкой каждого фрейма
        var farthestRightBrickX: CGFloat = 0.0
        
        for brick in bricks {
            let newX = brick.position.x - currentScrollAmount
            
            if newX < -brickSize.width { // удаляем секцию, если она сместилась за пределы экрана
                brick.removeFromParent()
                
                if let brickIndex = bricks.firstIndex(of: brick) {
                    bricks.remove(at: brickIndex)
                }
            } else {
                brick.position = CGPoint(x: newX, y: brick.position.y) // if brick is still on the screen: update his X
                if brick.position.x > farthestRightBrickX { // обновляем положение самой правой секции
                    farthestRightBrickX = brick.position.x
                }
            }
        }
        while farthestRightBrickX < frame.width { // постоянное заполнение экрана секциями тротуара
            var brickX = farthestRightBrickX + brickSize.width + 1.0
            let brickY = (brickSize.height / 2.0) + brickLevel.rawValue // устанавливается положение тротуаров по оси Y с учётом enum
            let randomNumber = arc4random_uniform(99) // рандомные выбоины
            
            if randomNumber < 2 && score > 10 { // 2% шанс на возникновение разрыва после 10 очков
                let gap = 20.0 * scrollSpeed
                brickX += gap
                
                let randomGemYAmount = CGFloat(arc4random_uniform(150))
                let newGemY = brickY + skater.size.height + randomGemYAmount // помещаем алмаз выше героя
                let newGemX = brickX - gap / 2.0 // помещаем алмаз в середину разрыва по оси Х
                
                spawnGem(atPosition: CGPoint(x: newGemX, y: newGemY))
            }
            
            else if randomNumber < 4 && score > 20 { // 2% шанс на изменение уровня секции после 20 очков
                if brickLevel == .high {
                    brickLevel = .low
                }
                else if brickLevel == .low {
                    brickLevel = .high
                }
            }
            
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            farthestRightBrickX = newBrick.position.x
    //        updateSkater() // вызываем метод
        }
    }
    
    func updateGems(withScrollAmount currentScrollAmount: CGFloat) {
        
        for gem in gems { // обновляем положение каждого алмаза (двигаем вместе с тротуаром)
            let thisGemX = gem.position.x - currentScrollAmount // расчитываем новое положение для гема
            gem.position = CGPoint(x: thisGemX, y: gem.position.y) // задаем новое значение position для гема
            
            if gem.position.x < 0.0 { // удаляем если гем убежал за границы экрана (х < 0)
                removeGem(gem)
            }
        }
    }
    
    func updateSkater() { // возвращение героя после прыжка
//        if !skater.isOnGround {
//            let velocityY = skater.velocity.y - gravitySpeed
//            skater.velocity = CGPoint(x: skater.velocity.x, y: velocityY)
//            let newSkaterY: CGFloat = skater.position.y + skater.velocity.y
//            skater.position = CGPoint(x: skater.position.x, y: newSkaterY)
//
//            if skater.position.y < skater.minimumY {
//                skater.position.y = skater.minimumY
//                skater.velocity = CGPoint.zero
//                skater.isOnGround = true
//            }
//        }
        if let velocityY = skater.physicsBody?.velocity.dy { // распаковываем скорость чтобы потом использовать
            if velocityY < -100.0 || velocityY > 100.0 { // определяем находится ли герой на земле
                skater.isOnGround = false // если скорость отрицательная по Y то герой не на земле (падает)
            }
        }
        // добавляем Bool переменные определяющие условия для завершения игры
        let isOffScreen = skater.position.y < 0.0 || skater.position.x < 0.0 // герой за пределами экрана
        let maxRotation = CGFloat(GLKMathDegreesToRadians(85.0)) // переводим радианы в градусы (определяем угол наклона героя)
        let isTippedOver = skater.zRotation > maxRotation || skater.zRotation < -maxRotation // герой опрокинулся
        
        if isOffScreen || isTippedOver {
            gameOver() // если хоть одно условие будет true то игра завершится
        }
    }
    
    func updateScore(withCurrentTime currentTime: TimeInterval) {
        // кол-во очков увеличивается по мере игры, счёт обновляется каждую секунду
        let elapsedTime = currentTime - lastScoreUpdateTime
        
        if elapsedTime > 1.0 { // увеличиваем кол-во очков
            
            score += Int(scrollSpeed)
            lastScoreUpdateTime = currentTime
            updateScoreLabelText()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        scrollSpeed += 0.01 // медленно увеличиваем скорость игры (увеличивается при каждом вызове update метода)
        
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
        updateSkater() // обновляем положение героя
        updateGems(withScrollAmount: currentScrollAmount) // обновляем положение гемов
        updateScore(withCurrentTime: currentTime) // обновление очков
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        if skater.isOnGround { // прыжок если герой на земле
//            skater.velocity = CGPoint(x: 0.0, y: skater.jumpSpeed) // скорость героя
//            skater.isOnGround = false // герой после прыжка уже не на земле
            skater.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 260.0))
        }
    }
    
    // MARK: - SKPhysicsContactDelegate Methods
    func didBegin(_ contact: SKPhysicsContact) { // проверяем есть ли контакт между героем и brick
        if contact.bodyA.categoryBitMask == PhysicsCategory.skater && contact.bodyB.categoryBitMask == PhysicsCategory.brick {
            skater.isOnGround = true
        }
        else if contact.bodyA.categoryBitMask == PhysicsCategory.skater && contact.bodyB.categoryBitMask == PhysicsCategory.gem {
            if let gem = contact.bodyB.node as? SKSpriteNode { // убираем алмаз тк герой его коснулся (преобразовываем тип свойства "node" SKNode в SKSpriteNode (нисходящее преобразование as?) чтобы можно было передать это свойство в метод "removeGem()"
                removeGem(gem)
                
                score += 50 // 50 очков за гем
                updateScoreLabelText()
            }
        }
    }
}
