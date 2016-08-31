//
//  File Models.swift
//  IWFileManager
//
//  Created by Dylan McArthur on 8/19/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public enum FileNodeType {
	case File, Folder
}

public class FileNode: CustomStringConvertible {
	
	public var name = ""
	
	public var type: FileNodeType = .File
	
	public var level = 0
	
	public var url = NSURL()
	
	public init(url: NSURL, type: FileNodeType) {
		self.url = url
		self.name = url.lastPathComponent!
		self.type = type
	}
	
	public var description: String {
		var ticks = ""
		for _ in 0..<level {
			ticks += "- "
		}
		
		return ticks + name + " (\(type)) "
	}
	
}
