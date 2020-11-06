//
//  DictionaryGradeCategory.swift
//  vulcan
//
//  Created by Kacper on 05/11/2020.
//
//

import Foundation
import CoreData

@objc(DictionaryGradeCategory)
public class DictionaryGradeCategory: NSManagedObject, Codable, Identifiable {
	@nonobjc public class func fetchRequest() -> NSFetchRequest<DictionaryGradeCategory> {
		return NSFetchRequest<DictionaryGradeCategory>(entityName: "DictionaryGradeCategory")
	}
	
	private enum CodingKeys: String, CodingKey {
		case code = "Kod"
		case id = "Id"
		case name = "Nazwa"
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(code, forKey: .code)
		try container.encode(id, forKey: .id)
		try container.encode(name, forKey: .name)
	}
	
	public required convenience init(from decoder: Decoder) throws {
		guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
			throw DecoderConfigurationError.missingManagedObjectContext
		}
		
		self.init(context: context)
		
		let values = try decoder.container(keyedBy: CodingKeys.self)
		code = try values.decode(String?.self, forKey: .code)
		id = try values.decode(Int64.self, forKey: .id)
		name = try values.decode(String?.self, forKey: .name)
	}
	
	@NSManaged public var code: String?
	@NSManaged public var id: Int64
	@NSManaged public var name: String?
}
