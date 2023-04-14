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
}
