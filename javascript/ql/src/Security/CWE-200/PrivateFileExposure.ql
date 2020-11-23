/**
 * @name Exposure of private files
 * @description Exposing a node_modules folder, or the project folder to the public, can cause exposure
 *              of private information.
 * @kind problem
 * @problem.severity warning
 * @id js/exposure-of-private-files
 * @tags security
 *       external/cwe/cwe-200
 * @precision high
 */

import javascript

/**
 * Holds if `folder` is a node_modules folder, and at most 1 subdirectory down.
 */
bindingset[folder]
predicate isNodeModuleFolder(string folder) {
  folder.regexpMatch("(\\.?\\.?/)*node_modules(/|(/[a-zA-Z@_-]+/?))?")
}

/**
 * Get a data-flow node that represents a path to the node_modules folder represented by the string-literal `path`.
 */
DataFlow::Node getANodeModulePath(string path) {
  result.getStringValue() = path and
  isNodeModuleFolder(path)
  or
  exists(DataFlow::CallNode resolve |
    resolve = DataFlow::moduleMember("path", ["resolve", "join"]).getACall()
  |
    result = resolve and
    resolve.getLastArgument() = getANodeModulePath(path)
  )
  or
  exists(StringOps::ConcatenationRoot root | root = result |
    root.getLastLeaf() = getANodeModulePath(path)
  )
  or
  result.getAPredecessor() = getANodeModulePath(path) // local data-flow
  or
  exists(string base, string folder |
    path = base + folder and
    folder.regexpMatch("(/)?[a-zA-Z@_-]+/?") and
    base.regexpMatch("(\\.?\\.?/)*node_modules(/)?") // node_modules, without any sub-folders.
  |
    exists(StringOps::ConcatenationRoot root | root = result |
      root.getNumOperand() = 2 and
      root.getFirstLeaf() = getANodeModulePath(base) and
      root.getLastLeaf().getStringValue() = folder
    )
    or
    exists(DataFlow::CallNode resolve |
      resolve = DataFlow::moduleMember("path", ["resolve", "join"]).getACall()
    |
      result = resolve and
      resolve.getNumArgument() = 2 and
      resolve.getArgument(0) = getANodeModulePath(path) and
      resolve.getArgument(1).mayHaveStringValue(folder)
    )
  )
}

/**
 * Gets a folder that contains a `package.json` file.
 */
pragma[noinline]
Folder getAPackageJSONFolder() { result = any(PackageJSON json).getFile().getParentContainer() }

/**
 * Gets a reference to `dirname`, the home folder, the current working folder, or the root folder.
 * All of these might cause information to be leaked.
 *
 * For `dirname` that can happen if there is a `package.json` file in the same folder.
 * It is assumed that the presence of a `package.json` file means that a `node_modules` folder can also exist.
 *
 * For the root/home/working folder, they contain so much information that they must leak information somehow (e.g. ssh keys in the `~/.ssh` folder).
 */
DataFlow::Node getALeakingFolder(string description) {
  exists(ModuleScope ms | result.asExpr() = ms.getVariable("__dirname").getAnAccess()) and
  result.getFile().getParentContainer() = getAPackageJSONFolder() and
  (
    if result.getFile().getParentContainer().getRelativePath().trim() != ""
    then description = "the folder " + result.getFile().getParentContainer().getRelativePath()
    else description = "a folder"
  )
  or
  result = DataFlow::moduleImport("os").getAMemberCall("homedir") and
  description = "the home folder"
  or
  result.mayHaveStringValue("/") and
  description = "the root folder"
  or
  result.getStringValue() = [".", "./"] and
  description = "the current working folder"
  or
  result.getAPredecessor() = getALeakingFolder(description)
  or
  exists(StringOps::ConcatenationRoot root | root = result |
    root.getNumOperand() = 2 and
    root.getOperand(0) = getALeakingFolder(description) and
    root.getOperand(1).getStringValue() = "/"
  )
}

/**
 * Gets a data-flow node that represents a path to the private folder `path`.
 */
DataFlow::Node getAPrivateFolderPath(string description) {
  exists(string path |
    result = getANodeModulePath(path) and description = "the folder \"" + path + "\""
  )
  or
  result = getALeakingFolder(description)
}

/**
 * Gest a call that serves the folder `path` to the public.
 */
DataFlow::CallNode servesAPrivateFolder(string description) {
  result = DataFlow::moduleMember(["express", "connect"], "static").getACall() and
  result.getArgument(0) = getAPrivateFolderPath(description)
  or
  result = DataFlow::moduleImport("serve-static").getACall() and
  result.getArgument(0) = getAPrivateFolderPath(description)
}

from Express::RouteSetup setup, string path
where
  setup.isUseCall() and
  setup.getArgument([0 .. 1]) = servesAPrivateFolder(path).getEnclosingExpr()
select setup, "Serves " + path + ", which can contain private information."
