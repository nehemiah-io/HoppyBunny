import SpriteKit
class GameScene: SKScene, SKPhysicsContactDelegate{
    var gameState: GameSceneState = .Active
    
    enum GameSceneState {
        case Active, GameOver
    }
    
    
    
    var hero: SKSpriteNode!
    var scrollLayer: SKNode!
    var sinceTouch : CFTimeInterval = 0
    var obstacleLayer: SKNode!
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    let scrollSpeed: CGFloat = 160
    var spawnTimer: CFTimeInterval = 0
    
    /* UI Connections */
    var buttonRestart: MSButtonNode!
    var scoreLabel: SKLabelNode!
    var points = 0
    
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        /*recursive node search for 'hero' (child of reference node) */
        hero = self.childNodeWithName("//hero") as! SKSpriteNode
        /* Set reference to scroll layer node */
        scrollLayer = self.childNodeWithName("scrollLayer")
        //set reference to obstacle layer node
        obstacleLayer = self.childNodeWithName("ObstacleLayer")
        buttonRestart = self.childNodeWithName("buttonRestart") as! MSButtonNode
        /* Set physics contact delegate */
        physicsWorld.contactDelegate = self
        buttonRestart.state = .Hidden
        
        buttonRestart.selectedHandler = {
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFill
            
            /* Restart game scene */
            skView.presentScene(scene)
            
            
            
        }
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        /* Play SFX */
        let flapSFX = SKAction.playSoundFileNamed("Yo", waitForCompletion: false)
        self.runAction(flapSFX)
        
        //apply vertical impulse
        hero.physicsBody?.applyImpulse(CGVectorMake(0, 250))
        /* Apply subtle rotation */
        hero.physicsBody?.applyAngularImpulse(-0.3)
        
        /* Reset touch timer */
        sinceTouch = 0
        /* Setup restart button selection handler */
        /* Hide restart button */
        // hero.physicsBody?.velocity = CGVectorMake(0, 0)
        
    }
    
    
    override func update(currentTime: CFTimeInterval) {
        if gameState != .Active { return }
        /* Called before each frame is rendered */
        /* Grab current velocity */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        /* Check and cap vertical velocity */
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
            /* Apply falling rotation */
            if sinceTouch > 0.1 {
                let impulse = -20000 * fixedDelta
                hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
            }
        }
        /* Clamp rotation */
        hero.zRotation.clamp(CGFloat(-20).degreesToRadians(),CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(-2, 2)
        
        /* Update last touch timer */
        sinceTouch+=fixedDelta
        /* Process world scrolling */
        scrollWorld()
        /* Process obstacles */
        spawnTimer+=fixedDelta
        
        updateObstacles()
        
    }
    func scrollWorld() {
        /* Scroll World */
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        /* Loop through scroll layer nodes */
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let groundPosition = scrollLayer.convertPoint(ground.position, toNode: self)
            
            /* Check if ground sprite has left the scene */
            if groundPosition.x <= -ground.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPointMake( (self.size.width / 2) + ground.size.width, groundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                ground.position = self.convertPoint(newPosition, toNode: scrollLayer)
                
                
            }
        }
    }
    func updateObstacles() {
        /* Update Obstacles */
        
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convertPoint(obstacle.position, toNode: self)
            
            print("obstacle position")
            
            /* Check if obstacle has left the scene */
            if obstaclePosition.x <= 0 {
                
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
                /* Time to add a new obstacle? */
                if spawnTimer >= 1.5 {
                    
                    /* Create a new obstacle reference object using our obstacle resource */
                    let resourcePath = NSBundle.mainBundle().pathForResource("Obstacle", ofType: "sks")
                    let newObstacle = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
                    obstacleLayer.addChild(newObstacle)
                    
                    /* Generate new obstacle position, start just outside screen and with a random y value */
                    let randomPosition = CGPointMake(352, CGFloat.random(min: 234, max: 382))
                    
                    /* Convert new node position back to obstacle layer space */
                    newObstacle.position = self.convertPoint(randomPosition, toNode: obstacleLayer)
                    
                    // Reset spawn timer
                    spawnTimer = 0
                    
                    
                }
            }
            
        }
    }
    func didBeginContact(contact: SKPhysicsContact) {
        /* Ensure only called while game running */
        if gameState != .Active { return }
        
        /* Hero touches anything, game over */
        
        /* Change game state to game over */
        gameState = .GameOver
        
        let death = SKAction.playSoundFileNamed("Aw Man", waitForCompletion: false)
        self.runAction(death)
        
        /* Stop any new angular velocity being applied */
        hero.physicsBody?.allowsRotation = false
        
        /* Reset angular velocity */
        hero.physicsBody?.angularVelocity = 0
        
        /* Stop hero flapping animation */
        hero.removeAllActions()
        let heroDeath = SKAction.runBlock({
            
            /* Put our hero face down in the dirt */
            self.hero.zRotation = CGFloat(-90).degreesToRadians()
            /* Stop hero from colliding with anything else */
            self.hero.physicsBody?.collisionBitMask = 0
            
        })
        
        /* Run action */
        hero.runAction(heroDeath)
        
        /* Show restart button */
         buttonRestart.state = .Active
        /* Load the shake action resource */
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        
        /* Loop through all nodes  */
        for node in self.children {
            
            /* Apply effect each ground node */
            node.runAction(shakeScene)
        }
        print("TODO: Add contact code")
    }
    
}

