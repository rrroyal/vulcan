//
//  DictionaryEmployee.swift
//  vulcan
//
//  Created by Kacper on 05/11/2020.
//
//

import Foundation
import CoreData

@objc(DictionaryEmployee)
public class DictionaryEmployee: NSManagedObject, Codable, Identifiable {
	@nonobjc public class func fetchRequest() -> NSFetchRequest<DictionaryEmployee> {
		return NSFetchRequest<DictionaryEmployee>(entityName: "DictionaryEmployee")
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "Id"
		case name = "Imie"
		case surname = "Nazwisko"
		case code = "Kod"
		case active = "Aktywny"
		case teacher = "Nauczyciel"
		case loginID = "LoginId"
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(active, forKey: .active)
		try container.encode(code, forKey: .code)
		try container.encode(id, forKey: .id)
		try container.encode(loginID, forKey: .loginID)
		try container.encode(name, forKey: .name)
		try container.encode(surname, forKey: .surname)
		try container.encode(teacher, forKey: .teacher)
	}
	
	public required convenience init(from decoder: Decoder) throws {
		guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
			throw DecoderConfigurationError.missingManagedObjectContext
		}
		
		self.init(context: context)
		
		let values = try decoder.container(keyedBy: CodingKeys.self)
		active = try values.decode(Bool.self, forKey: .active)
		code = try values.decode(String.self, forKey: .code)
		id = try values.decode(Int64.self, forKey: .id)
		loginID = try values.decode(Int32?.self, forKey: .loginID) ?? -1
		name = try values.decode(String.self, forKey: .name)
		surname = try values.decode(String.self, forKey: .surname)
		teacher = try values.decode(Bool.self, forKey: .teacher)
	}
	
	@NSManaged public var active: Bool
	@NSManaged public var code: String?
	@NSManaged public var id: Int64
	@NSManaged public var loginID: Int32
	@NSManaged public var name: String?
	@NSManaged public var surname: String?
	@NSManaged public var teacher: Bool
}
