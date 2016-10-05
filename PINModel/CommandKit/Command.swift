open class Command {
    open let name: String
    open let description: String

    public init(_ name: String, _ description: String) {
        self.name = name
        self.description = description
    }

    open func run(_ arguments: ARGV) {}

    open func run(_ manager: Manager, arguments: ARGV) {
        run(arguments)
    }
}

open class ClosureCommand: Command {
    public typealias ClosureType = (ARGV) -> ()
    let handler: ClosureType

    public init(name: String, description: String, handler: @escaping ClosureType) {
        self.handler = handler
        super.init(name, description)
    }

    open override func run(_ arguments: ARGV) {
        self.handler(arguments)
    }
}
