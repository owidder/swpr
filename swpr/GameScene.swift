//
//  GameScene.swift
//  swpr
//
//  Created by Oliver Widder on 21.09.25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    private var circle: SKShapeNode?
    private var touchStartPoint: CGPoint?
    private var isCircleActive = false
    private var totalSides = 0
    private var currentPolygonSides = 0
    private var sumLabel: SKLabelNode?

    override func didMove(to view: SKView) {
        print("didMove called - setting up scene")
        backgroundColor = .black
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        setupSumLabel()
        spawnNewCircle()
    }

    func setupSumLabel() {
        sumLabel = SKLabelNode(text: "Total Sides: 0")
        if let sumLabel = sumLabel {
            sumLabel.fontName = "Arial-BoldMT"
            sumLabel.fontSize = 24
            sumLabel.fontColor = .white
            sumLabel.position = CGPoint(x: size.width / 2, y: 50)
            addChild(sumLabel)
        }
    }

    func updateSumLabel() {
        sumLabel?.text = "Total Sides: \(totalSides)"
    }

    func spawnNewCircle() {
        circle?.removeFromParent()

        let size: CGFloat = size.width * 0.8
        let sides = Int.random(in: 3...9)
        let path = CGMutablePath()
        let radius = size * 0.4

        for i in 0..<sides {
            let angle = (CGFloat(i) * 2.0 * CGFloat.pi) / CGFloat(sides) - CGFloat.pi / 2
            let x = radius * cos(angle)
            let y = radius * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        circle = SKShapeNode(path: path)

        if let circle = circle {
            circle.fillColor = .systemBlue
            circle.strokeColor = .white
            circle.lineWidth = 3

            circle.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
            circle.setScale(0.0)
            circle.alpha = 0.0

            circle.physicsBody = SKPhysicsBody(polygonFrom: path)

            circle.physicsBody?.mass = 1.0
            circle.physicsBody?.linearDamping = 0.8
            circle.physicsBody?.angularDamping = 0.5
            circle.physicsBody?.affectedByGravity = false

            addChild(circle)

            let scaleAction = SKAction.scale(to: 1.0, duration: 0.6)
            scaleAction.timingMode = .easeOut

            let fadeAction = SKAction.fadeIn(withDuration: 0.4)

            let rotateAction = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 0.6)

            let animationGroup = SKAction.group([scaleAction, fadeAction, rotateAction])

            currentPolygonSides = sides
            print("Spawned polygon with \(sides) sides")

            circle.run(animationGroup)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.isCircleActive = true
                print("Circle is now active and ready for swiping")
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isCircleActive else { return }
        touchStartPoint = touch.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let startPoint = touchStartPoint,
              isCircleActive,
              let circle = circle else { return }

        let currentPoint = touch.location(in: self)
        let deltaX = currentPoint.x - startPoint.x
        let deltaY = currentPoint.y - startPoint.y

        let dragForce = CGVector(dx: deltaX * 15, dy: deltaY * 15)
        circle.physicsBody?.applyForce(dragForce)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let startPoint = touchStartPoint,
              isCircleActive,
              let circle = circle else { return }

        let endPoint = touch.location(in: self)
        let deltaX = endPoint.x - startPoint.x
        let deltaY = endPoint.y - startPoint.y
        let swipeThreshold: CGFloat = 100

        let swipeDistance = sqrt(deltaX * deltaX + deltaY * deltaY)

        if swipeDistance > swipeThreshold {
            let swipeDirection = CGVector(dx: deltaX, dy: deltaY)
            let normalizedDirection = CGVector(
                dx: swipeDirection.dx / swipeDistance,
                dy: swipeDirection.dy / swipeDistance
            )

            let swipeForce = CGVector(
                dx: normalizedDirection.dx * 800,
                dy: normalizedDirection.dy * 800
            )

            circle.physicsBody?.applyImpulse(swipeForce)
        }

        touchStartPoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartPoint = nil
    }

    override func update(_ currentTime: TimeInterval) {
        if let circle = circle {
            let circlePosition = circle.position

            let leftBoundary = -10.0
            let rightBoundary = size.width + 10.0

            if circlePosition.x < leftBoundary {
                print("Polygon swiped LEFT at position \(circlePosition.x), isCircleActive: \(isCircleActive)")
                if isCircleActive {
                    isCircleActive = false
                    totalSides += currentPolygonSides
                    print("Added \(currentPolygonSides) sides. Total now: \(totalSides)")
                    updateSumLabel()
                    spawnNewCircle()
                }
            } else if circlePosition.x > rightBoundary {
                print("Polygon swiped RIGHT at position \(circlePosition.x), isCircleActive: \(isCircleActive)")
                if isCircleActive {
                    isCircleActive = false
                    totalSides -= currentPolygonSides
                    print("Subtracted \(currentPolygonSides) sides. Total now: \(totalSides)")
                    updateSumLabel()
                    spawnNewCircle()
                }
            }
        }
    }
}
