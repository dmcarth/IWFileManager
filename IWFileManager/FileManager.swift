//
//  FileManager.swift
//  IWFileManager
//
//  Created by Dylan McArthur on 8/18/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public class FileManager {
	
	// MARK: - Singleton
	
	public static let sharedManager: FileManager = {
		let fileManager = NSFileManager()
		let documentsDirectory = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
		
		let instance = FileManager(fileManager: fileManager, documentsDirectory: documentsDirectory)
		
		return instance
	}()
	
	private init(fileManager: NSFileManager, documentsDirectory: NSURL) {
		self.fileManager = fileManager
		self.documentsDirectoryURL = documentsDirectory
	}
	
	// MARK: - Properties
	
	public typealias Callback = (NSURL)->Void
	
	let fileManager: NSFileManager
	
	let documentsDirectoryURL: NSURL
	
	let coordinationQueue: NSOperationQueue = {
		let coordinationQueue = NSOperationQueue()
		
		coordinationQueue.name = "com.filmstoriescode.Ibsen.fileManager.coordinationQueue"
		
		return coordinationQueue
	}()
	
	// MARK: - Query Methods
	
	public func directoryURLByAppendingPath(path: String) -> NSURL {
		return documentsDirectoryURL.URLByAppendingPathComponent(path)
	}
	
	public func directoryModel(forDirectoryURL directoryURL: NSURL) -> [FileNode] {
		let files = try! fileManager.contentsOfDirectoryAtURL(directoryURL, includingPropertiesForKeys: [kCFURLContentModificationDateKey as String, kCFURLIsDirectoryKey as String], options: [])
		
		var model = [FileNode]()
		
		for file in files {
			var p: AnyObject?
			try! file.getResourceValue(&p, forKey: NSURLIsDirectoryKey)
			let isDirectory = p as! Bool
			
			let type: FileNodeType = (isDirectory) == true ? .Folder : .File
			let node = FileNode(url: file, type: type)
			
			model.append(node)
		}
		
		return model
	}
	
	public func deepDirectoryModel(forDirectoryURL directoryURL: NSURL) -> [FileNode] {
		var nodes = [FileNode]()
		
		let enumerator = fileManager.enumeratorAtURL(directoryURL, includingPropertiesForKeys: [NSURLIsDirectoryKey], options: .SkipsHiddenFiles, errorHandler: nil)
		
		while let fileURL = enumerator?.nextObject() as? NSURL {
			
			var p: AnyObject?
			try! fileURL.getResourceValue(&p, forKey: NSURLIsDirectoryKey)
			let isDirectory = p as! Bool
			
			var node: FileNode
			if isDirectory {
				node = FileNode(url: fileURL, type: .Folder)
			} else {
				node = FileNode(url: fileURL, type: .File)
			}
			node.level = enumerator!.level - 1
			
			nodes.append(node)
		}
		
		return nodes
	}
	
	// MARK: - File System Methods
	
	public func createEmptyTextFile(named fileName: String, inDirectoryURL directoryURL: NSURL, completion: Callback?) {
		let data = ("").dataUsingEncoding(NSUTF8StringEncoding)!
		
		coordinationQueue.addOperationWithBlock {
			let baseURL = directoryURL.URLByAppendingPathComponent((fileName as NSString).stringByDeletingPathExtension)
			
			var ext = (fileName as NSString).pathExtension
			if ext.isEmpty { ext = "md" }
			
			let target = self.availableFileForBaseURL(baseURL, ext: ext)
			
			let writeIntent = NSFileAccessIntent.writingIntentWithURL(target, options: [])
			
			NSFileCoordinator().coordinateAccessWithIntents([writeIntent], queue: self.coordinationQueue, byAccessor: { (error) in
				if error != nil {
					return
				}
				
				self.fileManager.createFileAtPath(writeIntent.URL.path!, contents: data, attributes: nil)
				
				NSOperationQueue.mainQueue().addOperationWithBlock({
					completion?(writeIntent.URL)
				})
			})
		}
	}
	
	public func createDirectory(named directoryName: String, inDirectoryURL directoryURL: NSURL, completion: Callback?) {
		
		coordinationQueue.addOperationWithBlock {
			let baseURL = directoryURL.URLByAppendingPathComponent(directoryName, isDirectory: true)
			
			let target = self.availableDirectoryForBaseURL(baseURL)
			
			let writeIntent = NSFileAccessIntent.writingIntentWithURL(target, options: [])
			
			NSFileCoordinator().coordinateAccessWithIntents([writeIntent], queue: self.coordinationQueue, byAccessor: { (error) in
				if error != nil {
					return
				}
				
				do {
					try self.fileManager.createDirectoryAtURL(writeIntent.URL, withIntermediateDirectories: true, attributes: nil)
					
					NSOperationQueue.mainQueue().addOperationWithBlock({
						completion?(writeIntent.URL)
					})
				} catch {
					fatalError("Unexpected error creating folder: \(error)")
				}
			})
		}
		
	}
	
	public func createTemplateProject(named templateName: String, fromTemplateURL templateURL: NSURL, inDirectoryURL directoryURL: NSURL, completion: Callback?) {
		
		coordinationQueue.addOperationWithBlock {
			let baseURL = directoryURL.URLByAppendingPathComponent(templateName, isDirectory: true)
			
			let target = self.availableDirectoryForBaseURL(baseURL)
			
			let readIntent = NSFileAccessIntent.readingIntentWithURL(templateURL, options: [])
			let writeIntent = NSFileAccessIntent.writingIntentWithURL(target, options: [])
			
			NSFileCoordinator().coordinateAccessWithIntents([readIntent, writeIntent], queue: self.coordinationQueue, byAccessor: { (error) in
				if error != nil {
					return
				}
				
				do {
					try self.fileManager.copyItemAtURL(readIntent.URL, toURL: writeIntent.URL)
					
					NSOperationQueue.mainQueue().addOperationWithBlock({
						completion?(writeIntent.URL)
					})
				} catch {
					fatalError("Unexpected error creating template project: \(error)")
				}
			})
		}
	}
	
	public func move(itemAtURL sourceURL: NSURL, intoDirectoryURL directoryURL: NSURL, completion: Callback?) {
		
		coordinationQueue.addOperationWithBlock {
			
			let isDirectory = self.checkPromisedURLIsDirectory(sourceURL)
			
			var target = NSURL()
			
			if isDirectory {
				let baseURL = directoryURL.URLByAppendingPathComponent(sourceURL.lastPathComponent!)
				
				target = self.availableDirectoryForBaseURL(baseURL)
			} else {
				let baseURL = directoryURL.URLByAppendingPathComponent((sourceURL.lastPathComponent! as NSString).stringByDeletingPathExtension)
				
				let ext = sourceURL.pathExtension!
				
				target = self.availableFileForBaseURL(baseURL, ext: ext)
			}
			
			let readIntent = NSFileAccessIntent.readingIntentWithURL(sourceURL, options: [])
			let writeIntent = NSFileAccessIntent.writingIntentWithURL(target, options: [])
			
			NSFileCoordinator().coordinateAccessWithIntents([readIntent, writeIntent], queue: self.coordinationQueue, byAccessor: { (error) in
				if error != nil {
					return
				}
				
				do {
					try self.fileManager.moveItemAtURL(readIntent.URL, toURL: writeIntent.URL)
					
					NSOperationQueue.mainQueue().addOperationWithBlock({
						completion?(writeIntent.URL)
					})
				} catch {
					fatalError("Unexpected error moving: \(error)")
				}
			})
		}
		
	}
	
	public func rename(itemAtURL sourceURL: NSURL, usingName name: String, completion: Callback?) {
		
		coordinationQueue.addOperationWithBlock {
			
			let isDirectory = self.checkPromisedURLIsDirectory(sourceURL)
			
			var target = NSURL()
			
			if isDirectory {
				let baseURL = sourceURL.URLByDeletingLastPathComponent!.URLByAppendingPathComponent(name)
				
				target = self.availableDirectoryForBaseURL(baseURL)
			} else {
				let baseURL = sourceURL.URLByDeletingLastPathComponent!.URLByAppendingPathComponent((name as NSString).stringByDeletingPathExtension)
				
				var ext = (name as NSString).pathExtension
				if ext.isEmpty {
					if let sourceExt = sourceURL.pathExtension { ext = sourceExt }
				}
				
				target = self.availableFileForBaseURL(baseURL, ext: ext)
			}
			
			let readIntent = NSFileAccessIntent.readingIntentWithURL(sourceURL, options: [])
			let writeIntent = NSFileAccessIntent.writingIntentWithURL(target, options: [])
			
			NSFileCoordinator().coordinateAccessWithIntents([readIntent, writeIntent], queue: self.coordinationQueue, byAccessor: { (error) in
				if error != nil {
					return
				}
				
				do {
					try self.fileManager.moveItemAtURL(readIntent.URL, toURL: writeIntent.URL)
					
					NSOperationQueue.mainQueue().addOperationWithBlock({
						completion?(writeIntent.URL)
					})
				} catch {
					fatalError("Unexpected error renaming: \(error)")
				}
			})
		}
		
	}
	
	public func delete(itemAtURL url: NSURL, completion: ()->Void) {
		
		coordinationQueue.addOperationWithBlock {
			let writeIntent = NSFileAccessIntent.writingIntentWithURL(url, options: .ForDeleting)
			
			NSFileCoordinator().coordinateAccessWithIntents([writeIntent], queue: self.coordinationQueue, byAccessor: { (error) in
				if error != nil {
					return
				}
				
				do {
					try self.fileManager.removeItemAtURL(writeIntent.URL)
					
					NSOperationQueue.mainQueue().addOperationWithBlock({
						completion()
					})
				} catch {
					fatalError("unexpected error deleting item: \(error)")
				}
			})
		}
		
	}
	
	// MARK: - Private Helper Functions
	
	func availableFileForBaseURL(baseURL: NSURL, ext: String) -> NSURL {
		var target = baseURL.URLByAppendingPathExtension(ext)
		
		var nameSuffix = 1
		
		while target.checkPromisedItemIsReachableAndReturnError(nil) {
			target = NSURL(fileURLWithPath: baseURL.path! + "-\(nameSuffix).\(ext)")
			
			nameSuffix += 1
		}
		
		return target
	}
	
	func availableDirectoryForBaseURL(baseURL: NSURL) -> NSURL {
		var target = baseURL
		
		var nameSuffix = 1
		
		while target.checkPromisedItemIsReachableAndReturnError(nil) {
			target = NSURL(fileURLWithPath: baseURL.path! + "-\(nameSuffix)", isDirectory: true)
			
			nameSuffix += 1
		}
		
		return target
	}
	
	func checkPromisedURLIsDirectory(url: NSURL) -> Bool {
		var p: AnyObject?
		
		if url.checkPromisedItemIsReachableAndReturnError(nil) {
			try! url.getResourceValue(&p, forKey: NSURLIsDirectoryKey)
			return p as! Bool
		}
		
		return false
	}
	
}
