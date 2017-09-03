import Foundation

class Chair: VirtualObject {

	override init() {
		super.init(modelName: "chair", fileExtension: "scn", thumbImageFilename: "chair", title: "Chair")
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
