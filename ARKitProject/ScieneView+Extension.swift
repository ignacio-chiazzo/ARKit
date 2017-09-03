import ARKit
import Foundation
import SceneKit

extension ARSCNView {
	func setUp(viewController: MainViewController, session: ARSession) {
		delegate = viewController
		self.session = session
		antialiasingMode = .multisampling4X
		automaticallyUpdatesLighting = false
		preferredFramesPerSecond = 60
		contentScaleFactor = 1.3
		enableEnvironmentMapWithIntensity(25.0)
		if let camera = pointOfView?.camera {
			camera.wantsHDR = true
			camera.wantsExposureAdaptation = true
			camera.exposureOffset = -1
			camera.minimumExposure = -1
		}
	}

	func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
		if scene.lightingEnvironment.contents == nil {
			if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
				scene.lightingEnvironment.contents = environmentMap
			}
		}
		scene.lightingEnvironment.intensity = intensity
	}
}
