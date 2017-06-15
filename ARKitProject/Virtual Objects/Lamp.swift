import Foundation

class Lamp: VirtualObject {
    
    override init() {
        super.init(modelName: "lamp", fileExtension: "scn", thumbImageFilename: "vase", title: "Vase")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


