import Foundation

/// Protocol that defines that the element can return a plist element that represents itself.
protocol PlistSerializable {
    func plistKeyAndValue(proj: PBXProj) -> (key: CommentedString, value: PlistValue)
    var multiline: Bool { get }
}

extension PlistSerializable {
    var multiline: Bool { return true }
}

/// Writes your PBXProj files
class PBXProjWriter {
    
    var indent: UInt = 0
    var output: String = ""
    var multiline: Bool = true

    func write(proj: PBXProj) -> String {
        writeUtf8()
        writeNewLine()
        writeDictionaryStart()
        write(dictionaryKey: "archiveVersion", dictionaryValue: .string(CommentedString("\(proj.archiveVersion)")))
        write(dictionaryKey: "classes", dictionaryValue: .array([]))
        write(dictionaryKey: "objectVersion", dictionaryValue: .string(CommentedString("\(proj.objectVersion)")))
        writeIndent()
        write(string: "objects = {")
        increaseIndent()
        writeNewLine()
        write(section: "PBXAggregateTarget", proj: proj, object: proj.aggregateTargets)
        write(section: "PBXBuildFile", proj: proj, object: proj.buildFiles)
        write(section: "PBXContainerItemProxy", proj: proj, object: proj.containerItemProxies)
        write(section: "PBXCopyFilesBuildPhase", proj: proj, object: proj.copyFilesBuildPhases)
        write(section: "PBXFileElement", proj: proj, object: proj.fileElements)
        write(section: "PBXFileReference", proj: proj, object: proj.fileReferences)
        write(section: "PBXFrameworksBuildPhase", proj: proj, object: proj.frameworksBuildPhases)
        write(section: "PBXGroup", proj: proj, object: proj.groups)
        write(section: "PBXHeadersBuildPhase", proj: proj, object: proj.headersBuildPhases)
        write(section: "PBXNativeTarget", proj: proj, object: proj.nativeTargets)
        write(section: "PBXProject", proj: proj, object: proj.projects)
        write(section: "PBXResourcesBuildPhase", proj: proj, object: proj.resourcesBuildPhases)
        write(section: "PBXShellScriptBuildPhase", proj: proj, object: proj.shellScriptBuildPhases)
        write(section: "PBXSourcesBuildPhase", proj: proj, object: proj.sourcesBuildPhases)
        write(section: "PBXTargetDependency", proj: proj, object: proj.targetDependencies)
        write(section: "PBXVariantGroup", proj: proj, object: proj.variantGroups)
        write(section: "XCBuildConfiguration", proj: proj, object: proj.buildConfigurations)
        write(section: "XCConfigurationList", proj: proj, object: proj.configurationLists)
        decreaseIndent()
        writeIndent()
        write(string: "};")
        writeNewLine()
        write(dictionaryKey: "rootObject",
              dictionaryValue: .string(CommentedString(proj.rootObject,
                                                                   comment: "Project object")))
        writeDictionaryEnd()
        writeNewLine()
        return output
    }
    
    // MARK: - Private
    
    private func writeUtf8() {
        output.append("// !$*UTF8*$!")
    }
    
    private func writeNewLine() {
        if multiline {
            output.append("\n")
        } else {
            output.append(" ")
        }
    }
    
    private func write(value: PlistValue) {
        switch value {
        case .array(let array):
            write(array: array)
        case .dictionary(let dictionary):
            write(dictionary: dictionary)
        case .string(let commentedString):
            write(commentedString: commentedString)
        }
    }
    
    private func write(commentedString: CommentedString) {
        write(string: commentedString.validString)
        if let comment = commentedString.comment {
            write(string: " ")
            write(comment: comment)
        }
    }
    
    private func write(string: String) {
        output.append(string)
    }
    
    private func write(comment: String) {
        output.append("/* \(comment) */")
    }
    
    private func write<T: Referenceable & PlistSerializable>(section: String, proj: PBXProj, object: [T]) {
        if object.count == 0 { return }
        writeNewLine()
        write(string: "/* Begin \(section) section */")
        writeNewLine()
        object
            .sorted(by: { $0.0.reference < $0.1.reference})
            .forEach { (serializable) in
            let element = serializable.plistKeyAndValue(proj: proj)
            write(dictionaryKey: element.key, dictionaryValue: element.value, multiline: serializable.multiline)
        }
        write(string: "/* End \(section) section */")
        writeNewLine()
    }
    
    private func write(dictionary: [CommentedString: PlistValue], newLines: Bool = true) {
        writeDictionaryStart()
        dictionary.sorted(by: { (left, right) -> Bool in
                if left.key == "isa" {
                    return true
                } else if right.key == "isa" {
                    return false
                } else {
                    return left.key.string < right.key.string
                }
            })
            .forEach({ write(dictionaryKey: $0.key, dictionaryValue: $0.value, multiline: self.multiline) })
        writeDictionaryEnd()
    }
    
    private func write(dictionaryKey: CommentedString, dictionaryValue: PlistValue, multiline: Bool = true) {
        writeIndent()
        let beforeMultiline = self.multiline
        self.multiline = multiline
        write(commentedString: dictionaryKey)
        output.append(" = ")
        write(value: dictionaryValue)
        output.append(";")
        self.multiline = beforeMultiline
        writeNewLine()
    }
    
    private func writeDictionaryStart() {
        output.append("{")
        if multiline { writeNewLine() }
        increaseIndent()
    }
    
    private func writeDictionaryEnd() {
        decreaseIndent()
        writeIndent()
        output.append("}")
    }
    
    private func write(array: [PlistValue]) {
        writeArrayStart()
        array.forEach { write(arrayValue: $0) }
        writeArrayEnd()
    }
    
    private func write(arrayValue: PlistValue) {
        writeIndent()
        write(value: arrayValue)
        output.append(",")
        writeNewLine()
    }
    
    private func writeArrayStart() {
        output.append("(")
        if multiline { writeNewLine() }
        increaseIndent()
    }
    
    private func writeArrayEnd() {
        decreaseIndent()
        writeIndent()
        output.append(")")
    }
    
    private func writeIndent() {
        if multiline {
            output.append(String(repeating: "\t", count: Int(indent)))
        }
    }
    
    private func increaseIndent() {
        indent += 1
    }
    
    private func decreaseIndent() {
        indent -= 1
    }
    
}
