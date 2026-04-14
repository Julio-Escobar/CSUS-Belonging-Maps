# Belonging Maps - Complete Database Schema & ERD

## Project Overview

A mobile application that helps students/community members discover and connect with campus and community resources (organizations, cultural centers, support groups, etc.) with location-based mapping, social media integration, and user engagement features.

---

## Entity Relationship Diagram (ERD)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          BELONGING MAPS - ERD                                 │
└──────────────────────────────────────────────────────────────────────────────┘

                            ┌─────────────────────┐
                            │       User          │
                            ├─────────────────────┤
                            │ id (PK)             │
                            │ email               │
                            │ password (hash)     │
                            │ firstName           │
                            │ lastName            │
                            │ profileImageUrl     │
                            │ bio                 │
                            │ campus (CSUS/etc)   │
                            │ role (student/admin)│
                            │ interests[]         │
                            │ createdAt           │
                            │ updatedAt           │
                            └─────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
        ┌─────────────────┐  ┌──────────────┐  ┌──────────────┐
        │  Favorites      │  │   Reviews    │  │  Bookmarks   │
        ├─────────────────┤  ├──────────────┤  ├──────────────┤
        │ id (PK)         │  │ id (PK)      │  │ id (PK)      │
        │ userId (FK)     │  │ userId (FK)  │  │ userId (FK)  │
        │ orgId (FK)      │  │ orgId (FK)   │  │ orgId (FK)   │
        │ createdAt       │  │ rating       │  │ createdAt    │
        └─────────────────┘  │ comment      │  └──────────────┘
                             │ images[]     │
                             │ createdAt    │
                             │ updatedAt    │
                             └──────────────┘

                    ┌─────────────────────────┐
                    │    Organization         │
                    ├─────────────────────────┤
                    │ id (PK)                 │
                    │ name                    │
                    │ description             │
                    │ category (enum)         │
                    │ imageUrl                │
                    │ coverImageUrl           │
                    │ latitude                │
                    │ longitude               │
                    │ address                 │
                    │ phone                   │
                    │ email                   │
                    │ website                 │
                    │ establishedYear         │
                    │ memberCount             │
                    │ rating (avg)            │
                    │ verifiedStatus          │
                    │ tags[]                  │
                    │ operatingHours{}        │
                    │ createdAt               │
                    │ updatedAt               │
                    └─────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┬──────────────────┐
        │                   │                   │                  │
        ▼                   ▼                   ▼                  ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐ ┌──────────────┐
│  SocialMedia     │ │  Location    │ │    Gallery       │ │   Event      │
├──────────────────┤ ├──────────────┤ ├──────────────────┤ ├──────────────┤
│ id (PK)          │ │ id (PK)      │ │ id (PK)          │ │ id (PK)      │
│ orgId (FK)       │ │ orgId (FK)   │ │ orgId (FK)       │ │ orgId (FK)   │
│ platform         │ │ type         │ │ imageUrl         │ │ title        │
│ url              │ │ buildingName │ │ caption          │ │ description  │
│ icon             │ │ floor        │ │ uploadedBy       │ │ startDate    │
│ followers        │ │ room         │ │ createdAt        │ │ endDate      │
│ createdAt        │ │ coordinates  │ │ updatedAt        │ │ location     │
│                  │ │ createdAt    │ │                  │ │ capacity     │
│                  │ │              │ │                  │ │ registrations│
│                  │ │              │ │                  │ │ createdAt    │
└──────────────────┘ └──────────────┘ └──────────────────┘ └──────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    ADMIN & MODERATION                             │
└──────────────────────────────────────────────────────────────────┘

                    ┌──────────────────┐
                    │  AdminUser       │
                    ├──────────────────┤
                    │ id (PK)          │
                    │ userId (FK)      │
                    │ role (mod/admin) │
                    │ permissions[]    │
                    │ createdAt        │
                    └──────────────────┘
                            │
                ┌───────────┴────────────┐
                ▼                        ▼
        ┌──────────────┐        ┌──────────────┐
        │  ReportFlag  │        │  Announcement│
        ├──────────────┤        ├──────────────┤
        │ id (PK)      │        │ id (PK)      │
        │ type         │        │ title        │
        │ contentId    │        │ content      │
        │ reportedBy   │        │ priority     │
        │ reason       │        │ adminId (FK) │
        │ status       │        │ createdAt    │
        │ createdAt    │        │ expiresAt    │
        └──────────────┘        └──────────────┘
```

---

## Complete UML Class Diagram

```
╔════════════════════════════════════════════════════════════════════════════╗
║                    BELONGING MAPS - UML CLASS DIAGRAM                       ║
╚════════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────┐
│              User                           │
├─────────────────────────────────────────────┤
│ - id: String (UUID)                         │
│ - email: String                             │
│ - passwordHash: String                      │
│ - firstName: String                         │
│ - lastName: String                          │
│ - profileImageUrl: String?                  │
│ - bio: String?                              │
│ - campus: String (enum)                     │
│ - role: UserRole (student/faculty/staff)   │
│ - interests: List<String> (tags)            │
│ - favorites: List<String> (orgIds)          │
│ - bookmarks: List<String> (orgIds)          │
│ - createdAt: DateTime                       │
│ - updatedAt: DateTime                       │
│ - lastLoginAt: DateTime?                    │
├─────────────────────────────────────────────┤
│ + getFullName(): String                     │
│ + addFavorite(orgId): Future<void>          │
│ + removeFavorite(orgId): Future<void>       │
│ + addBookmark(orgId): Future<void>          │
│ + submitReview(Review): Future<void>        │
│ + getProfile(): UserProfile                 │
│ + updateProfile(data): Future<void>         │
│ + logout(): Future<void>                    │
└─────────────────────────────────────────────┘

┌───────────────────────────────────────────────────┐
│           Organization                            │
├───────────────────────────────────────────────────┤
│ - id: String (UUID)                               │
│ - name: String                                    │
│ - description: String                             │
│ - category: OrgCategory (enum)                    │
│   (Campus Organization, Cultural Center,          │
│    Support Group, Academic Club, etc)             │
│ - imageUrl: String?                               │
│ - coverImageUrl: String?                          │
│ - latitude: double                                │
│ - longitude: double                               │
│ - address: String                                 │
│ - phone: String?                                  │
│ - email: String?                                  │
│ - website: String?                                │
│ - establishedYear: int?                           │
│ - memberCount: int                                │
│ - rating: double (0-5)                            │
│ - reviewCount: int                                │
│ - verifiedStatus: bool                            │
│ - tags: List<String>                              │
│ - operatingHours: Map<String, TimeRange>          │
│ - socialLinks: List<SocialMedia>                  │
│ - locations: List<Location>                       │
│ - events: List<Event>                             │
│ - gallery: List<GalleryImage>                     │
│ - createdAt: DateTime                             │
│ - updatedAt: DateTime                             │
├───────────────────────────────────────────────────┤
│ + getLocation(): LatLng                           │
│ + getCategory(): String                           │
│ + getSocialLinks(): List<SocialMedia>             │
│ + getEvents(): List<Event>                        │
│ + getReviews(): List<Review>                      │
│ + getAverageRating(): double                      │
│ + getDistance(userLocation): double               │
│ + isOpen(now): bool                               │
│ + getOperatingHours(): Map<String, String>        │
│ + updateInfo(data): Future<void>                  │
│ + addEvent(event): Future<void>                   │
│ + uploadImage(image): Future<void>                │
└───────────────────────────────────────────────────┘

┌──────────────────────────────────────┐
│        SocialMedia                   │
├──────────────────────────────────────┤
│ - id: String (UUID)                  │
│ - organizationId: String (FK)         │
│ - platform: SocialPlatform (enum)    │
│   (Instagram, Facebook, Twitter,      │
│    TikTok, YouTube, LinkedIn)         │
│ - url: String                         │
│ - followers: int?                     │
│ - lastUpdated: DateTime?              │
│ - createdAt: DateTime                 │
├──────────────────────────────────────┤
│ + getIcon(): IconData                 │
│ + getPlatformName(): String           │
│ + openUrl(): Future<void>             │
│ + getFollowerCount(): int             │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│         Location                     │
├──────────────────────────────────────┤
│ - id: String (UUID)                  │
│ - organizationId: String (FK)         │
│ - locationType: String                │
│   (campus, community, satellite)      │
│ - buildingName: String?               │
│ - floor: int?                         │
│ - room: String?                       │
│ - latitude: double                    │
│ - longitude: double                   │
│ - accessibility: AccessibilityInfo    │
│ - parkingInfo: String?                │
│ - description: String?                │
│ - createdAt: DateTime                 │
├──────────────────────────────────────┤
│ + getCoordinates(): LatLng            │
│ + getDisplayName(): String            │
│ + getAddress(): String                │
│ + getDirections(): String (URL)       │
│ + isAccessible(): bool                │
│ + getDistance(from): double           │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│        Review (Rating)               │
├──────────────────────────────────────┤
│ - id: String (UUID)                  │
│ - organizationId: String (FK)         │
│ - userId: String (FK)                 │
│ - rating: int (1-5)                   │
│ - title: String?                      │
│ - comment: String                     │
│ - images: List<String>?               │
│ - upvotes: int                        │
│ - downvotes: int                      │
│ - verified: bool                      │
│ - createdAt: DateTime                 │
│ - updatedAt: DateTime                 │
├──────────────────────────────────────┤
│ + getSentiment(): String              │
│ + upvote(): void                      │
│ + downvote(): void                    │
│ + delete(): Future<void>              │
│ + flag(reason): Future<void>          │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│          Event                       │
├──────────────────────────────────────┤
│ - id: String (UUID)                  │
│ - organizationId: String (FK)         │
│ - title: String                       │
│ - description: String                 │
│ - imageUrl: String?                   │
│ - startDate: DateTime                 │
│ - endDate: DateTime?                  │
│ - location: Location                  │
│ - capacity: int?                      │
│ - registrations: int                  │
│ - tags: List<String>                  │
│ - isRecurring: bool                   │
│ - recurrenceRule: String? (RRULE)     │
│ - createdAt: DateTime                 │
│ - updatedAt: DateTime                 │
├──────────────────────────────────────┤
│ + register(userId): Future<void>      │
│ + unregister(userId): Future<void>    │
│ + getAttendees(): List<User>          │
│ + isUpcoming(): bool                  │
│ + getNextOccurrence(): DateTime       │
│ + shareEvent(): Future<void>          │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│       GalleryImage                   │
├──────────────────────────────────────┤
│ - id: String (UUID)                  │
│ - organizationId: String (FK)         │
│ - imageUrl: String                    │
│ - thumbnailUrl: String                │
│ - caption: String?                    │
│ - uploadedBy: String (userId)         │
│ - tags: List<String>                  │
│ - createdAt: DateTime                 │
│ - updatedAt: DateTime                 │
├──────────────────────────────────────┤
│ + delete(): Future<void>              │
│ + updateCaption(text): Future<void>   │
│ + share(): Future<void>               │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│    Notification                      │
├──────────────────────────────────────┤
│ - id: String (UUID)                  │
│ - userId: String (FK)                 │
│ - type: NotificationType (enum)       │
│ - title: String                       │
│ - body: String                        │
│ - relatedId: String? (orgId/eventId)  │
│ - imageUrl: String?                   │
│ - isRead: bool                        │
│ - actionUrl: String?                  │
│ - createdAt: DateTime                 │
├──────────────────────────────────────┤
│ + markAsRead(): Future<void>          │
│ + delete(): Future<void>              │
│ + navigate(): void                    │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│    ReportFlag (Moderation)           │
├──────────────────────────────────────┤
│ - id: String (UUID)                  │
│ - reportType: ReportType (enum)       │
│   (Inappropriate, Spam, Abuse,        │
│    Harassment, Copyright)             │
│ - contentId: String                   │
│ - contentType: String (review/org)    │
│ - reportedBy: String (userId)         │
│ - reason: String                      │
│ - description: String?                │
│ - status: ReportStatus (pending/...)  │
│ - resolvedBy: String? (adminId)       │
│ - resolution: String?                 │
│ - createdAt: DateTime                 │
│ - resolvedAt: DateTime?               │
├──────────────────────────────────────┤
│ + resolve(action): Future<void>       │
│ + reject(): Future<void>              │
│ + getReport(): Report                 │
└──────────────────────────────────────┘
```

---

## Database Schema (PostgreSQL)

```sql
-- ============================================
-- USERS & AUTHENTICATION
-- ============================================

CREATE TYPE user_role AS ENUM ('student', 'faculty', 'staff', 'community');
CREATE TYPE user_campus AS ENUM ('csus', 'uc_davis', 'uc_berkeley', 'other');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    profile_image_url VARCHAR(500),
    bio TEXT,
    campus user_campus DEFAULT 'csus',
    role user_role DEFAULT 'student',
    interests TEXT[], -- JSON array of tags
    verified BOOLEAN DEFAULT false,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP -- soft delete
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_campus ON users(campus);

-- ============================================
-- ORGANIZATIONS
-- ============================================

CREATE TYPE org_category AS ENUM (
    'campus_organization',
    'cultural_center',
    'support_group',
    'academic_club',
    'professional_society',
    'community_resource',
    'cultural_affinity',
    'mental_health',
    'career_services',
    'tutoring',
    'housing',
    'dining',
    'other'
);

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category org_category NOT NULL,
    image_url VARCHAR(500),
    cover_image_url VARCHAR(500),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    address VARCHAR(500),
    phone VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(500),
    established_year INTEGER,
    member_count INTEGER DEFAULT 0,
    rating DECIMAL(3, 2) DEFAULT 0, -- 0-5
    review_count INTEGER DEFAULT 0,
    verified BOOLEAN DEFAULT false,
    tags TEXT[], -- JSON array
    operating_hours JSONB, -- {monday: {open: "9:00", close: "17:00"}, ...}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_org_category ON organizations(category);
CREATE INDEX idx_org_location ON organizations USING GIST(ll_to_earth(latitude, longitude));
CREATE INDEX idx_org_verified ON organizations(verified);
CREATE INDEX idx_org_name ON organizations USING GIN(to_tsvector('english', name || ' ' || description));

-- ============================================
-- SOCIAL MEDIA
-- ============================================

CREATE TYPE social_platform AS ENUM (
    'instagram',
    'facebook',
    'twitter',
    'tiktok',
    'youtube',
    'linkedin',
    'snapchat',
    'discord',
    'slack'
);

CREATE TABLE social_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    platform social_platform NOT NULL,
    url VARCHAR(500) NOT NULL,
    followers INTEGER,
    last_updated TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, platform)
);

CREATE INDEX idx_social_org ON social_media(organization_id);

-- ============================================
-- LOCATIONS
-- ============================================

CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    location_type VARCHAR(50), -- campus, community, satellite
    building_name VARCHAR(255),
    floor INTEGER,
    room VARCHAR(50),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    accessibility_info JSONB, -- {wheelchair_access: true, elevator: true, ...}
    parking_info TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_location_org ON locations(organization_id);
CREATE INDEX idx_location_coordinates ON locations USING GIST(ll_to_earth(latitude, longitude));

-- ============================================
-- REVIEWS & RATINGS
-- ============================================

CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    comment TEXT,
    images VARCHAR(500)[], -- Array of image URLs
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    verified BOOLEAN DEFAULT false, -- Student verification
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE(organization_id, user_id) -- One review per user per org
);

CREATE INDEX idx_review_org ON reviews(organization_id);
CREATE INDEX idx_review_user ON reviews(user_id);
CREATE INDEX idx_review_rating ON reviews(rating);
CREATE INDEX idx_review_created ON reviews(created_at DESC);

-- ============================================
-- EVENTS
-- ============================================

CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    location_id UUID REFERENCES locations(id),
    capacity INTEGER,
    registration_count INTEGER DEFAULT 0,
    tags TEXT[],
    is_recurring BOOLEAN DEFAULT false,
    recurrence_rule VARCHAR(500), -- RRULE format for iCalendar
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_event_org ON events(organization_id);
CREATE INDEX idx_event_date ON events(start_date DESC);
CREATE INDEX idx_event_location ON events(location_id);

-- ============================================
-- EVENT REGISTRATIONS
-- ============================================

CREATE TABLE event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    attended BOOLEAN DEFAULT false,
    UNIQUE(event_id, user_id)
);

CREATE INDEX idx_registration_event ON event_registrations(event_id);
CREATE INDEX idx_registration_user ON event_registrations(user_id);

-- ============================================
-- GALLERY IMAGES
-- ============================================

CREATE TABLE gallery_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    caption TEXT,
    uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gallery_org ON gallery_images(organization_id);
CREATE INDEX idx_gallery_uploader ON gallery_images(uploaded_by);

-- ============================================
-- FAVORITES & BOOKMARKS
-- ============================================

CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, organization_id)
);

CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_org ON favorites(organization_id);

CREATE TABLE bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, organization_id)
);

CREATE INDEX idx_bookmarks_user ON bookmarks(user_id);
CREATE INDEX idx_bookmarks_org ON bookmarks(organization_id);

-- ============================================
-- NOTIFICATIONS
-- ============================================

CREATE TYPE notification_type AS ENUM (
    'review_response',
    'event_reminder',
    'new_event',
    'organization_update',
    'message',
    'favorite_updated'
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    related_id UUID, -- orgId, eventId, reviewId
    image_url VARCHAR(500),
    is_read BOOLEAN DEFAULT false,
    action_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notification_user ON notifications(user_id);
CREATE INDEX idx_notification_unread ON notifications(user_id, is_read);

-- ============================================
-- MODERATION & REPORTING
-- ============================================

CREATE TYPE report_type AS ENUM (
    'inappropriate_content',
    'spam',
    'abuse_harassment',
    'copyright_violation',
    'misinformation',
    'off_topic'
);

CREATE TYPE report_status AS ENUM (
    'pending',
    'investigating',
    'resolved',
    'rejected',
    'closed'
);

CREATE TABLE report_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type report_type NOT NULL,
    content_id UUID NOT NULL, -- reviewId, orgId, eventId
    content_type VARCHAR(50), -- review, organization, event
    reported_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    description TEXT,
    status report_status DEFAULT 'pending',
    resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    resolution TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

CREATE INDEX idx_report_status ON report_flags(status);
CREATE INDEX idx_report_created ON report_flags(created_at DESC);

CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    priority VARCHAR(50), -- high, medium, low
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- ============================================
-- ADMIN USERS
-- ============================================

CREATE TYPE admin_role AS ENUM (
    'moderator',
    'admin',
    'super_admin'
);

CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    admin_role admin_role NOT NULL,
    permissions TEXT[], -- JSON array of permission strings
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_admin_role ON admin_users(admin_role);

-- ============================================
-- ACTIVITY LOGS (for analytics)
-- ============================================

CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100),
    entity_type VARCHAR(50),
    entity_id UUID,
    metadata JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activity_user ON activity_logs(user_id);
CREATE INDEX idx_activity_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_created ON activity_logs(created_at DESC);

-- ============================================
-- SEARCH INDICES (for full-text search)
-- ============================================

CREATE INDEX idx_org_search ON organizations USING GIN(
    to_tsvector('english',
        coalesce(name, '') || ' ' ||
        coalesce(description, '') || ' ' ||
        array_to_string(tags, ' ')
    )
);

CREATE INDEX idx_event_search ON events USING GIN(
    to_tsvector('english',
        coalesce(title, '') || ' ' ||
        coalesce(description, '') || ' ' ||
        array_to_string(tags, ' ')
    )
);
```

---

## Dart Models Implementation

```dart
// lib/models/user.dart
enum UserRole { student, faculty, staff, community }
enum UserCampus { csus, ucDavis, ucBerkeley, other }

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImageUrl;
  final String? bio;
  final UserCampus campus;
  final UserRole role;
  final List<String> interests;
  final List<String> favoriteOrgIds;
  final List<String> bookmarkOrgIds;
  final bool verified;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
    this.bio,
    this.campus = UserCampus.csus,
    this.role = UserRole.student,
    this.interests = const [],
    this.favoriteOrgIds = const [],
    this.bookmarkOrgIds = const [],
    this.verified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String getFullName() => '$firstName $lastName';

  toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'profileImageUrl': profileImageUrl,
    'bio': bio,
    'campus': campus.toString(),
    'role': role.toString(),
    'interests': interests,
    'verified': verified,
  };
}

// lib/models/organization.dart
enum OrgCategory {
  campusOrganization,
  culturalCenter,
  supportGroup,
  academicClub,
  professionalSociety,
  communityResource,
  culturalAffinity,
  mentalHealth,
  careerServices,
  tutoring,
  housing,
  dining,
  other
}

class Organization {
  final String id;
  final String name;
  final String description;
  final OrgCategory category;
  final String? imageUrl;
  final String? coverImageUrl;
  final double latitude;
  final double longitude;
  final String address;
  final String? phone;
  final String? email;
  final String? website;
  final int? establishedYear;
  final int memberCount;
  final double rating;
  final int reviewCount;
  final bool verified;
  final List<String> tags;
  final Map<String, TimeRange>? operatingHours;
  final List<SocialMedia> socialLinks;
  final List<Location> locations;
  final List<Event> events;
  final List<GalleryImage> gallery;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.imageUrl,
    this.coverImageUrl,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.phone,
    this.email,
    this.website,
    this.establishedYear,
    this.memberCount = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.verified = false,
    this.tags = const [],
    this.operatingHours,
    this.socialLinks = const [],
    this.locations = const [],
    this.events = const [],
    this.gallery = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  LatLng getLocation() => LatLng(latitude, longitude);

  bool isOpen() {
    // Check if organization is open right now
    return true; // TODO: implement
  }
}

// lib/models/event.dart
class Event {
  final String id;
  final String organizationId;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final Location? location;
  final int? capacity;
  final int registrationCount;
  final List<String> tags;
  final bool isRecurring;
  final String? recurrenceRule;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.startDate,
    this.endDate,
    this.location,
    this.capacity,
    this.registrationCount = 0,
    this.tags = const [],
    this.isRecurring = false,
    this.recurrenceRule,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isUpcoming() => startDate.isAfter(DateTime.now());
}

// lib/models/review.dart
class Review {
  final String id;
  final String organizationId;
  final String userId;
  final int rating; // 1-5
  final String? title;
  final String comment;
  final List<String>? images;
  final int upvotes;
  final int downvotes;
  final bool verified;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.rating,
    this.title,
    required this.comment,
    this.images,
    this.upvotes = 0,
    this.downvotes = 0,
    this.verified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String getSentiment() {
    if (rating >= 4) return 'Positive';
    if (rating == 3) return 'Neutral';
    return 'Negative';
  }
}

// lib/models/social_media.dart
enum SocialPlatform {
  instagram,
  facebook,
  twitter,
  tiktok,
  youtube,
  linkedin,
  snapchat,
  discord,
  slack
}

class SocialMedia {
  final String id;
  final SocialPlatform platform;
  final String url;
  final int? followers;

  SocialMedia({
    required this.id,
    required this.platform,
    required this.url,
    this.followers,
  });

  IconData getIcon() {
    switch (platform) {
      case SocialPlatform.instagram:
        return FontAwesomeIcons.instagram;
      case SocialPlatform.facebook:
        return FontAwesomeIcons.facebook;
      case SocialPlatform.twitter:
        return FontAwesomeIcons.twitter;
      case SocialPlatform.tiktok:
        return FontAwesomeIcons.tiktok;
      case SocialPlatform.youtube:
        return FontAwesomeIcons.youtube;
      case SocialPlatform.linkedin:
        return FontAwesomeIcons.linkedin;
      case SocialPlatform.snapchat:
        return FontAwesomeIcons.snapchat;
      case SocialPlatform.discord:
        return FontAwesomeIcons.discord;
      case SocialPlatform.slack:
        return FontAwesomeIcons.slack;
    }
  }

  String getPlatformName() => platform.toString().split('.').last;
}

// lib/models/location.dart
class Location {
  final String id;
  final String organizationId;
  final String? buildingName;
  final int? floor;
  final String? room;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? accessibilityInfo;
  final String? parkingInfo;
  final String? description;
  final DateTime createdAt;

  Location({
    required this.id,
    required this.organizationId,
    this.buildingName,
    this.floor,
    this.room,
    required this.latitude,
    required this.longitude,
    this.accessibilityInfo,
    this.parkingInfo,
    this.description,
    required this.createdAt,
  });

  LatLng getCoordinates() => LatLng(latitude, longitude);

  String getDisplayName() {
    if (buildingName != null && floor != null && room != null) {
      return '$buildingName, Floor $floor, Room $room';
    } else if (buildingName != null) {
      return buildingName!;
    }
    return 'Location';
  }

  bool isWheelchairAccessible() {
    return (accessibilityInfo?['wheelchair_access'] as bool?) ?? false;
  }
}

// lib/models/notification.dart
enum NotificationType {
  reviewResponse,
  eventReminder,
  newEvent,
  organizationUpdate,
  message,
  favoriteUpdated
}

class Notification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? relatedId;
  final String? imageUrl;
  final bool isRead;
  final String? actionUrl;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.imageUrl,
    this.isRead = false,
    this.actionUrl,
    required this.createdAt,
  });
}
```

---

## API Endpoints Summary

```
# Authentication
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
GET    /api/auth/profile
PUT    /api/auth/profile

# Organizations
GET    /api/organizations
GET    /api/organizations/:id
GET    /api/organizations/search?q=term
GET    /api/organizations/nearby?lat=X&lng=Y&radius=5km
POST   /api/organizations (admin)
PUT    /api/organizations/:id (admin)
DELETE /api/organizations/:id (admin)

# Events
GET    /api/events
GET    /api/events/:id
GET    /api/events/upcoming
GET    /api/organizations/:orgId/events
POST   /api/events/:id/register
DELETE /api/events/:id/register

# Reviews
GET    /api/organizations/:orgId/reviews
POST   /api/organizations/:orgId/reviews
PUT    /api/reviews/:id
DELETE /api/reviews/:id
POST   /api/reviews/:id/upvote
POST   /api/reviews/:id/downvote

# User Actions
POST   /api/users/:userId/favorites/:orgId
DELETE /api/users/:userId/favorites/:orgId
POST   /api/users/:userId/bookmarks/:orgId
DELETE /api/users/:userId/bookmarks/:orgId

# Notifications
GET    /api/notifications
PUT    /api/notifications/:id/read
DELETE /api/notifications/:id

# Search & Discovery
GET    /api/search?q=term&category=campus_organization&sort=rating
GET    /api/trending
GET    /api/recommendations

# Moderation (admin)
POST   /api/reports
GET    /api/admin/reports
PUT    /api/admin/reports/:id/resolve
POST   /api/admin/announcements
```

---

## Implementation Priority

### Phase 1 (MVP - Current)

- [x] User authentication
- [x] Organization profiles
- [x] Map view with locations
- [x] Social media links
- [x] Location information
- [ ] Review/rating system

### Phase 2 (Soon)

- [ ] Event management
- [ ] User favorites/bookmarks
- [ ] Basic notifications
- [ ] Search functionality

### Phase 3 (Future)

- [ ] Event registration system
- [ ] Gallery/images
- [ ] Admin moderation
- [ ] Advanced analytics
- [ ] Messaging system
- [ ] Recommendations engine

---

This gives you a complete, scalable database structure for the Belonging Maps application!
