//
//  TweakPersistency.swift
//  SwiftTweaks
//c
//  Created by Bryan Clark on 11/16/15.
//  Copyright © 2015 Khan Academy. All rights reserved.
//

import UIKit

/// Identifies tweaks in TweakPersistency
internal protocol TweakIdentifiable {
	var persistenceIdentifier: String { get }
}

internal final class TweakPersistency {
	private let diskPersistency: TweakDiskPersistency

	private var tweakCache = TweakCache()

	init(identifier: String) {
		self.diskPersistency = TweakDiskPersistency(identifier: identifier)
		self.tweakCache = self.diskPersistency.loadFromDisk()
	}

	internal func currentValueForTweak<T>(_ tweak: Tweak<T>) -> T? {
		return persistedValueForTweakIdentifiable(AnyTweak(tweak: tweak)) as? T
	}

	internal func currentValueForTweak<T>(_ tweak: Tweak<T>) -> T? where T: Comparable {
		if let currentValue = persistedValueForTweakIdentifiable(AnyTweak(tweak: tweak)) as? T {
				// If the tweak can be clipped, then we'll need to clip it - because
				// the tweak might've been persisted without a min / max, but then you changed the tweak definition.
				// example: you tweaked it to 11, then set a max of 10 - the persisted value is still 11!
				return clip(currentValue, tweak.minimumValue, tweak.maximumValue)
		}

		return nil
	}

	internal func persistedValueForTweakIdentifiable(_ tweakID: TweakIdentifiable) -> TweakableType? {
		return tweakCache.get(key: tweakID.persistenceIdentifier)
	}

	internal func setValue(_ value: TweakableType?,  forTweakIdentifiable tweakID: TweakIdentifiable) {
		tweakCache.set(key: tweakID.persistenceIdentifier, value: value)
		diskPersistency.saveToDisk(tweakCache)
	}

	internal func clearAllData() {
		tweakCache = TweakCache()
		diskPersistency.saveToDisk(tweakCache)
	}
}

/// Persists a TweakCache on disk using NSCoding
private final class TweakDiskPersistency {
	private let fileURL: URL

	private static func fileURLForIdentifier(_ identifier: String) -> URL {
		return try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
			.appendingPathComponent("SwiftTweaks")
			.appendingPathComponent("\(identifier)")
			.appendingPathExtension("db")
	}

	init(identifier: String) {
		self.fileURL = TweakDiskPersistency.fileURLForIdentifier(identifier)
		try? FileManager.default.createDirectory(at: self.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
	}

	func loadFromDisk() -> TweakCache {
		if let data = try? Data(contentsOf: fileURL),
			 let cache = try? JSONDecoder().decode(TweakCache.self, from: data) {
			return cache
		} else {
			return TweakCache()
		}
	}

	func saveToDisk(_ cache: TweakCache) {
		if let data = try? JSONEncoder().encode(cache) {
			try? data.write(to: fileURL)
		}
	}
}

// Note: Could pass in key and Tweakable type in order to avoid needing to cast/check keys to determine type.

class TweakCache: Codable {
	var boolean: [String:Bool] = [:]
	var integer: [String:Int] = [:]
	var cgFloat: [String:CGFloat] = [:]
	var double: [String:Double] = [:]
	var color: [String:CodableColor] = [:]
	var string: [String:String] = [:]
	var stringList: [String:String] = [:]
//	var action: [String:TweakAction] = [:]
}

extension TweakCache {
	func get(key: String) -> TweakableType? {
		guard let type = getKnownKeyType(key: key) else { return nil }
		switch type {
		case .boolean:
			return boolean[key]
		case .integer:
			return integer[key]
		case .cgFloat:
			return cgFloat[key]
		case .double:
			return double[key]
		case .color:
			return color[key]?.asTweakColor
		case .string:
			return string[key]
		case .stringList:
			return stringList[key]
		}
	}
	
	func set(key: String, value: TweakableType?) {
		if let value = value {
			// If switch to use TweakViewDataType, could avoid unneeded casts.
			if let boolean = value as? Bool { self.boolean[key] = boolean }
			if let integer = value as? Int { self.integer[key] = integer }
			if let cgFloat = value as? CGFloat { self.cgFloat[key] = cgFloat }
			if let double = value as? Double { self.double[key] = double }
			if let color = value as? TweakColor { self.color[key] = CodableColor(color) }
			if let string = value as? String { self.string[key] = string }
		} else {
			remove(key: key)
		}
	}
	
	private func remove(key: String) {
		guard let type = getKnownKeyType(key: key) else { return }
		switch type {
		case .boolean:
			boolean[key] = nil
		case .integer:
			integer[key] = nil
		case .cgFloat:
			cgFloat[key] = nil
		case .double:
			double[key] = nil
		case .color:
			color[key] = nil
		case .string:
			string[key] = nil
		case .stringList:
			stringList[key] = nil
		}
	}
	
	private func getKnownKeyType(key: String) -> KeyType? {
		if boolean.keys.contains(key) { return .boolean }
		if integer.keys.contains(key) { return .integer }
		if cgFloat.keys.contains(key) { return .cgFloat }
		if double.keys.contains(key) { return .double }
		if color.keys.contains(key) { return .color }
		if string.keys.contains(key) { return .string }
		if stringList.keys.contains(key) { return .stringList }
		return nil
	}
}

// Could probably replace with TweakViewDataType
enum KeyType {
	case boolean
	case integer
	case cgFloat
	case double
	case color
	case string
	case stringList
//	case action
}

private extension TweakViewDataType {
	/// Identifies our TweakViewDataType when in NSCoding. See implementation of TweakDiskPersistency.Data
	var nsCodingKey: String {
		switch self {
		case .boolean: return "boolean"
		case .integer: return "integer"
		case .cgFloat: return "cgfloat"
		case .double: return "double"
		case .uiColor: return "uicolor"
		case .string: return "string"
		case .stringList: return "stringlist"
		case .action: return "action"
		}
	}
}

private extension TweakableType {
	/// Gets the underlying value from a Tweakable Type
	var nsCoding: AnyObject {
		switch type(of: self).tweakViewDataType {
			case .boolean: return self as! Bool as AnyObject
			case .integer: return self as! Int as AnyObject
			case .cgFloat: return self as! CGFloat as AnyObject
			case .double: return self as! Double as AnyObject
			case .uiColor: return self as! UIColor
			case .string: return self as! NSString
			case .stringList: return (self as! StringOption).value as AnyObject
			case .action: return true as AnyObject
		}
	}
}

struct CodableColor: Codable {
	let r,b,g,a: CGFloat
	init(_ tweakColor: TweakColor) {
		self.r = tweakColor.ciColor.red
		self.g = tweakColor.ciColor.green
		self.b = tweakColor.ciColor.blue
		self.a = tweakColor.ciColor.alpha
	}
	var asTweakColor: TweakColor {
		return TweakColor(red: r, green: g, blue: b, alpha: a)
	}
}
