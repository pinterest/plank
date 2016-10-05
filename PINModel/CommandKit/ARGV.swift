public enum ParameterType {
    case Argument, Option, Flag
}

open class ARGV {

    let originalArgs: [String]
    open var arguments = [String]()
    open var options = [String: String]()
    open var flags = [String: Bool]()

    public init(_ args: [String]) {
        originalArgs = args

        for arg in originalArgs {
            switch parameterType(arg) {
            case .Argument:
                arguments.append(arg)
            case .Option:
                let (key, value) = optionParameter(arg)
                options[key] = value
            case .Flag:
                let (key, value) = flagParameter(arg)
                flags[key] = value
            }
        }
    }

    open func shift() -> String? {
        if arguments.count > 0 {
            return arguments.remove(at: 0)
        } else {
            return nil
        }
    }

    open func option(_ name: String) -> String? {
        return options.removeValue(forKey: name)
    }

    open func flag(_ name: String) -> Bool? {
        return flags.removeValue(forKey: name)
    }

    fileprivate func parameterType(_ arg: String) -> ParameterType {
        if arg.hasPrefix("--") {
            if arg.characters.contains("=") {
                return .Option
            } else {
                return .Flag
            }
        } else {
            return .Argument
        }
    }

    fileprivate func optionParameter(_ arg: String) -> (key: String, value: String) {
        let argument = arg.substring(from: arg.characters.index(arg.startIndex, offsetBy: 2))
        let components = argument.characters.split(whereSeparator: { $0 == "=" }).map { String($0) }
        assert(components.count == 2)
        return (components[0], components[1])
    }

    fileprivate func flagParameter(_ arg: String) -> (key: String, value: Bool) {
        if arg.hasPrefix("--no-") {
            return (arg.substring(from: arg.characters.index(arg.startIndex, offsetBy: 5)), false)
        } else {
            return (arg.substring(from: arg.characters.index(arg.startIndex, offsetBy: 2)), true)
        }
    }
}
