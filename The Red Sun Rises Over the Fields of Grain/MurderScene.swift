//
//  MurderScene.swift
//  The Red Sun Rises Over the Fields of Grain
//
//  Created by Charlie Imhoff on 4/24/15.
//  Copyright (c) 2015 Silo Games. All rights reserved.
//

import SpriteKit

class MurderScene: SKScene {
	
	enum MurderMoment {
		case HouseInDistance
		case HouseUpClose
		case Window
		case Pitchfork
		case DoorClosed
		case DoorOpened
		case Stabs
	}
	
	var currentMoment : MurderMoment
	var currentMomentNode : SKNode?
	var stabs : Int = 0
	var inTransition : Bool = false
	let worldLightingBitmask : UInt32 = 0x1 << 1
	
    //Init Scene here
    override init(size: CGSize) {
		currentMoment = .HouseInDistance
        super.init(size: size)
		currentMomentNode = getHouseInTheDistanceMoment()
		self.addChild(currentMomentNode!)
    }
	
	func transitionToMoment(nextMoment: MurderMoment) {
		if inTransition {
			return	//wait your damn turn
		}
		
		var nextMomentNode : SKNode
		switch nextMoment {
		case .HouseInDistance:
			nextMomentNode = getHouseInTheDistanceMoment()
		case .HouseUpClose:
			nextMomentNode = getHouseUpCloseMoment()
		case .Window:
			nextMomentNode = getWindowMoment()
		case .Pitchfork:
			nextMomentNode = getPitchforkGrabMoment()
		case .DoorClosed:
			nextMomentNode = getDoorClosedMoment()
		case .DoorOpened:
			nextMomentNode = getDoorOpenMoment()
		case .Stabs:
			nextMomentNode = getStabMoment()
		}
		
		//anim to next moment
		inTransition = true
		let fadeOutAndRemove = SKAction.sequence([SKAction.fadeOutWithDuration(1), SKAction.removeFromParent()])
		currentMomentNode?.runAction(fadeOutAndRemove) {
			//onCompletion:
			self.inTransition = false
		}
		
		nextMomentNode.alpha = 0
		self.addChild(nextMomentNode)
		let fadeIn = SKAction.fadeInWithDuration(1)
		nextMomentNode.runAction(fadeIn)
		currentMoment = nextMoment
		currentMomentNode = nextMomentNode
	}
    
    // MARK: Moments (not quite scenes!)
    func getHouseInTheDistanceMoment() -> SKNode {
        let houseInTheDistanceMoment = SKNode()
        
        let background = SKSpriteNode(imageNamed: "BackgroundNight")
        background.position = CGPoint(x: size.width/2, y:size.height/2)
        background.size.height = size.height
        houseInTheDistanceMoment.addChild(background)
		
		let pointLight = SKLightNode()
		pointLight.lightColor = SKColor.whiteColor()
		pointLight.categoryBitMask = worldLightingBitmask
		pointLight.position = CGPoint(x: size.width/2, y: size.height/2)
		houseInTheDistanceMoment.addChild(pointLight)
		
		let sparkedBacking = SKSpriteNode(imageNamed: "BackgroundNightLightning")
		sparkedBacking.position = CGPoint(x: size.width/2, y: size.height/2)
		sparkedBacking.size.height = size.height
		sparkedBacking.size.width = size.width * 4
		houseInTheDistanceMoment.addChild(sparkedBacking)
		let sparks = self.getSparkLayerForSparkedBackground(sparkedBacking)
		houseInTheDistanceMoment.addChild(sparks)
        
        let ground = SKSpriteNode(imageNamed: "GroundNight")
        ground.size = CGSize(width: size.width * 2, height: 300)
        ground.position = CGPoint(x: size.width/2, y: 0)
		ground.zPosition = 1
		ground.lightingBitMask = worldLightingBitmask
        
        let house = SKSpriteNode(imageNamed: "House")
        house.name = "distant house"
        house.setScale(3)
		house.zPosition = 1
        house.position = CGPoint(x: size.width - 20, y: ground.size.height/2)
		house.lightingBitMask = worldLightingBitmask
        
        house.runAction(self.getBlinkAction())
		
		houseInTheDistanceMoment.addChild(self.getRainLayer())
        houseInTheDistanceMoment.addChild(ground)
        houseInTheDistanceMoment.addChild(house)
		
        return houseInTheDistanceMoment
    }
	
	func getRainLayer() -> SKNode {
		let rainLayer = SKNode()
		rainLayer.position = CGPoint(x: size.width/2, y: self.size.height * 1.1)
		
		let wait = SKAction.waitForDuration(0.2)
		let dropRainDropRandomly = SKAction.runBlock { () -> Void in
			//add a drop
			let drop = SKSpriteNode(imageNamed: "Raindrop")
			drop.setScale(0.5)
			let xPos = CGFloat(arc4random_uniform(UInt32(self.size.width)))-300
			drop.position = CGPoint(x: xPos, y: 0)
			drop.zRotation = 0.185
			drop.physicsBody = SKPhysicsBody(circleOfRadius: 2)	//so it drops
			rainLayer.addChild(drop)
			drop.physicsBody?.applyForce(CGVector(dx: 2, dy: 0))
		}
		rainLayer.runAction(SKAction.repeatActionForever(SKAction.sequence([wait,dropRainDropRandomly])))
		rainLayer.zPosition = 0
		
		return rainLayer
	}
	
	func getSparkLayerForSparkedBackground(backing:SKNode) -> SKNode {
		let spark = SKLightNode()
		spark.lightColor = SKColor.whiteColor()
		spark.categoryBitMask = worldLightingBitmask
		spark.falloff = 0.3	//big area
		spark.position = CGPoint(x: size.width/2, y: size.height/2)
		
		//hide both spark layer and the backing
		spark.enabled = false
		backing.alpha = 0
		
		let wait = SKAction.waitForDuration(1.2)
		let shortWait = SKAction.waitForDuration(0.4)
		let longWait = SKAction.waitForDuration(2)
		let flash = SKAction.runBlock { () -> Void in
			spark.enabled = true
		}
		let show = SKAction.runBlock { () -> Void in
			backing.alpha = 1
		}
		let frameBreak = SKAction.waitForDuration(0.06)
		let muzzle = SKAction.runBlock { () -> Void in
			spark.enabled = false
		}
		let hide = SKAction.runBlock { () -> Void in
			backing.alpha = 0
		}
		let shabang = SKAction.sequence([flash,frameBreak,muzzle])
		let showbang = SKAction.sequence([show,frameBreak,hide])
		let shaseq = SKAction.sequence([wait,shabang,shortWait,shabang,wait,shabang,longWait,shabang])
		let showseq = SKAction.sequence([wait,showbang,shortWait,showbang,wait,showbang,longWait,showbang])
		let shaloop = SKAction.repeatActionForever(shaseq)
		let showloop = SKAction.repeatActionForever(showseq)
		spark.runAction(shaloop)
		backing.runAction(showloop)
		
		return spark
	}
	
    func getBlinkAction(color: SKColor = SKColor.grayColor()) -> SKAction {
        let colorize = SKAction.colorizeWithColor(color, colorBlendFactor: 0.5, duration: 0.6)
        let colorizeReturn = SKAction.colorizeWithColorBlendFactor(0.0, duration: 0.6)
        let blink = SKAction.repeatActionForever(SKAction.sequence([colorize, colorizeReturn]))
        
        return blink
    }
    
    func getHouseUpCloseMoment() -> SKNode {
        let houseUpCloseMoment = SKNode()
        
        let background = SKSpriteNode(imageNamed: "BackgroundNight")
        background.position = CGPoint(x: size.width/2, y:size.height/2)
        background.size.height = size.height
        background.size.width = size.width * 2
        houseUpCloseMoment.addChild(background)
		
		let pointLight = SKLightNode()
		pointLight.lightColor = SKColor.whiteColor()
		pointLight.categoryBitMask = worldLightingBitmask
		pointLight.falloff = 0.5
		pointLight.position = CGPoint(x: size.width/2, y: size.height)
		houseUpCloseMoment.addChild(pointLight)
		
		let sparkedBacking = SKSpriteNode(imageNamed: "BackgroundNightLightning")
		sparkedBacking.position = CGPoint(x: size.width/2, y: size.height)
		sparkedBacking.size.height = size.height
		sparkedBacking.size.width = size.width * 4
		houseUpCloseMoment.addChild(sparkedBacking)
		let sparks = self.getSparkLayerForSparkedBackground(sparkedBacking)
		self.addChild(sparks)
		
        let ground = SKSpriteNode(imageNamed: "GroundNight")
        ground.size = CGSize(width: size.width, height: 250)
        ground.position = CGPoint(x: size.width/2, y: 125)
		ground.lightingBitMask = worldLightingBitmask
		ground.shadowedBitMask = worldLightingBitmask
		ground.zPosition = 1
        
        let house = SKSpriteNode(imageNamed: "House")
        house.name = "closer house"
        house.setScale(4)
		house.zPosition = 1
		house.lightingBitMask = worldLightingBitmask
		house.shadowCastBitMask = worldLightingBitmask
        house.position = CGPoint(x: size.width/2, y: ground.size.height)
        
        house.runAction(self.getBlinkAction())
		
		houseUpCloseMoment.addChild(self.getRainLayer())
        houseUpCloseMoment.addChild(ground)
        houseUpCloseMoment.addChild(house)
		
        return houseUpCloseMoment
    }
    
    func getWindowMoment() -> SKNode {
        let windowMoment = SKNode()
        windowMoment.name = "window moment"
        
        let backdrop = SKSpriteNode(imageNamed: "WindowView")
        backdrop.position = CGPoint(x: size.width/2, y:size.height/2)
        backdrop.size = CGSize(width: size.width, height: size.height)
        
        windowMoment.addChild(backdrop)
        
        let bed = SKSpriteNode(imageNamed: "Bed")
        bed.name = "bed"
        bed.setScale(4)
        bed.position = CGPoint(x: size.width/2 - 10, y:size.height/2)
        
        let bedPosition1 = bed.position
        let bedPosition2 = CGPoint(x: size.width/2 - 20, y:size.height/2)
        
        let moveToPosition2 = SKAction.moveTo(bedPosition2, duration: 0.1)
        let waitABit = SKAction.waitForDuration(1)
        let moveToPosition1 = SKAction.moveTo(bedPosition1, duration: 0.1)
        let bedVibrate = SKAction.repeatActionForever(SKAction.sequence([moveToPosition2, waitABit, moveToPosition1, waitABit]))

        bed.runAction(bedVibrate)
        
        windowMoment.addChild(bed)
        
        return windowMoment
    }
    
    func getPitchforkGrabMoment() -> SKNode {
        let pitchforkGrabMoment = SKNode()
        
        let background = SKSpriteNode(imageNamed: "GroundNight")
        background.position = CGPoint(x: size.width/2, y:size.height/2)
        background.size.height = size.height * 3
        background.size.width = size.width * 3
        background.runAction(self.getBlinkAction(color: SKColor.redColor()))
        pitchforkGrabMoment.addChild(background)
        
        let pitchfork = SKSpriteNode(imageNamed: "Pitchfork")
        pitchfork.name = "pitchfork"
        pitchfork.position = CGPoint(x: size.width/2, y:size.height/2)
        pitchfork.setScale(7)
        pitchforkGrabMoment.addChild(pitchfork)
        
        let 💪 = SKSpriteNode(imageNamed: "Reachingarm") // EMOJI VARIABLE YO! (for the burly arm that grabs the pitchfork)
        💪.position = CGPoint(x: -25, y: -25)
        💪.name = "burly arm"
        💪.setScale(4)
        pitchforkGrabMoment.addChild(💪)
        
        return pitchforkGrabMoment
        
    }
    
    func grabPitchfork() {
        let 💪 = self.childNodeWithName("//burly arm")
        let pitchfork = self.childNodeWithName("//pitchfork")
        
        let destinationPoint = pitchfork!.position
        let initialPoint = 💪!.position
        
        let moveTo = SKAction.moveTo(destinationPoint, duration: 1.0)
        💪!.runAction(moveTo) {
            //on completion:
            let moveBack = SKAction.moveTo(initialPoint, duration: 0.75)
            💪!.runAction(moveBack)
			pitchfork!.runAction(moveBack) {
				//on completion:
				self.transitionToMoment(.DoorClosed)
			}
        }
        
    }
    
    func getDoorClosedMoment() -> SKNode {
        let doorClosedMoment = SKNode()
        doorClosedMoment.name = "door closed"
        
        let backdrop = SKSpriteNode(imageNamed: "DoorClosed")
        backdrop.position = CGPoint(x: size.width/2, y:size.height/2)
        backdrop.size = CGSize(width: size.width, height: size.height)
        
        doorClosedMoment.addChild(backdrop)
        
        return doorClosedMoment
    }

    
    func getDoorOpenMoment() -> SKNode {
        let doorOpenMoment = SKNode()
        doorOpenMoment.name = "door open"
        
        let backdrop = SKSpriteNode(imageNamed: "DoorOpen")
        backdrop.position = CGPoint(x: size.width/2, y:size.height/2)
        backdrop.size = CGSize(width: size.width, height: size.height)
        
        doorOpenMoment.addChild(backdrop)
        
        return doorOpenMoment
    }
    
    func getStabMoment() -> SKNode {
        let stabMoment = SKNode()
        stabMoment.name = "stab moment"
        
        let fear = SKSpriteNode(imageNamed: "Fear")
        fear.name = "fear"
        fear.position = CGPoint(x: size.width/2, y:size.height/2)
        fear.size = CGSize(width: size.width, height: size.height)
        
        let ouch = SKSpriteNode(imageNamed: "Stabbing")
        ouch.name = "ouch"
        ouch.position = CGPoint(x: size.width/2, y:size.height/2)
        ouch.size = CGSize(width: size.width, height: size.height)
        
        ouch.alpha = 0.0 // dont show the blood quite yet, know wat i mean?
        
        stabMoment.addChild(fear)
        stabMoment.addChild(ouch)
        
        let pitchfork = SKSpriteNode(imageNamed: "PitchforkForward")
        pitchfork.position = CGPoint(x: size.width/2, y:size.height/2)
        pitchfork.name = "stabbing pitchfork"
        pitchfork.alpha = 0.0
        pitchfork.setScale(8)
        stabMoment.addChild(pitchfork)
        
        return stabMoment
    }
	
	//MARK: Interactions
    
    func stab() {
        let fear = self.childNodeWithName("//fear")
        let ouch = self.childNodeWithName("//ouch")
        let pitchfork = self.childNodeWithName("//stabbing pitchfork")
        
        let shrink = SKAction.scaleTo(4, duration: 0.3)
        let shiftDown = SKAction.moveToY(pitchfork!.position.y + 10, duration: 0.3)
        let stabIn = SKAction.sequence([shrink, shiftDown])
        
        let grow = SKAction.scaleTo(8, duration: 0.3)
        let shiftUp = SKAction.moveToY(pitchfork!.position.y - 10, duration: 0.3)
        let stabOut = SKAction.sequence([grow, shiftUp])
        
        pitchfork!.runAction(SKAction.fadeInWithDuration(0.4)){
            // on completion:
            pitchfork!.runAction(stabIn) {
                ouch!.runAction(SKAction.fadeInWithDuration(1))
                fear!.runAction(SKAction.fadeOutWithDuration(1.1))
                pitchfork!.runAction(stabOut)
            }
        }
		
		stabs++
		
		if let faderCurtain = self.childNodeWithName("faderCurtain") {
			faderCurtain.runAction(SKAction.fadeAlphaBy(+0.2, duration: 0.5))
		} else {
			let faderCurtain = SKShapeNode(rectOfSize: size)
			faderCurtain.name = "faderCurtain"
			faderCurtain.position = CGPoint(x: size.width/2, y: size.height/2)
			faderCurtain.fillColor = SKColor.blackColor()
			faderCurtain.strokeColor = SKColor.blackColor()
			faderCurtain.alpha = 0
			self.addChild(faderCurtain)
		}
		
		if stabs >= 7 {
			GameProfile.sharedInstance.committedMurder = true
			GameProfile.sharedInstance.saveToFile()
			let transition = SKTransition.crossFadeWithDuration(5)
			self.view?.presentScene(FarmScene(size: size), transition: transition)
		}
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        //touches
        for touch in touches {
			let location = (touch as! UITouch).locationInNode(self)
			switch currentMoment {
			case .HouseInDistance:
				for touched in self.nodesAtPoint(location) {
					if let node = touched as? SKNode {
						if node.name == "distant house" {
							self.transitionToMoment(.HouseUpClose)
						}
					}
				}
			case .HouseUpClose:
				for touched in self.nodesAtPoint(location) {
					if let node = touched as? SKNode {
						if node.name == "closer house" {
							self.transitionToMoment(.Window)
						}
					}
				}
			case .Window:
				self.transitionToMoment(.Pitchfork)
			case .Pitchfork:
				for touched in self.nodesAtPoint(location) {
					if let node = touched as? SKNode {
						if node.name == "pitchfork" {
							self.grabPitchfork()
						}
					}
				}
			case .DoorClosed:
				self.transitionToMoment(.DoorOpened)
			case .DoorOpened:
				self.transitionToMoment(.Stabs)
			case .Stabs:
				self.stab()
			}
		}
    }

	
}
