//
//  NextUpProvider.swift
//  Widget
//
//  Created by Kacper on 18/10/2020.
//

import CoreData
import WidgetKit
import Vulcan

struct NextUpProvider: TimelineProvider {
	struct Entry: TimelineEntry {
		let date: Date
		let currentEvent: Vulcan.ScheduleEvent?
		let nextEvents: [Vulcan.ScheduleEvent]
		
		var relevance: TimelineEntryRelevance? {
			guard let event: Vulcan.ScheduleEvent = self.currentEvent else {
				return TimelineEntryRelevance(score: 0.1)
			}
			
			if let dateStarts = event.dateStarts,
			   let dateEnds = event.dateEnds {
				return TimelineEntryRelevance(score: 1, duration: dateStarts.timeIntervalSince1970 - dateEnds.timeIntervalSince1970)
			} else {
				return TimelineEntryRelevance(score: 0.5)
			}
		}
	}
	
	var schedule: [Vulcan.ScheduleEvent] {
		let context = CoreDataModel.shared.persistentContainer.viewContext
		let fetchRequest: NSFetchRequest<StoredScheduleEvent> = StoredScheduleEvent.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(StoredScheduleEvent.dateStartsEpoch), ascending: true)]
		
		if let storedSchedule = try? context.fetch(fetchRequest) {
			return storedSchedule
				.compactMap { entity -> Vulcan.ScheduleEvent? in
					guard var event = Vulcan.ScheduleEvent(from: entity) else {
						return nil
					}
					
					let employeeFetchRequest: NSFetchRequest = DictionaryEmployee.fetchRequest()
					employeeFetchRequest.predicate = NSPredicate(format: "id == %d", event.employeeID)
					if let employee: DictionaryEmployee = (try? context.fetch(employeeFetchRequest))?.first {
						event.employee = employee
					}
					
					let timeFetchRequest: NSFetchRequest = DictionaryLessonTime.fetchRequest()
					timeFetchRequest.predicate = NSPredicate(format: "id == %d", event.lessonTimeID)
					guard let time: DictionaryLessonTime = (try? context.fetch(timeFetchRequest))?.first else {
						return nil
					}
					event.dateStartsEpoch = TimeInterval(event.dateEpoch + Int(time.start) + 3600)
					event.dateEndsEpoch = TimeInterval(event.dateEpoch + Int(time.end) + 3600)
					
					return event
				}
				.filter { $0.dateStarts != nil && $0.dateEnds != nil }
				.sorted { $0.dateStarts ?? $0.date < $1.dateStarts ?? $0.date }
				.filter { $0.userSchedule }
				.filter { $0.dateStarts ?? $0.date >= Date().startOfDay }
		} else {
			return []
		}
	}
	
	func placeholder(in context: Context) -> Entry {
		Entry(date: Date(), currentEvent: nil, nextEvents: [])
	}
	
	func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
		var currentEvent: Vulcan.ScheduleEvent = Vulcan.ScheduleEvent(dateEpoch: Int(Date().startOfDay.timeIntervalSince1970), lessonOfTheDay: 1, lessonTimeID: 0, subjectID: 0, subjectName: NSLocalizedString("Spanish", comment: ""), divisionShort: nil, room: "03", employeeID: 1, helpingEmployeeID: nil, oldEmployeeID: nil, oldHelpingEmployeeID: nil, scheduleID: 1, note: nil, labelStrikethrough: false, labelBold: false, userSchedule: false, employeeFullName: "Ben Chang")
		currentEvent.dateStarts = Date()
		currentEvent.dateEnds = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
		
		var nextEvent = currentEvent
		nextEvent.dateStarts = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: 1, to: nextEvent.dateStarts ?? nextEvent.date) ?? nextEvent.date
		nextEvent.dateEnds = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: 1, to: nextEvent.dateEnds ?? nextEvent.date) ?? nextEvent.date
		
		let entry = Entry(date: Date(), currentEvent: currentEvent, nextEvents: [nextEvent])
		completion(entry)
	}
	
	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
		var entries: [Entry] = schedule
			.map { event -> [Entry] in
				let nextEvents = schedule
					.filter { $0.dateStarts ?? $0.date > event.dateStarts ?? event.date }
				
				var entries: [Entry] = [Entry(date: event.dateStarts ?? event.date, currentEvent: event, nextEvents: nextEvents)]
				
				if let nextEventDateStarts = nextEvents.first?.dateStarts,
				   let currentEventDateEnds = event.dateEnds,
				   currentEventDateEnds != nextEventDateStarts {
					entries.append(Entry(date: currentEventDateEnds, currentEvent: nil, nextEvents: nextEvents))
				} else if event.lessonOfTheDay == 1 {
					entries.append(Entry(date: Date().startOfDay, currentEvent: nil, nextEvents: nextEvents))
				}
				
				return entries
			}
			.flatMap { $0 }
				
		entries.append(Entry(date: entries.last?.currentEvent?.dateEnds ?? entries.last?.date.addingTimeInterval(3600) ?? Date().addingTimeInterval(3600), currentEvent: nil, nextEvents: []))
		entries.sort { $0.date < $1.date }
		
		let policy: TimelineReloadPolicy
		if let lastEventDateEnds = entries.last?.currentEvent?.dateEnds ?? entries.last?.nextEvents.last?.dateEnds {
			policy = .after(lastEventDateEnds)
		} else {
			policy = .atEnd
		}
		
		completion(Timeline(entries: entries, policy: policy))
	}
}
