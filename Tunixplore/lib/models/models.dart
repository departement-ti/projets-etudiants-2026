// ──────────────────────────────────────────
// USER ROLE
// ──────────────────────────────────────────
enum UserRole { visitor, organiserParticular, organiserAgency }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final UserRole role;
  final String? agencyName;
  final String? agencyLicense;
  final int loyaltyPoints;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.role,
    this.agencyName,
    this.agencyLicense,
    this.loyaltyPoints = 0,
  });

  static UserRole userRoleFromString(String role) {
    switch (role) {
      case 'organiserParticular':
        return UserRole.organiserParticular;
      case 'organiserAgency':
        return UserRole.organiserAgency;
      default:
        return UserRole.visitor;
    }
  }

  static String userRoleToString(UserRole role) {
    switch (role) {
      case UserRole.organiserParticular:
        return 'organiserParticular';
      case UserRole.organiserAgency:
        return 'organiserAgency';
      case UserRole.visitor:
        return 'visitor';
    }
  }

  factory UserModel.fromJson(String id, Map<String, dynamic> json) {
    return UserModel(
      id: id,
      name: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      role: UserModel.userRoleFromString(json['role'] ?? 'visitor'),
      agencyName: json['agencyName'],
      agencyLicense: json['agencyLicense'],
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
    );
  }
}

// ──────────────────────────────────────────
// TUNISIAN PLACE / SITE MODEL
// ──────────────────────────────────────────
class PlaceModel {
  final String id;
  final String name;
  final String region;
  final String imageUrl;
  final String description;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final double latitude;
  final double longitude;
  final bool isFeatured;
  final String openingHours;
  final String entryFee;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.region,
    required this.imageUrl,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    required this.latitude,
    required this.longitude,
    this.isFeatured = false,
    required this.openingHours,
    required this.entryFee,
  });

  factory PlaceModel.fromJson(String id, Map<String, dynamic> json) {
    return PlaceModel(
      id: id,
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      latitude: (json['lat'] ?? 0).toDouble(),
      longitude: (json['lng'] ?? 0).toDouble(),
      isFeatured: json['isFeatured'] ?? false,
      openingHours: json['openingHours'] ?? '',
      entryFee: json['entryFee'] ?? '',
    );
  }
}

// ──────────────────────────────────────────
// EVENT / TOUR MODEL
// ──────────────────────────────────────────
enum EventType { visit, tour, festival, workshop, adventure, cultural }

class EventModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> gallery;
  final String organiserId;
  final String organiserName;
  final String organiserAvatar;
  final EventType type;
  final String location;
  final String region;
  final double latitude;
  final double longitude;
  final String date;
  final String startTime;
  final String duration;
  final String price;
  final int maxParticipants;
  final int currentParticipants;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final List<String> includes;
  final bool isOnline;
  final String language;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.gallery,
    required this.organiserId,
    required this.organiserName,
    required this.organiserAvatar,
    required this.type,
    required this.location,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.startTime,
    required this.duration,
    required this.price,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    required this.includes,
    this.isOnline = false,
    required this.language,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static EventType eventTypeFromString(String type) {
    switch (type) {
      case 'visit':
        return EventType.visit;
      case 'tour':
        return EventType.tour;
      case 'festival':
        return EventType.festival;
      case 'workshop':
        return EventType.workshop;
      case 'adventure':
        return EventType.adventure;
      case 'cultural':
        return EventType.cultural;
      default:
        return EventType.visit;
    }
  }

  static String eventTypeToString(EventType type) {
    return type.name;
  }

  factory EventModel.fromJson(String id, Map<String, dynamic> json) {
    return EventModel(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      gallery: List<String>.from(json['gallery'] ?? []),
      organiserId: json['organiserId'] ?? '',
      organiserName: json['organiserName'] ?? '',
      organiserAvatar: json['organiserAvatar'] ?? '',
      type: eventTypeFromString(json['type'] ?? 'visit'),
      location: json['location'] ?? '',
      region: json['region'] ?? '',
      latitude: _toDouble(json['lat']),
      longitude: _toDouble(json['lng']),
      date: json['date'],
      startTime: json['startTime'] ?? '',
      duration: json['duration'] ?? '',
      price: json['price'],
      maxParticipants: json['maxParticipants'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      rating: _toDouble(json['rating']),
      reviewCount: json['reviewCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      includes: List<String>.from(json['includes'] ?? []),
      isOnline: json['isOnline'] ?? false,
      language: json['language'] ?? 'fr',
    );
  }

  int get spotsLeft => maxParticipants - currentParticipants;
  bool get isFull => spotsLeft <= 0;
}

// ──────────────────────────────────────────
// REGISTRATION (PARTICIPATION) MODEL
// ──────────────────────────────────────────
enum RegistrationStatus { upcoming, completed, cancelled }

class RegistrationModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String eventImage;
  final String eventDate;
  final String eventLocation;
  final String price;
  final RegistrationStatus status;
  final int participants;
  final EventType? eventType;

  const RegistrationModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventImage,
    required this.eventDate,
    required this.eventLocation,
    required this.price,
    required this.status,
    required this.participants,
    this.eventType,
  });

  factory RegistrationModel.fromMap(String id, Map<String, dynamic> data) {
    return RegistrationModel(
      id: id,
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      eventImage: data['eventImage'] ?? '',
      eventDate: data['eventDate'] ?? '',
      eventLocation: data['eventLocation'] ?? '',
      price: data['price'] ?? '0',
      participants: (data['participants'] ?? 1).toInt(),
      status: _statusFromString(data['status'] ?? 'upcoming'),
      eventType: _eventTypeFromString(data['eventType']),
    );
  }

  // ─────────────────────────────
  // HELPERS
  // ─────────────────────────────
  static RegistrationStatus _statusFromString(String value) {
    switch (value) {
      case 'completed':
        return RegistrationStatus.completed;
      case 'cancelled':
        return RegistrationStatus.cancelled;
      default:
        return RegistrationStatus.upcoming;
    }
  }

  static EventType? _eventTypeFromString(dynamic value) {
    if (value == null) return null;

    try {
      return EventType.values.firstWhere((e) => e.name == value.toString());
    } catch (_) {
      return null;
    }
  }
}

// ──────────────────────────────────────────
// NOTIFICATION MODEL
// ──────────────────────────────────────────
enum NotificationType { registration, promotion, reminder, alert, newEvent }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

// ──────────────────────────────────────────
// REVIEW MODEL
// ──────────────────────────────────────────
class ReviewModel {
  final String id;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final String date;
  final String targetName;
  final String authorName;

  const ReviewModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.date,
    required this.targetName,
    required this.authorName,
  });
}

// ──────────────────────────────────────────
// CHAT MESSAGE MODEL
// ──────────────────────────────────────────
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime time;

  final String type; // text, event_card, registration_card, wishlist_card
  final Map<String, dynamic>? data;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.type = "text",
    this.data,
  });
}

// ──────────────────────────────────────────
// CHAT RESPONSE MODEL
// ──────────────────────────────────────────

class ChatResponse {
  final String text;
  final String type; // "text" | "list" | "event" | "registrations" | "wishlist"
  final List<Map<String, dynamic>> items;

  ChatResponse({required this.text, required this.type, required this.items});
}

// ──────────────────────────────────────────
// ITINERARY MODEL
// ──────────────────────────────────────────
class ItineraryStep {
  final String time;
  final String title;
  final String description;
  final String placeId;

  const ItineraryStep({
    required this.time,
    required this.title,
    required this.description,
    required this.placeId,
  });
}

class ItineraryModel {
  final String id;
  final String title;
  final String duration;
  final List<String> regions;
  final List<ItineraryStep> steps;
  final String difficulty;
  final String imageUrl;

  const ItineraryModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.regions,
    required this.steps,
    required this.difficulty,
    required this.imageUrl,
  });
}
