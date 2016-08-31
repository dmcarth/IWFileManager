//
//  FileManagerTests.swift
//  IWFileManager
//
//  Created by Dylan McArthur on 8/31/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import IWFileManager

class FileManagerTests: XCTestCase {

	let fileManager = FileManager.sharedManager
	
	var directoryURL = NSURL()
	
	override func setUp() {
		super.setUp()
		
		directoryURL = fileManager.directoryURLByAppendingPath("")
		
		clearDirectory()
	}
	
	override func tearDown() {
		clearDirectory()
		
		super.tearDown()
	}
	
	func clearDirectory() {
		let fm = NSFileManager()
		let files = try! fm.contentsOfDirectoryAtURL(directoryURL, includingPropertiesForKeys: nil, options: [])
		
		for file in files {
			try! fm.removeItemAtURL(file)
		}
	}
	
	// MARK: - Tests
	
	func testCreateEmptyTextFile() {
		let expectation = expectationWithDescription("Creating text file")
		
		fileManager.createEmptyTextFile(named: "File.md", inDirectoryURL: directoryURL) { (url) in
			XCTAssert(url.checkResourceIsReachableAndReturnError(nil))
			expectation.fulfill()
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testCreateDuplicateTextFile() {
		let expectation = expectationWithDescription("Create duplicate text file")
		
		fileManager.createEmptyTextFile(named: "File.md", inDirectoryURL: directoryURL) { (url) in
			
			self.fileManager.createEmptyTextFile(named: "File.md", inDirectoryURL: self.directoryURL, completion: { (url) in
				XCTAssertEqual(url.lastPathComponent, "File-1.md")
				expectation.fulfill()
			})
			
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testCreateDirectory() {
		let expectation = expectationWithDescription("Create directory")
		
		fileManager.createDirectory(named: "Folder", inDirectoryURL: directoryURL) { (url) in
			XCTAssert(url.checkResourceIsReachableAndReturnError(nil))
			expectation.fulfill()
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testCreateDuplicateDirectory() {
		let expectation = expectationWithDescription("Create duplicate directory")
		
		fileManager.createDirectory(named: "Folder", inDirectoryURL: directoryURL) { (url) in
			
			self.fileManager.createDirectory(named: "Folder", inDirectoryURL: self.directoryURL, completion: { (url) in
				XCTAssertEqual(url.lastPathComponent, "Folder-1")
				expectation.fulfill()
			})
			
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testCreateTemplateProject() {
		let expectation = expectationWithDescription("Create template project")
		
		let templateURL = NSBundle(forClass: FileManagerTests.self).URLForResource("TemplateProject", withExtension: nil)!
		
		fileManager.createTemplateProject(named: "Template", fromTemplateURL: templateURL, inDirectoryURL: directoryURL) { (url) in
			XCTAssert(url.checkPromisedItemIsReachableAndReturnError(nil))
			expectation.fulfill()
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testCreateDuplicatTemplateProject() {
		let expectation = expectationWithDescription("Create duplicate template project")
		
		let templateURL = NSBundle(forClass: FileManagerTests.self).URLForResource("TemplateProject", withExtension: nil)!
		
		fileManager.createTemplateProject(named: "Novel", fromTemplateURL: templateURL, inDirectoryURL: directoryURL) { (url) in
			
			self.fileManager.createTemplateProject(named: "Novel", fromTemplateURL: templateURL, inDirectoryURL: self.directoryURL, completion: { (url) in
				XCTAssertEqual(url.lastPathComponent, "Novel-1")
				expectation.fulfill()
			})
			
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testMoveFile() {
		let expectation = expectationWithDescription("Move file")
		
		fileManager.createEmptyTextFile(named: "File.md", inDirectoryURL: directoryURL) { (fileURL1) in
			
			self.fileManager.createDirectory(named: "Folder", inDirectoryURL: self.directoryURL, completion: { (folderURL) in
				
				self.fileManager.move(itemAtURL: fileURL1, intoDirectoryURL: folderURL, completion: { (fileURL2) in
					XCTAssert(fileURL2.checkPromisedItemIsReachableAndReturnError(nil))
					XCTAssert(!fileURL1.checkPromisedItemIsReachableAndReturnError(nil))
					expectation.fulfill()
				})
				
			})
			
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testMoveFileToDuplicate() {
		let expectation = expectationWithDescription("Move file to duplicate")
		
		fileManager.createEmptyTextFile(named: "File.md", inDirectoryURL: directoryURL) { (fileURL1) in
			
			self.fileManager.createDirectory(named: "Folder", inDirectoryURL: self.directoryURL, completion: { (folderURL) in
				
				self.fileManager.createEmptyTextFile(named: "File.md", inDirectoryURL: folderURL, completion: { (fileURL2) in
					
					self.fileManager.move(itemAtURL: fileURL1, intoDirectoryURL: folderURL, completion: { (fileURL3) in
						XCTAssertEqual(fileURL3.lastPathComponent!, "File-1.md")
						expectation.fulfill()
					})
					
				})
				
			})
			
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testMoveDirectory() {
		let expectation = expectationWithDescription("Move folder")
		
		fileManager.createDirectory(named: "Folder", inDirectoryURL: directoryURL) { (folderURL1) in
			
			self.fileManager.createDirectory(named: "SmFolder", inDirectoryURL: self.directoryURL, completion: { (folderURL2) in
				
				self.fileManager.move(itemAtURL: folderURL2, intoDirectoryURL: folderURL1, completion: { (url) in
					let comps = url.pathComponents!
					let rel = comps[comps.count - 2] + "/" + comps[comps.count-1]
					XCTAssertEqual(rel, "Folder/SmFolder")
					expectation.fulfill()
				})
				
			})
			
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testRenameFile() {
		let expectation = expectationWithDescription("Rename file")
		
		fileManager.createEmptyTextFile(named: "File.md", inDirectoryURL: directoryURL) { (url) in
			
			self.fileManager.rename(itemAtURL: url, usingName: "NewFile.md", completion: { (newURL) in
				XCTAssert(!url.checkPromisedItemIsReachableAndReturnError(nil))
				XCTAssertEqual(newURL.lastPathComponent!, "NewFile.md")
				expectation.fulfill()
			})
			
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testRenameDirectory() {
		let expectation = expectationWithDescription("Rename folder")
		
		fileManager.createDirectory(named: "Folder", inDirectoryURL: directoryURL) { (folderURL) in
			
			self.fileManager.rename(itemAtURL: folderURL, usingName: "NewFolder", completion: { (url) in
				XCTAssert(!folderURL.checkPromisedItemIsReachableAndReturnError(nil))
				XCTAssertEqual(url.lastPathComponent, "NewFolder")
				XCTAssert(url.checkPromisedItemIsReachableAndReturnError(nil))
				expectation.fulfill()
			})
			
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testDelete() {
		let expectation = expectationWithDescription("delete file")
		
		fileManager.createEmptyTextFile(named: "File.md", inDirectoryURL: directoryURL) { (url) in
			self.fileManager.delete(itemAtURL: url, completion: {
				XCTAssert(!url.checkPromisedItemIsReachableAndReturnError(nil))
				expectation.fulfill()
			})
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testDeepDirectoryModel() {
		let expectation = expectationWithDescription("delete file")
		
		fileManager.createDirectory(named: "Folder", inDirectoryURL: directoryURL) { (folderURL1) in
			
			self.fileManager.createEmptyTextFile(named: "File.md", inDirectoryURL: self.directoryURL, completion: { (fileURL) in
				
				self.fileManager.createDirectory(named: "SmFolder", inDirectoryURL: folderURL1, completion: { (folderURL2) in
					
					let nodes = self.fileManager.deepDirectoryModel(forDirectoryURL: self.directoryURL)
					XCTAssertEqual(nodes.count, 3)
					expectation.fulfill()
					
				})
				
			})
			
		}
		
		waitForExpectationsWithTimeout(5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}

}
