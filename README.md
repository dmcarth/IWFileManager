# IWFileManager
A multi-threaded wrapper for NSFileManager, designed to make writing document-based iOS apps easier.

It was originally written as part of Ibsen.

## Building
IWFileManager is written in Swift 2.2 and requires Xcode 7 to run. No other dependencies are required. 

## Installation
Something fancier than copy-paste is on its way...

## Usage
For the sake of simplicity, IWFileManager functions are all performed by a singleton with access to its own private coordinationQueue.

```Swift
let fileManager = FileManager.sharedInstance
```

It provides a nice, Swifty interface for basic file operations, including move, rename, and delete.

```Swift
fileManager.move(itemAtURL: fileURL, intoDirectoryURL: directoryURL) { (newURL) in
	print("Item moved to: \(newURL)")
}

fileManager.rename(itemAtURL: fileURL, usingName: "New Name") { (newURL) in
	print("Item renamed to: \(newURL)")
}

fileManager.delete(itemAtURL: fileURL) { 
	print("Item deleted")
}
```

... and some less common, but dead useful, query functions.

```Swift
let directoryURL = fileManager.directoryURLByAppendingPath("") // Appends path to ~/Documents

let nodes = fileManager.deepDirectoryModel(forDirectoryURL: directoryURL)

for node in nodes {
	print(node)
}

// Prints: 
// Empty Folder (Folder)
// Test Folder (Folder)
// - Test File.txt (File)
// - Test File-1.text (File)
```

File conflicts are automatically avoided by renaming the new URL. 

### Creating Files
Also included are some convenient functions for initializing files and directories.

```Swift
fileManager.createEmptyTextFile(named: "Text File", inDirectoryURL: directoryURL) { (newURL) in
	print("UTF8 encoded file at: \(newURL)")
}

fileManager.createDirectory(named: "Folder", inDirectoryURL: directoryURL) { (newURL) in
	print("Empty folder at: \(newURL)")
}

fileManager.createTemplateProject(named: "Template", fromTemplateURL: templateURL, inDirectoryURL: directoryURL) { (newURL) in
	print("\(newURL) created from template")
}
```

### Error Handling
IWFileManager is designed to, whereever possilbe, fail gracefully and quietly. Callback functions will only be performed if the operation was succesful. Otherwise, the callback is ignored. This may be changed in the future.

## Tests
IWFileManager currently passes 100% of its tests. About 25% of those tests are too big.
