open class Manager {
    open var commands = [Command]()

    public init() {}

    lazy var defaultCommand: Command = {
        ClosureCommand(name: "", description: "The default command") { argv in
            print("No command specified")
        }
    }()

    open func register(_ name: String, _ description: String, handler: @escaping ClosureCommand.ClosureType) {
        register(ClosureCommand(name: name, description: description, handler: handler))
    }

    open func register(_ command: Command) {
        commands.append(command)
    }

    open func registerDefault(_ handler: @escaping ClosureCommand.ClosureType) {
        defaultCommand = ClosureCommand(name: "", description: "The default command", handler: handler)
    }

    /// Finds a command by name
    open func findCommand(_ name: String) -> Command? {
        return commands.filter { $0.name == name }.first
    }

    /// Finds the command to execute based on input arguments
    open func findCommand(_ argv: ARGV) -> Command? {
        let args = argv.arguments
        // try to find the deepest command name matching the arguments
        for depth in Array((1...args.count).reversed()) {
            let slicedArgs = args[0 ..< depth]
            let maybeCommandName = slicedArgs.joined(separator: " ")

            if let command = findCommand(maybeCommandName) {
                argv.arguments = Array(args[depth ..< args.count]) // strip the command name from arguments
                return command
            }
        }

        return nil
    }

    /// Runs the correct command based on input arguments
    open func run(arguments: [String]? = nil) {
        let argv: ARGV

        if let arguments = arguments {
            argv = ARGV(arguments)
        } else {
            var arguments = CommandLine.arguments
            arguments.remove(at: 0)
            argv = ARGV(arguments)
        }

        if argv.arguments.count > 0 {
            if let command = findCommand(argv) {
                command.run(self, arguments: argv)
            } else {
                print("Unknown command.")
            }
        } else {
            defaultCommand.run(argv)
        }
    }
}
