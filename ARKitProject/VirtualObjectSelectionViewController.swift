import UIKit

class VirtualObjectSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	private var tableView: UITableView!
	private var size: CGSize!
	weak var delegate: VirtualObjectSelectionViewControllerDelegate?

	init(size: CGSize) {
		super.init(nibName: nil, bundle: nil)
		self.size = size
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView = UITableView()
		tableView.frame = CGRect(origin: CGPoint.zero, size: self.size)
		tableView.dataSource = self
		tableView.delegate = self
		tableView.backgroundColor = UIColor.clear
		tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .light))
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		tableView.bounces = false

		self.preferredContentSize = self.size

		self.view.addSubview(tableView)
	}

	func getObject(index: Int) -> VirtualObject {
		switch index {
		case 0:
			return Candle()
		case 1:
			return Cup()
		case 2:
			return Vase()
		case 3:
			return Lamp()
		case 4:
			return Chair()
		default:
			return Cup()
		}
	}

	static let COUNT_OBJECTS = 5

	// MARK: - UITableViewDelegate
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		delegate?.virtualObjectSelectionViewController(self, object: getObject(index: indexPath.row))
		self.dismiss(animated: true, completion: nil)
	}

	// MARK: - UITableViewDataSource
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return VirtualObjectSelectionViewController.COUNT_OBJECTS
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell()
		let label = UILabel(frame: CGRect(x: 53, y: 10, width: 200, height: 30))
		let icon = UIImageView(frame: CGRect(x: 15, y: 10, width: 30, height: 30))

		cell.backgroundColor = UIColor.clear
		cell.selectionStyle = .none
		let vibrancyEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .extraLight))
		let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
		vibrancyView.frame = cell.contentView.frame
		cell.contentView.insertSubview(vibrancyView, at: 0)
		vibrancyView.contentView.addSubview(label)
		vibrancyView.contentView.addSubview(icon)

		// Fill up the cell with data from the object.
		let object = getObject(index: indexPath.row)
		var thumbnailImage = object.thumbImage!
		if let invertedImage = thumbnailImage.inverted() {
			thumbnailImage = invertedImage
		}
		label.text = object.title
		icon.image = thumbnailImage

		return cell
	}

	func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
		let cell = tableView.cellForRow(at: indexPath)
		cell?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
	}

	func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
		let cell = tableView.cellForRow(at: indexPath)
		cell?.backgroundColor = UIColor.clear
	}
}

// MARK: - VirtualObjectSelectionViewControllerDelegate
protocol VirtualObjectSelectionViewControllerDelegate: class {
	func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, object: VirtualObject)
}
