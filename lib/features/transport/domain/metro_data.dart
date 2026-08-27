import 'package:flutter/material.dart';

class MetroStation {
  final String name;
  final bool isInterchange;
  final double lat;
  final double lng;

  const MetroStation({
    required this.name,
    this.isInterchange = false,
    required this.lat,
    required this.lng,
  });
}

class MetroLine {
  final String id;
  final String name;
  final Color color;
  final List<MetroStation> stations;

  const MetroLine({
    required this.id,
    required this.name,
    required this.color,
    required this.stations,
  });
}

class MetroData {
  static const List<MetroLine> lines = [
    MetroLine(
      id: 'blue',
      name: 'Blue Line (Line 1)',
      color: Colors.blue,
      stations: [
        MetroStation(name: 'Dakshineswar', lat: 22.6542, lng: 88.3562),
        MetroStation(name: 'Baranagar', lat: 22.6457, lng: 88.3693),
        MetroStation(name: 'Noapara', isInterchange: true, lat: 22.6402, lng: 88.3916),
        MetroStation(name: 'Dum Dum', lat: 22.6225, lng: 88.3948),
        MetroStation(name: 'Belgachia', lat: 22.6056, lng: 88.3881),
        MetroStation(name: 'Shyambazar', lat: 22.6001, lng: 88.3732),
        MetroStation(name: 'Shobhabazar Sutanuti', lat: 22.5934, lng: 88.3662),
        MetroStation(name: 'Girish Park', lat: 22.5855, lng: 88.3615),
        MetroStation(name: 'Mahatma Gandhi Road', lat: 22.5794, lng: 88.3585),
        MetroStation(name: 'Central', lat: 22.5714, lng: 88.3551),
        MetroStation(name: 'Chandni Chowk', lat: 22.5663, lng: 88.3524),
        MetroStation(name: 'Esplanade', isInterchange: true, lat: 22.5623, lng: 88.3512),
        MetroStation(name: 'Park Street', isInterchange: true, lat: 22.5539, lng: 88.3496),
        MetroStation(name: 'Maidan', lat: 22.5471, lng: 88.3477),
        MetroStation(name: 'Rabindra Sadan', lat: 22.5398, lng: 88.3457),
        MetroStation(name: 'Netaji Bhavan', lat: 22.5323, lng: 88.3444),
        MetroStation(name: 'Jatin Das Park', lat: 22.5255, lng: 88.3435),
        MetroStation(name: 'Kalighat', lat: 22.5186, lng: 88.3429),
        MetroStation(name: 'Rabindra Sarobar', lat: 22.5089, lng: 88.3430),
        MetroStation(name: 'Mahanayak Uttam Kumar', lat: 22.4965, lng: 88.3441),
        MetroStation(name: 'Netaji', lat: 22.4849, lng: 88.3496),
        MetroStation(name: 'Masterda Surya Sen', lat: 22.4764, lng: 88.3582),
        MetroStation(name: 'Gitanjali', lat: 22.4682, lng: 88.3712),
        MetroStation(name: 'Kavi Nazrul', lat: 22.4623, lng: 88.3811),
        MetroStation(name: 'Shahid Khudiram', lat: 22.4665, lng: 88.3934),
        MetroStation(name: 'Kavi Subhash', isInterchange: true, lat: 22.4729, lng: 88.4048),
      ],
    ),
    MetroLine(
      id: 'green_east',
      name: 'Green Line (Line 2 - East)',
      color: Colors.green,
      stations: [
        MetroStation(name: 'Salt Lake Sector V', lat: 22.5794, lng: 88.4347),
        MetroStation(name: 'Karunamoyee', lat: 22.5833, lng: 88.4234),
        MetroStation(name: 'Central Park', lat: 22.5857, lng: 88.4116),
        MetroStation(name: 'City Centre', lat: 22.5878, lng: 88.4044),
        MetroStation(name: 'Bengal Chemical', lat: 22.5804, lng: 88.4027),
        MetroStation(name: 'Salt Lake Stadium', lat: 22.5714, lng: 88.4011),
        MetroStation(name: 'Phoolbagan', lat: 22.5701, lng: 88.3887),
        MetroStation(name: 'Sealdah', lat: 22.5695, lng: 88.3711),
      ],
    ),
    MetroLine(
      id: 'green_west',
      name: 'Green Line (Line 2 - West)',
      color: Colors.green,
      stations: [
        MetroStation(name: 'Howrah Maidan', lat: 22.5898, lng: 88.3344),
        MetroStation(name: 'Howrah', isInterchange: true, lat: 22.5839, lng: 88.3424),
        MetroStation(name: 'Mahakaran', lat: 22.5746, lng: 88.3475),
        MetroStation(name: 'Esplanade', isInterchange: true, lat: 22.5623, lng: 88.3512),
      ],
    ),
    MetroLine(
      id: 'purple',
      name: 'Purple Line (Line 3)',
      color: Colors.purple,
      stations: [
        MetroStation(name: 'Joka', lat: 22.4571, lng: 88.3075),
        MetroStation(name: 'Thakurpukur', lat: 22.4678, lng: 88.3101),
        MetroStation(name: 'Sakherbazar', lat: 22.4776, lng: 88.3142),
        MetroStation(name: 'Behala Chowrasta', lat: 22.4891, lng: 88.3175),
        MetroStation(name: 'Behala Bazar', lat: 22.5023, lng: 88.3211),
        MetroStation(name: 'Taratala', lat: 22.5135, lng: 88.3243),
        MetroStation(name: 'Majerhat', isInterchange: true, lat: 22.5221, lng: 88.3276),
      ],
    ),
    MetroLine(
      id: 'orange',
      name: 'Orange Line (Line 6)',
      color: Colors.orange,
      stations: [
        MetroStation(name: 'Kavi Subhash', isInterchange: true, lat: 22.4729, lng: 88.4048),
        MetroStation(name: 'Satyajit Ray', lat: 22.4821, lng: 88.4035),
        MetroStation(name: 'Jyotirindra Nandi', lat: 22.4925, lng: 88.4021),
        MetroStation(name: 'Kavi Sukanta', lat: 22.5011, lng: 88.4005),
        MetroStation(name: 'Hemayati Mukhopadhyay', lat: 22.5112, lng: 88.3991),
      ],
    ),
  ];

  static List<String> getAllStations() {
    final Set<String> stations = {};
    for (var line in lines) {
      for (var station in line.stations) {
        stations.add(station.name);
      }
    }
    final sorted = stations.toList()..sort();
    return sorted;
  }
}
