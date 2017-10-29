//
//  GameScene.swift
//  Save Christmas
//
//  Created by Keith Davis on 10/28/17.
//  Copyright © 2017 Keith Davis. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var snowfield: SKEmitterNode!
    var player: SKSpriteNode!
    var livesArray: [SKSpriteNode]!
    var gameTimer: Timer!
    var possiblePackages1 = ["package1", "package2", "tree1"]
    var possiblePackages2 = ["alien4", "alien5", "alien6"]
    var possiblePackages3 = ["alien7"]
    var possiblePackages4 = ["alien8", "alien9", "alien10"]
    let packageCategory: UInt32 = 0x1 << 1
    let photonTorpedoCategory: UInt32 = 0x1 << 0
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0
    var scoreLabel: SKLabelNode!
    var torpedoSound: SKAction!
    var explosionSound: SKAction!
    var loseSound: SKAction!
    var backgroundMusic: SKAudioNode!
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        
        if let musicURL = Bundle.main.url(forResource: "bells", withExtension: "wav") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
        
        torpedoSound = SKAction.playSoundFileNamed("torpedo.wav", waitForCompletion: false)
        explosionSound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
        loseSound = SKAction.playSoundFileNamed("lose.wav", waitForCompletion: false)
        
        addLives()
        
        snowfield = SKEmitterNode(fileNamed: "Snowfield")
        snowfield.position = CGPoint(x: 0, y: self.frame.height)
        snowfield.particlePositionRange = CGVector(dx: self.frame.width * 2, dy: self.frame.height)
        snowfield.advanceSimulationTime(10)
        self.addChild(snowfield)
        
        snowfield.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "santa")
        player.position = CGPoint(x: self.frame.size.width / 2, y: player.size.height / 2 + 20)
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: 100, y: self.frame.height - 60)
        scoreLabel.fontName = "GillSans-Bold"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = UIColor.purple
        score = 0
        
        self.addChild(scoreLabel)
        
        var timeInterval  = 0.75
        
        if UserDefaults.standard.bool(forKey: "hard") {
            timeInterval = 0.3
        }
        
        gameTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data: CMAccelerometerData?, error: Error?) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.7 + self.xAcceleration * 0.3
            }
        }
    }
    
    override func didSimulatePhysics() {
        super.didSimulatePhysics()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & packageCategory) != 0 {
                torpedoDidCollideWithPackage(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
    }
    
    func torpedoDidCollideWithPackage(torpedoNode: SKSpriteNode, alienNode: SKSpriteNode) {
        
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = alienNode.position
        self.addChild(explosion)
        self.run(explosionSound)
        
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
        
        score += 5
    }
    
    func addLives() {
        livesArray = [SKSpriteNode]()
        
        for live in 1 ... 3 {
            let liveNode = SKSpriteNode(imageNamed: "santa")
            liveNode.position = CGPoint(x: self.frame.width - CGFloat(4 - live) * liveNode.size.width, y: self.frame.height - 60)
            self.addChild(liveNode)
            livesArray.append(liveNode)
        }
    }
    
    @objc func addAlien() {
        var possibleAliens = [String]()
        
        if score >= 0 && score < 300 {
            possibleAliens = possiblePackages1
        } else if score >= 300 && score < 550 {
            possibleAliens = possiblePackages2
        } else if score >= 550 && score < 800 {
            possibleAliens = possiblePackages3
        } else {
            possibleAliens = possiblePackages4
        }
        
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        let randomAlienPosition = GKRandomDistribution(lowestValue: 10, highestValue: Int(self.frame.width) - 10)
        let position = CGFloat(randomAlienPosition.nextInt())
        alien.position = CGPoint(x: position, y: self.frame.size.height + alien.size.height)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        alien.physicsBody?.categoryBitMask = packageCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animationDuration: TimeInterval = 6
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -alien.size.height), duration: animationDuration))
        
        actionArray.append(SKAction.run {
            self.run(self.loseSound)
            
            if self.livesArray.count > 0 {
                let liveNode = self.livesArray.first
                liveNode!.removeFromParent()
                self.livesArray.removeFirst()
                
                if self.livesArray.count == 0 {
                    self.motionManager.stopAccelerometerUpdates()
                    
                    let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                    let menuScene = SKScene(fileNamed: "MenuScene") as! MenuScene
                    menuScene.scaleMode = .aspectFill
                    menuScene.score = self.score
                    
                    self.view?.presentScene(menuScene, transition: transition)
                }
            }
        })
        
        actionArray.append(SKAction.removeFromParent())
        alien.run(SKAction.sequence(actionArray))
    }
    
    func fireTorpedo() {
        self.run(torpedoSound)
        
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = packageCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedoNode)
        
        let animationDuration: TimeInterval = 0.3
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height + 10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        torpedoNode.run(SKAction.sequence(actionArray))
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        player.position.x += xAcceleration * 50
        
        if player.position.x < -20 {
            player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
        } else if player.position.x > self.size.width + 20 {
            player.position = CGPoint(x: -20, y: player.position.y)
        }
    }
}

