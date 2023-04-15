//
//  Skater.swift
//  SchoolhouseSkateboarder
//
//  Created by Dmitrii Dorogov on 13.04.2023.
//

import SpriteKit

class Skater: SKSpriteNode {
    var velocity = CGPoint.zero
    var minimumY: CGFloat = 0.0
    var jumpSpeed: CGFloat = 20.0
    var isOnGround = true
    
    func setupPhysicsBody() {
        
        if let skaterTexture = texture {
            physicsBody = SKPhysicsBody(texture: skaterTexture, size: size)
            physicsBody?.isDynamic = true
            physicsBody?.density = 6.0
            physicsBody?.allowsRotation = true
            physicsBody?.angularDamping = 1.0
            
            physicsBody?.categoryBitMask = PhysicsCategory.skater
            physicsBody?.collisionBitMask = PhysicsCategory.brick // на героя влияют столкновения с телом brick
            physicsBody?.contactTestBitMask = PhysicsCategory.brick | PhysicsCategory.gem // герой контактирует с телами brick и gem
        }
    }
}
