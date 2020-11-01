//
//  ComplicationController.swift
//  WatchKit Extension
//
//  Created by royal on 03/09/2020.
//

import ClockKit
import Vulcan

class ComplicationController: NSObject, CLKComplicationDataSource {
	var schedule: [Vulcan.ScheduleEvent] {
		VulcanStore.shared.schedule
			.flatMap(\.events)
			.filter { $0.isUserSchedule }
	}
	
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "ScheduleComplication", displayName: "vulcan", supportedFamilies: CLKComplicationFamily.allCases)
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    // MARK: - Timeline Configuration
	
	func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
		handler(self.schedule.filter({ $0.dateStarts ?? $0.date >= Date() }).first?.date.startOfDay)
	}
	
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
		handler(self.schedule.filter({ $0.dateStarts ?? $0.date >= Date() }).last?.dateEnds)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.hideOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
		
		let schedule = self.schedule
			.filter { $0.dateStarts ?? $0.date >= Date() }
		
		let now: Date = Date()
		
		// If no event, return empty template
		guard let nextEventIndex = schedule.firstIndex(where: { $0.dateStarts ?? $0.date > now || $0.isCurrent ?? false }) else {
			handler(CLKComplicationTimelineEntry(date: now, complicationTemplate: emptyTemplate(for: complication)))
			return
		}
		
		// First index or out of range
		let nextEvent = schedule[nextEventIndex]
		if nextEventIndex - 1 < 0 {
			handler(CLKComplicationTimelineEntry(date: nextEvent.dateStarts ?? nextEvent.date, complicationTemplate: templateForEvent(for: complication, event: nextEvent)))
			return
		}
		
		// Other events
		let previousEvent = schedule[nextEventIndex - 1]
		guard let nextEventDateStarts = nextEvent.dateStarts,
			  let nextEventDateEnds = nextEvent.dateEnds,
			  let previousEventDateStarts = previousEvent.dateStarts,
			  let previousEventDateEnds = previousEvent.dateEnds else {
			handler(CLKComplicationTimelineEntry(date: now, complicationTemplate: templateForEvent(for: complication, event: nextEvent)))
			return
		}
		
		let previousEventTriggerTime: TimeInterval = (previousEventDateStarts.timeIntervalSinceReferenceDate + previousEventDateEnds.timeIntervalSinceReferenceDate) / 2
		let nextEventTriggerTime: TimeInterval = (nextEventDateStarts.timeIntervalSinceReferenceDate + nextEventDateEnds.timeIntervalSinceReferenceDate) / 2
		let currentTime: TimeInterval = now.timeIntervalSinceReferenceDate
		
		if currentTime < nextEventTriggerTime {
			// previousEvent
			handler(CLKComplicationTimelineEntry(date: Date(timeIntervalSinceReferenceDate: previousEventTriggerTime), complicationTemplate: templateForEvent(for: complication, event: previousEvent)))
			return
		} else {
			// nextEvent
			handler(CLKComplicationTimelineEntry(date: Date(timeIntervalSinceReferenceDate: nextEventTriggerTime), complicationTemplate: templateForEvent(for: complication, event: nextEvent)))
			return
		}
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after the given date
		var entries: [CLKComplicationTimelineEntry] = self.schedule
			.filter { $0.dateEnds ?? $0.date >= date.startOfDay }
			.timeline()
			.map { date, event in
				CLKComplicationTimelineEntry(date: date, complicationTemplate: templateForEvent(for: complication, event: event))
			}
			.sorted { $0.date < $1.date }
		
		entries.append(CLKComplicationTimelineEntry(date: self.schedule.last?.dateEnds ?? Date(), complicationTemplate: emptyTemplate(for: complication)))
		
		handler(entries)
    }

    // MARK: - Sample Templates
	
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
		handler(templateForEvent(for: complication, event: self.schedule.first(where: { $0.dateEnds ?? $0.date >= Date() })))
    }
	
	// MARK: - Helper Functions
	
	/// Returns empty complication template for specified complication
	/// - Parameter complication: Current complication
	/// - Returns: Complication template
	private func emptyTemplate(for complication: CLKComplication) -> CLKComplicationTemplate {
		let template: CLKComplicationTemplate
		
		let scheduleText = CLKSimpleTextProvider(text: "Schedule".localized)
		let nothingLeftEmojiText = CLKSimpleTextProvider(text: "Nothing left for now ☺️".localized)
		let nothingLeftText = CLKSimpleTextProvider(text: "Nothing left for now".localized)
		let emojiText = CLKSimpleTextProvider(text: "☺️")
		
		// Modular Small
		let modularSmall = CLKComplicationTemplateModularSmallSimpleText(textProvider: emojiText)
		
		// Modular Large
		let modularLarge = CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: scheduleText, body1TextProvider: nothingLeftEmojiText)
		
		// Utilitarian Small
		let utilitarianSmall = CLKComplicationTemplateUtilitarianSmallRingText(textProvider: emojiText, fillFraction: 0, ringStyle: .open)
		
		// Utilitarian Small Flat
		let utilitarianSmallFlat = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: nothingLeftEmojiText)
		
		// Utilitarian Large
		let utilitarianLarge = CLKComplicationTemplateUtilitarianLargeFlat(textProvider: nothingLeftEmojiText)
		
		// Circular Small
		let circularSmall = CLKComplicationTemplateCircularSmallSimpleText(textProvider: emojiText)
		
		// Extra Large
		let extraLarge = CLKComplicationTemplateExtraLargeStackText(line1TextProvider: scheduleText, line2TextProvider: nothingLeftEmojiText)
		
		// Graphic Corner
		let graphicCorner = CLKComplicationTemplateGraphicCornerStackText(innerTextProvider: nothingLeftText, outerTextProvider: emojiText)
		
		// Graphic Bezel
		let circularTemplate = CLKComplicationTemplateGraphicCircularStackText(line1TextProvider: CLKSimpleTextProvider(text: "📆"), line2TextProvider: emojiText)
		circularTemplate.tintColor = UIColor(named: "AccentColor")
		let graphicBezel = CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circularTemplate, textProvider: nothingLeftText)
		
		// Graphic Circular
		let graphicCircular = circularTemplate
		
		// Graphic Rectangular
		let graphicRectangular = CLKComplicationTemplateGraphicRectangularStandardBody(headerTextProvider: scheduleText, body1TextProvider: nothingLeftEmojiText)
		
		// Graphic Extra Large
		let graphicExtraLarge = CLKComplicationTemplateGraphicExtraLargeCircularStackText(line1TextProvider: scheduleText, line2TextProvider: nothingLeftEmojiText)
		
		switch complication.family {
			case .circularSmall:		template = circularSmall
			case .modularSmall:			template = modularSmall
			case .modularLarge:			template = modularLarge
			case .utilitarianSmall:		template = utilitarianSmall
			case .utilitarianSmallFlat:	template = utilitarianSmallFlat
			case .utilitarianLarge:		template = utilitarianLarge
			case .extraLarge:			template = extraLarge
			case .graphicCorner:		template = graphicCorner
			case .graphicBezel:			template = graphicBezel
			case .graphicCircular:		template = graphicCircular
			case .graphicRectangular:	template = graphicRectangular
			case .graphicExtraLarge:	template = graphicExtraLarge
			@unknown default:			fatalError("Unknown complication type: \(complication.family.rawValue)")
		}
		
		template.tintColor = UIColor(named: "AccentColor")
		return template
	}
	
	/// Returns complication template for specified complication
	/// - Parameters:
	///   - complication: Current complication
	///   - event: Selected event
	/// - Returns: Complication template
	private func templateForEvent(for complication: CLKComplication, event: Vulcan.ScheduleEvent?) -> CLKComplicationTemplate {
		guard let event: Vulcan.ScheduleEvent = event,
			  let dateStarts = event.dateStarts,
			  let dateEnds = event.dateEnds else {
			return emptyTemplate(for: complication)
		}
		
		let template: CLKComplicationTemplate
		
		let subjectTextProvider: CLKTextProvider = CLKSimpleTextProvider(text: event.subjectName)
		let roomAndSubjectTextProvider: CLKTextProvider = CLKSimpleTextProvider(text: "(\(event.room)) \(event.subjectName)")
		var roomAndTeacherTextProvider: CLKTextProvider {
			if let employeeFullName = event.employeeFullName {
				return CLKSimpleTextProvider(text: "(\(event.room)) \(employeeFullName)")
			} else {
				return CLKSimpleTextProvider(text: "Room \(event.room)")
			}
		}
		let roomTextProvider: CLKTextProvider = CLKSimpleTextProvider(text: event.room)
		let dateProvider: CLKTextProvider = CLKTimeIntervalTextProvider(start: dateStarts, end: dateEnds)
		
		// Modular Small
		let modularSmall: CLKComplicationTemplate = CLKComplicationTemplateModularSmallSimpleText(textProvider: roomTextProvider)
		
		// Modular Large
		let modularLarge: CLKComplicationTemplate = CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: subjectTextProvider, body1TextProvider: roomAndTeacherTextProvider, body2TextProvider: dateProvider)
		
		// Utilitarian Small
		let utilitarianSmall: CLKComplicationTemplate = CLKComplicationTemplateUtilitarianSmallRingText(textProvider: roomTextProvider, fillFraction: 0, ringStyle: .open)
		
		// Utilitarian Small Flat
		let utilitarianSmallFlat: CLKComplicationTemplate = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: roomAndSubjectTextProvider)
		
		// Utilitarian Large
		let utilitarianLarge: CLKComplicationTemplate = CLKComplicationTemplateUtilitarianLargeFlat(textProvider: roomAndSubjectTextProvider)
		
		// Circular Small
		let circularSmall: CLKComplicationTemplate = CLKComplicationTemplateCircularSmallSimpleText(textProvider: roomTextProvider)
		
		// Extra Large
		let extraLarge: CLKComplicationTemplate = CLKComplicationTemplateExtraLargeStackText(line1TextProvider: subjectTextProvider, line2TextProvider: roomTextProvider)
		
		// Graphic Corner
		let graphicCorner: CLKComplicationTemplate = CLKComplicationTemplateGraphicCornerStackText(innerTextProvider: dateProvider, outerTextProvider: roomTextProvider)
		
		// Graphic Bezel
		let circularTemplate: CLKComplicationTemplateGraphicCircular = CLKComplicationTemplateGraphicCircularStackText(line1TextProvider: CLKSimpleTextProvider(text: "📆"), line2TextProvider: roomTextProvider)
		circularTemplate.tintColor = UIColor(named: "AccentColor")
		let graphicBezel: CLKComplicationTemplate = CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circularTemplate, textProvider: subjectTextProvider)
		
		// Graphic Circular
		let graphicCircular: CLKComplicationTemplate = circularTemplate
		
		// Graphic Rectangular
		let graphicRectangular: CLKComplicationTemplate = CLKComplicationTemplateGraphicRectangularStandardBody(headerTextProvider: subjectTextProvider, body1TextProvider: roomAndTeacherTextProvider, body2TextProvider: dateProvider)
		
		// Graphic Extra Large
		let graphicExtraLarge: CLKComplicationTemplate = CLKComplicationTemplateGraphicExtraLargeCircularStackText(line1TextProvider: roomAndSubjectTextProvider, line2TextProvider: dateProvider)
		
		switch complication.family {
			case .circularSmall:		template = circularSmall
			case .modularSmall:			template = modularSmall
			case .modularLarge:			template = modularLarge
			case .utilitarianSmall:		template = utilitarianSmall
			case .utilitarianSmallFlat:	template = utilitarianSmallFlat
			case .utilitarianLarge:		template = utilitarianLarge
			case .extraLarge:			template = extraLarge
			case .graphicCorner:		template = graphicCorner
			case .graphicBezel:			template = graphicBezel
			case .graphicCircular:		template = graphicCircular
			case .graphicRectangular:	template = graphicRectangular
			case .graphicExtraLarge:	template = graphicExtraLarge
			@unknown default:			fatalError("Unknown complication type: \(complication.family.rawValue)")
		}
		
		template.tintColor = UIColor(named: "AccentColor")
		return template
	}
}
