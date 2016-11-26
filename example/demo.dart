library darteventkitdemo;

import 'dart:convert';
import 'package:darteventkit/darteventkit.dart';

class Event {
  String title;
  String location;
  String notes;
  DateTime startDate;
  DateTime endDate;
  num duration;

  Event.fromMap(Map values) {
    title = values.containsKey("title") ? values["title"] : "";
    location = values.containsKey("location") ? values["location"] : "";
    notes = values.containsKey("notes") ? values["notes"] : "";
    startDate = DateTime.parse(values["startDate"]);
    endDate = DateTime.parse(values["endDate"]);
    duration = num.parse(values["duration"]);
  }
}

void main() {
    // fetch events from calendar named "Demo" from today back to 2 years
    var eventJson = calendarEvents("Demo");

    List<Event> events = [];
    JSON.decode(eventJson)
        .forEach((values) => events.add(new Event.fromMap(values)));

    events.forEach((event) => print("${event.title} : ${event.startDate}-${event.endDate} (${event.duration} mins)"));
}