//
//  DictionarySubject.swift
//  vulcan
//
//  Created by Kacper on 05/11/2020.
//
//

import Foundation
import CoreData

@objc(DictionarySubject)
public class DictionarySubject: NSManagedObject, Codable, Identifiable {
	@nonobjc public class func fetchRequest() -> NSFetchRequest<DictionarySubject> {
		return NSFetchRequest<DictionarySubject>(entityName: "DictionarySubject")
	}
	
	private enum CodingKeys: String, CodingKey {
		case active = "Aktywny"
		case code = "Kod"
		case id = "Id"
		case name = "Nazwa"
		case position = "Pozycja"
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(active, forKey: .active)
		try container.encode(code, forKey: .code)
		try container.encode(id, forKey: .id)
		try container.encode(name, forKey: .name)
		try container.encode(position, forKey: .position)
	}
	
	public required convenience init(from decoder: Decoder) throws {
		guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
			throw DecoderConfigurationError.missingManagedObjectContext
		}
		
		self.init(context: context)
		
		let values = try decoder.container(keyedBy: CodingKeys.self)
		active = try values.decode(Bool.self, forKey: .active)
		code = try values.decode(String?.self, forKey: .code)
		id = try values.decode(Int64.self, forKey: .id)
		name = try values.decode(String?.self, forKey: .name)
		position = try values.decode(Int16.self, forKey: .position)
	}
	
	@NSManaged public var active: Bool
	@NSManaged public var code: String?
	@NSManaged public var id: Int64
	@NSManaged public var name: String?
	@NSManaged public var position: Int16
}
