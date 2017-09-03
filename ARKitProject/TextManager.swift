import Foundation
import ARKit

enum MessageType {
	case trackingStateEscalation
	case planeEstimation
	case contentPlacement
	case focusSquare
}

class TextManager {

	init(viewController: MainViewController) {
		self.viewController = viewController
	}

	func showMessage(_ text: String, autoHide: Bool = true) {
		messageHideTimer?.invalidate()

		viewController.messageLabel.text = text

		showHideMessage(hide: false, animated: true)

		if autoHide {
			let charCount = text.characters.count
			let displayDuration: TimeInterval = min(10, Double(charCount) / 15.0 + 1.0)
			messageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration,
			                                        repeats: false,
			                                        block: { [weak self] ( _ ) in
														self?.showHideMessage(hide: true, animated: true)
			})
		}
	}

	func showDebugMessage(_ message: String) {
		guard viewController.showDebugVisuals else {
			return
		}

		debugMessageHideTimer?.invalidate()

		viewController.debugMessageLabel.text = message

		showHideDebugMessage(hide: false, animated: true)

		let charCount = message.characters.count
		let displayDuration: TimeInterval = min(10, Double(charCount) / 15.0 + 1.0)
		debugMessageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration,
		                                             repeats: false,
		                                             block: { [weak self] ( _ ) in
														self?.showHideDebugMessage(hide: true, animated: true)
		})
	}

	var schedulingMessagesBlocked = false

	func scheduleMessage(_ text: String, inSeconds seconds: TimeInterval, messageType: MessageType) {
		// Do not schedule a new message if a feedback escalation alert is still on screen.
		guard !schedulingMessagesBlocked else {
			return
		}

		var timer: Timer?
		switch messageType {
		case .contentPlacement: timer = contentPlacementMessageTimer
		case .focusSquare: timer = focusSquareMessageTimer
		case .planeEstimation: timer = planeEstimationMessageTimer
		case .trackingStateEscalation: timer = trackingStateFeedbackEscalationTimer
		}

		if timer != nil {
			timer!.invalidate()
			timer = nil
		}
		timer = Timer.scheduledTimer(withTimeInterval: seconds,
		                             repeats: false,
		                             block: { [weak self] ( _ ) in
										self?.showMessage(text)
										timer?.invalidate()
										timer = nil
		})
		switch messageType {
		case .contentPlacement: contentPlacementMessageTimer = timer
		case .focusSquare: focusSquareMessageTimer = timer
		case .planeEstimation: planeEstimationMessageTimer = timer
		case .trackingStateEscalation: trackingStateFeedbackEscalationTimer = timer
		}
	}

	func showTrackingQualityInfo(for trackingState: ARCamera.TrackingState, autoHide: Bool) {
		showMessage(trackingState.presentationString, autoHide: autoHide)
	}

	func escalateFeedback(for trackingState: ARCamera.TrackingState, inSeconds seconds: TimeInterval) {
		if self.trackingStateFeedbackEscalationTimer != nil {
			self.trackingStateFeedbackEscalationTimer!.invalidate()
			self.trackingStateFeedbackEscalationTimer = nil
		}

		self.trackingStateFeedbackEscalationTimer = Timer.scheduledTimer(withTimeInterval: seconds,
		                                                                 repeats: false, block: { _ in
			self.trackingStateFeedbackEscalationTimer?.invalidate()
			self.trackingStateFeedbackEscalationTimer = nil
			self.schedulingMessagesBlocked = true
			var title = ""
			var message = ""
			switch trackingState {
			case .notAvailable:
				title = "Tracking status: Not available."
				message = "Tracking status has been unavailable for an extended time. Try resetting the session."
			case .limited(let reason):
				title = "Tracking status: Limited."
				message = "Tracking status has been limited for an extended time. "
				switch reason {
				case .excessiveMotion: message += "Try slowing down your movement, or reset the session."
				case .insufficientFeatures: message += "Try pointing at a flat surface, or reset the session."
                case .initializing: message += "Initializing."
                }
			case .normal: break
			}

			let restartAction = UIAlertAction(title: "Reset", style: .destructive, handler: { _ in
				self.viewController.restartExperience(self)
				self.schedulingMessagesBlocked = false
			})
			let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
				self.schedulingMessagesBlocked = false
			})
			self.showAlert(title: title, message: message, actions: [restartAction, okAction])
		})
	}

	func cancelScheduledMessage(forType messageType: MessageType) {
		var timer: Timer?
		switch messageType {
		case .contentPlacement: timer = contentPlacementMessageTimer
		case .focusSquare: timer = focusSquareMessageTimer
		case .planeEstimation: timer = planeEstimationMessageTimer
		case .trackingStateEscalation: timer = trackingStateFeedbackEscalationTimer
		}

		if timer != nil {
			timer!.invalidate()
			timer = nil
		}
	}

	func cancelAllScheduledMessages() {
		cancelScheduledMessage(forType: .contentPlacement)
		cancelScheduledMessage(forType: .planeEstimation)
		cancelScheduledMessage(forType: .trackingStateEscalation)
		cancelScheduledMessage(forType: .focusSquare)
	}

	var alertController: UIAlertController?

	func showAlert(title: String, message: String, actions: [UIAlertAction]? = nil) {
		alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		if let actions = actions {
			for action in actions {
				alertController!.addAction(action)
			}
		} else {
			alertController!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		}
		self.viewController.present(alertController!, animated: true, completion: nil)
	}

	func dismissPresentedAlert() {
		alertController?.dismiss(animated: true, completion: nil)
	}

	let blurEffectViewTag = 100

	func blurBackground() {
		let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
		let blurEffectView = UIVisualEffectView(effect: blurEffect)
		blurEffectView.frame = viewController.view.bounds
		blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		blurEffectView.tag = blurEffectViewTag
		viewController.view.addSubview(blurEffectView)
	}

	func unblurBackground() {
		for view in viewController.view.subviews {
			if let blurView = view as? UIVisualEffectView, blurView.tag == blurEffectViewTag {
				blurView.removeFromSuperview()
			}
		}
	}

	// MARK: - Private
	private var viewController: MainViewController!

	// Timers for hiding regular and debug messages
	private var messageHideTimer: Timer?
	private var debugMessageHideTimer: Timer?

	// Timers for showing scheduled messages
	private var focusSquareMessageTimer: Timer?
	private var planeEstimationMessageTimer: Timer?
	private var contentPlacementMessageTimer: Timer?

	// Timer for tracking state escalation
	private var trackingStateFeedbackEscalationTimer: Timer?

	private func showHideMessage(hide: Bool, animated: Bool) {
		if !animated {
			viewController.messageLabel.isHidden = hide
			return
		}

		UIView.animate(withDuration: 0.2,
		               delay: 0,
		               options: [.allowUserInteraction, .beginFromCurrentState],
		               animations: {
						self.viewController.messageLabel.isHidden = hide
						self.updateMessagePanelVisibility()
		}, completion: nil)
	}

	private func showHideDebugMessage(hide: Bool, animated: Bool) {
		if !animated {
			viewController.debugMessageLabel.isHidden = hide
			return
		}

		UIView.animate(withDuration: 0.2,
		               delay: 0,
		               options: [.allowUserInteraction, .beginFromCurrentState],
		               animations: {
						self.viewController.debugMessageLabel.isHidden = hide
						self.updateMessagePanelVisibility()
		}, completion: nil)
	}

	private func updateMessagePanelVisibility() {
		// Show and hide the panel depending whether there is something to show.
		viewController.messagePanel.isHidden = viewController.messageLabel.isHidden &&
			viewController.debugMessageLabel.isHidden &&
			viewController.featurePointCountLabel.isHidden
	}
}
