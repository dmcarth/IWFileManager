//
//  File Models.swift
//  IWFileManager
//
//  Created by Dylan McArthur on 8/19/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public enum FileNodeType {
	case file, folder
}

public class DirectoryTreeNode {
	
	internal var parent: DirectoryTreeNode?
	internal var children = [DirectoryTreeNode]()
	
	public var name: String
	public var url: URL
	public var type = FileNodeType.file
	public var isExpanded = false
	public var flatChildren: [DirectoryTreeNode] {
		if needsTraversal {
			euler = eulerTrail(for: self)
		}
		needsTraversal = false
		return euler
	}
	
	fileprivate var needsTraversal = true
	fileprivate var euler = [DirectoryTreeNode]()
	
	init(url: URL) {
		self.url = url
		self.name = url.lastPathComponent
	}
	
	func addChild(_ child: DirectoryTreeNode) {
		self.children.append(child)
		child.parent = self
	}
	
	func eulerTrail(for node: DirectoryTreeNode) -> [DirectoryTreeNode] {
		var buff = [DirectoryTreeNode]()
		
		for child in children {
			buff.append(child)
			if child.isExpanded {
				buff.append(contentsOf: eulerTrail(for: child))
			}
		}
		
		return buff
	}
	
}

extension DirectoryTreeNode: Collection {
	
	public typealias Index = Int
	
	public var startIndex: Int {
		return 0
	}
	
	public var endIndex: Int {
		return children.count
	}
	
	public func index(after i: Int) -> Int {
		return i + 1
	}
	
	public subscript(_ i: Int) -> DirectoryTreeNode {
		return children[i]
	}
}

extension DirectoryTreeNode: CustomStringConvertible {
	
	public var description: String {
		return name
	}
	
	func debugString() -> String {
		return name +  " { " + children.map { $0.description }.joined(separator: "\n") + " } "
	}
	
}
