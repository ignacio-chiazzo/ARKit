import Foundation
import ARKit

class HitTestVisualization {

	var minHitDistance: CGFloat = 0.01
	var maxHitDistance: CGFloat = 4.5
	var xAxisSamples = 6
	var yAxisSamples = 6
	var fieldOfViewWidth: CGFloat = 0.8
	var fieldOfViewHeight: CGFloat = 0.8

	let hitTestPointParentNode = SCNNode()
	var hitTestPoints = [SCNNode]()
	var hitTestFeaturePoints = [SCNNode]()

	let sceneView: ARSCNView
	let overlayView = LineOverlayView()

	init(sceneView: ARSCNView) {
		self.sceneView = sceneView
		overlayView.backgroundColor = UIColor.clear
		overlayView.frame = sceneView.frame
		sceneView.addSubview(overlayView)
	}

	deinit {
		hitTestPointParentNode.removeFromParentNode()
		overlayView.removeFromSuperview()
	}

	func setupHitTestResultPoints() {

		if hitTestPointParentNode.parent == nil {
			self.sceneView.scene.rootNode.addChildNode(hitTestPointParentNode)
		}

		while hitTestPoints.count < xAxisSamples * yAxisSamples {
			hitTestPoints.append(createCrossNode(size: 0.01, color:UIColor.blue, horizontal:false))
			hitTestFeaturePoints.append(createCrossNode(size: 0.01, color:UIColor.yellow, horizontal:true))
		}
	}

	func render() {

		// Remove any old nodes,
		hitTestPointParentNode.childNodes.forEach {
			$0.removeFromParentNode()
			$0.geometry = nil
		}

		// Ensure there are enough nodes that can be rendered.
		setupHitTestResultPoints()

		let xAxisOffset: CGFloat = (1 - fieldOfViewWidth) / 2
		let yAxisOffset: CGFloat = (1 - fieldOfViewHeight) / 2

		let stepX = fieldOfViewWidth / CGFloat(xAxisSamples - 1)
		let stepY = fieldOfViewHeight / CGFloat(yAxisSamples - 1)

		var screenSpaceX: CGFloat = xAxisOffset
		var screenSpaceY: CGFloat = yAxisOffset

		guard let currentFrame = sceneView.session.currentFrame else {
			return
		}

		for x in 0 ..< xAxisSamples {

			screenSpaceX = xAxisOffset + (CGFloat(x) * stepX)

			for y in 0 ..< yAxisSamples {

				screenSpaceY = yAxisOffset + (CGFloat(y) * stepY)

				let hitTestPoint = hitTestPoints[(x * yAxisSamples) + y]

				let hitTestResults = currentFrame.hitTest(CGPoint(x: screenSpaceX, y: screenSpaceY), types: .featurePoint)

				if hitTestResults.isEmpty {
					hitTestPoint.isHidden = true
					continue
				}

				hitTestPoint.isHidden = false

				let result = hitTestResults[0]

				// Place a blue cross, oriented parallel to the screen at the place of the hit.
				let hitTestPointPosition = SCNVector3.positionFromTransform(result.worldTransform)

				hitTestPoint.position = hitTestPointPosition
				hitTestPointParentNode.addChildNode(hitTestPoint)

				// Subtract the result's local position from the world position
			    // to get the position of the feature which the ray hit.
				let localPointPosition = SCNVector3.positionFromTransform(result.localTransform)
				let featurePosition = hitTestPointPosition - localPointPosition

				let hitTestFeaturePoint = hitTestFeaturePoints[(x * yAxisSamples) + y]

				hitTestFeaturePoint.position = featurePosition
				hitTestPointParentNode.addChildNode(hitTestFeaturePoint)

				// Create a 2D line between the feature point and the hit test result to be drawn on the overlay view.
				overlayView.addLine(start: screenPoint(for: hitTestPointPosition), end: screenPoint(for: featurePosition))

			}
		}
		// Draw the 2D lines
		DispatchQueue.main.async {
			self.overlayView.setNeedsDisplay()
		}
	}

	private func screenPoint(for point: SCNVector3) -> CGPoint {
		let projectedPoint = sceneView.projectPoint(point)
		return CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))
	}
}

class LineOverlayView: UIView {

	struct Line {
		var start: CGPoint
		var end: CGPoint
	}

	var lines = [Line]()

	func addLine(start: CGPoint, end: CGPoint) {
		lines.append(Line(start: start, end: end))
	}

	override func draw(_ rect: CGRect) {
		super.draw(rect)
		for line in lines {
			let path = UIBezierPath()
			path.move(to: line.start)
			path.addLine(to: line.end)
			path.close()
			UIColor.red.set()
			path.stroke()
			path.fill()
		}
		lines.removeAll()
	}
}
