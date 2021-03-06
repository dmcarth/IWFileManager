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

	let fileManager = IWFileManager.sharedManager
	
	var directoryURL: URL!
	
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
		let fm = Foundation.FileManager()
		let files = try! fm.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
		
		for file in files {
			try! fm.removeItem(at: file)
		}
	}
	
	// MARK: - Tests
	
	func testCreateEmptyTextFile() {
		let expectation = self.expectation(description: "Creating text file")
		
		fileManager.createEmptyTextFile(named: "File.md", in: directoryURL) { (url) in
			XCTAssert(FileManager.default.fileExists(atPath: url.path))
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testCreateDuplicateTextFile() {
		let expectation = self.expectation(description: "Create duplicate text file")
		
		fileManager.createEmptyTextFile(named: "File.md", in: directoryURL) { (url) in
			
			self.fileManager.createEmptyTextFile(named: "File.md", in: self.directoryURL, completion: { (url) in
				XCTAssertEqual(url.lastPathComponent, "File-1.md")
				expectation.fulfill()
			})
			
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testCreateDirectory() {
		let expectation = self.expectation(description: "Create directory")
		
		fileManager.createDirectory(named: "Folder", in: directoryURL) { (url) in
			XCTAssert(FileManager.default.fileExists(atPath: url.path))
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testCreateDuplicateDirectory() {
		let expectation = self.expectation(description: "Create duplicate directory")
		
		fileManager.createDirectory(named: "Folder", in: directoryURL) { (url) in
			
			self.fileManager.createDirectory(named: "Folder", in: self.directoryURL, completion: { (url) in
				XCTAssertEqual(url.lastPathComponent, "Folder-1")
				expectation.fulfill()
			})
			
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testCreateTemplateProject() {
		let expectation = self.expectation(description: "Create template project")
		
		let templateURL = Bundle(for: FileManagerTests.self).url(forResource: "TemplateProject", withExtension: nil)!
		
		fileManager.createTemplateProject(named: "Template", using: templateURL, in: directoryURL) { (url) in
			XCTAssert(FileManager.default.fileExists(atPath: url.path))
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testCreateDuplicatTemplateProject() {
		let expectation = self.expectation(description: "Create duplicate template project")
		
		let templateURL = Bundle(for: FileManagerTests.self).url(forResource: "TemplateProject", withExtension: nil)!
		
		fileManager.createTemplateProject(named: "Novel", using: templateURL, in: directoryURL) { (url) in
			
			self.fileManager.createTemplateProject(named: "Novel", using: templateURL, in: self.directoryURL, completion: { (url) in
				XCTAssertEqual(url.lastPathComponent, "Novel-1")
				expectation.fulfill()
			})
			
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testMoveFile() {
		let expectation = self.expectation(description: "Move file")
		
		fileManager.createEmptyTextFile(named: "File.md", in: directoryURL) { (fileURL1) in
			
			self.fileManager.createDirectory(named: "Folder", in: self.directoryURL, completion: { (folderURL) in
				
				self.fileManager.move(itemAt: fileURL1, into: folderURL, completion: { (fileURL2) in
					XCTAssert(FileManager.default.fileExists(atPath: fileURL2.path))
					XCTAssert(FileManager.default.fileExists(atPath: fileURL1.path) == false)
					expectation.fulfill()
				})
				
			})
			
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testMoveFileToDuplicate() {
		let expectation = self.expectation(description: "Move file to duplicate")
		
		fileManager.createEmptyTextFile(named: "File.md", in: directoryURL) { (fileURL1) in
			
			self.fileManager.createDirectory(named: "Folder", in: self.directoryURL, completion: { (folderURL) in
				
				self.fileManager.createEmptyTextFile(named: "File.md", in: folderURL, completion: { (fileURL2) in
					
					self.fileManager.move(itemAt: fileURL1, into: folderURL, completion: { (fileURL3) in
						XCTAssertEqual(fileURL3.lastPathComponent, "File-1.md")
						expectation.fulfill()
					})
					
				})
				
			})
			
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testMoveDirectory() {
		let expectation = self.expectation(description: "Move folder")
		
		fileManager.createDirectory(named: "Folder", in: directoryURL) { (folderURL1) in
			
			self.fileManager.createDirectory(named: "SmFolder", in: self.directoryURL, completion: { (folderURL2) in
				
				self.fileManager.move(itemAt: folderURL2, into: folderURL1, completion: { (url) in
					let comps = url.pathComponents
					let rel = comps[comps.count - 2] + "/" + comps[comps.count-1]
					XCTAssertEqual(rel, "Folder/SmFolder")
					expectation.fulfill()
				})
				
			})
			
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testRenameFile() {
		let expectation = self.expectation(description: "Rename file")
		
		fileManager.createEmptyTextFile(named: "File.md", in: directoryURL) { (url) in
			
			self.fileManager.rename(itemAt: url, using: "NewFile.md", completion: { (newURL) in
				XCTAssert(FileManager.default.fileExists(atPath: url.path) == false)
				XCTAssertEqual(newURL.lastPathComponent, "NewFile.md")
				expectation.fulfill()
			})
			
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testRenameDirectory() {
		let expectation = self.expectation(description: "Rename folder")
		
		fileManager.createDirectory(named: "Folder", in: directoryURL) { (folderURL) in
			
			self.fileManager.rename(itemAt: folderURL, using: "NewFolder", completion: { (url) in
				XCTAssert(FileManager.default.fileExists(atPath: folderURL.path) == false)
				XCTAssertEqual(url.lastPathComponent, "NewFolder")
				XCTAssert(FileManager.default.fileExists(atPath: url.path))
				expectation.fulfill()
			})
			
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testDelete() {
		let expectation = self.expectation(description: "delete file")
		
		fileManager.createEmptyTextFile(named: "File.md", in: directoryURL) { (url) in
			self.fileManager.delete(itemAt: url, completion: {
				XCTAssert(FileManager.default.fileExists(atPath: url.path) == false)
				expectation.fulfill()
			})
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}
	
	func testDeepDirectoryModel() {
		let expectation = self.expectation(description: "delete file")
		
		fileManager.createDirectory(named: "Folder", in: directoryURL) { (folderURL1) in
			
			self.fileManager.createEmptyTextFile(named: "File.md", in: self.directoryURL, completion: { (fileURL) in
				
				self.fileManager.createDirectory(named: "SmFolder", in: folderURL1, completion: { (folderURL2) in
					
					let nodes = self.fileManager.deepDirectoryModel(for: self.directoryURL)
					XCTAssertEqual(nodes.count, 3)
					expectation.fulfill()
					
				})
				
			})
			
		}
		
		waitForExpectations(timeout: 5) { (error) in
			if let error = error {
				XCTFail("\(error)")
			}
		}
	}

}
