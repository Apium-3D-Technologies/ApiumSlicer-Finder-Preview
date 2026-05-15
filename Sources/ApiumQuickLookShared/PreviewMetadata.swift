import CoreGraphics

public struct PreviewMetadata {
    public var previewImage: CGImage?
    public var printer: String?
    public var projectVersion: String?
    public var materialType: String?
    public var nozzleDiameter: String?
    public var nozzleTemperature: String?
    public var bedTemperature: String?
    public var layerHeight: String?
    public var perimeters: String?
    public var infillPattern: String?
    public var infillDensity: String?
    public var printTime: String?
    public var isApiumFile: Bool

    public init(
        previewImage: CGImage? = nil,
        printer: String? = nil,
        projectVersion: String? = nil,
        materialType: String? = nil,
        nozzleDiameter: String? = nil,
        nozzleTemperature: String? = nil,
        bedTemperature: String? = nil,
        layerHeight: String? = nil,
        perimeters: String? = nil,
        infillPattern: String? = nil,
        infillDensity: String? = nil,
        printTime: String? = nil,
        isApiumFile: Bool = false
    ) {
        self.previewImage = previewImage
        self.printer = printer
        self.projectVersion = projectVersion
        self.materialType = materialType
        self.nozzleDiameter = nozzleDiameter
        self.nozzleTemperature = nozzleTemperature
        self.bedTemperature = bedTemperature
        self.layerHeight = layerHeight
        self.perimeters = perimeters
        self.infillPattern = infillPattern
        self.infillDensity = infillDensity
        self.printTime = printTime
        self.isApiumFile = isApiumFile
    }
}
