# Zwimm - Application Specification

## 1. Vision & Core Value Proposition
Zwimm is a Client-Server application designed to give users a clear overview of available swimming sessions (e.g. "Banenzwemmen" / Lap Swimming, Recreatief zwemmen, etc.) across multiple swimming pools for the coming week. 

Users specify a target goal (e.g., Banenzwemmen) and a search location (current GPS or manual location + radius range), and Zwimm aggregates and presents all matching swimming opportunities in a consolidated weekly schedule.

---

## 2. System Architecture Overview

Architecture consists of two main pillars:
1. **Backend Server (Nightly Aggregator & API)**
   - Runs nightly cron jobs to scrape/fetch/parse opening hours & schedules from swimming pools within target regions.
   - Normalizes schedule data (Pool Name, Address, Geolocation, Activity Type, Start/End Time, Date).
   - Serves REST API for the mobile client.
   - Fully testable and deployable on Linux servers (e.g., in Docker containers).

2. **iOS Client App (iPhone / SwiftUI)**
   - Allows user to set preferred activity (e.g., "Banenzwemmen").
   - Location filtering: Current GPS location or custom fixed location + search radius (in km).
   - Weekly view showing aggregated swim slots ordered by date, time, and distance.
   - Offline caching for instant loading.

---

## 3. Detailed Specifications

### A. Backend Server Component
- **Nightly Scraping & Sync**: Cron job triggered every night (e.g., 02:00 AM).
- **Data Model**:
  - `Pool`: ID, Name, Address, Latitude, Longitude, Website, SourceURL
  - `ScheduleSlot`: ID, PoolID, ActivityType (Banenzwemmen, etc.), StartTime, EndTime, Date, Notes
- **API Endpoints**:
  - `GET /api/v1/pools?lat={lat}&lng={lng}&radius={km}`
  - `GET /api/v1/schedules?lat={lat}&lng={lng}&radius={km}&activity={type}&startDate={YYYY-MM-DD}&endDate={YYYY-MM-DD}`

### B. iPhone Client App Component
- **Settings / Preferences**:
  - Activity selection (Default: Banenzwemmen).
  - Search location (Current GPS location vs User-defined address/city).
  - Radius slider (e.g., 5 km - 50 km).
- **Schedule Screen**:
  - Filtered view for the coming week (7-day horizon).
  - Grouped by day (Today, Tomorrow, [Weekday]).
  - Cards displaying: Swimming pool name, distance (km), time slot (e.g. 07:00 - 08:30), and activity.
  - Map view toggle showing swimming pool pins within radius.

---

## 4. Development & Testing Plan
- **Linux Backend / Shared Models**:
  - Develop backend API + scrapers / data parsers in Swift (SPM) or Node.js/Python on the Linux server.
  - Testable locally via Docker / `swift test`.
- **iOS Client**:
  - SwiftUI frontend using shared Swift data models where applicable.
  - Evaluated locally via SPM logic tests and verified via macOS CI/CD pipeline.
