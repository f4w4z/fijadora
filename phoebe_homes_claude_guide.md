# phoebe homes – claude code implementation guide

## objective

build a production-ready flutter application for a home services, property management, and furniture marketplace platform.

target:
- flutter only
- clean architecture
- scalable
- production quality
- minimalistic premium ui
- complete in approximately one week using claude code

---

# design philosophy

design language:

- uber
- linear
- notion
- stripe dashboard
- revolut
- raycast
- apple wallet
- airbnb

principles:

- almost entirely white backgrounds with dark mode support
- generous whitespace
- rounded corners (12-16px)
- very few colors
- typography first
- subtle shadows only
- smooth 60fps animations
- bottom navigation
- large touch targets
- cards instead of heavy borders
- skeleton loading
- shimmer placeholders
- native feeling

avoid:

- gradients
- glassmorphism
- neumorphism
- excessive animations
- colorful dashboards
- clutter
- unnecessary icons

---

# technology stack

## frontend

Flutter (stable)
Riverpod
GoRouter
Freezed
json_serializable
Dio
Flutter Hooks
Cached Network Image
Flutter Map
Google Fonts
Hive

## backend

Supabase

Use:

- Authentication
- PostgreSQL
- Realtime
- Storage
- Edge Functions
- Row Level Security

Avoid Firebase.

---

# APIs

Maps:
Google Maps SDK

Notifications:
Firebase Cloud Messaging

Payments:
Stripe

AI:
Google Gemini 2.5 Flash

Voice AI:
Vapi

Image Understanding:
Gemini Vision

Object Storage:
Supabase Storage

Analytics:
PostHog

Crash Reporting:
Firebase Crashlytics

Logging:
Sentry

Search:
Postgres Full Text Search

---

# architecture

lib/
 core/
 features/
 shared/
 services/
 models/
 repositories/
 widgets/
 theme/

Each feature owns:

- ui
- repository
- datasource
- models
- providers

Use repository pattern.

---

# user roles

Customer
Worker
Admin
Manager

Separate navigation and permissions.

---

# core modules

## authentication

- Email
- Google Sign In
- Role based login

## home

Two primary tabs

Services

Shop

Quick actions

Upcoming bookings

Orders

Notifications

---

## services

Raise maintenance request.

Trades:

- Plumbing
- Electrical
- Carpentry
- Painting
- HVAC
- Cleaning
- General Repairs

Request flow

Photos

Description

Schedule

Address

Submit

---

## job lifecycle

Pending

Assigned

Worker En Route

Worker Arrived

In Progress

Waiting Approval

Completed

Rejected

Cancelled

Realtime updates.

---

## worker app

Today's jobs

Navigation

Start job

Timer

Upload photos

Notes

Complete job

Offline support.

---

## live tracking

Realtime worker location.

Customer sees

ETA

Worker profile

Rating

Vehicle (optional)

---

## home profile

Digital home record.

Store

Rooms

Appliances

Paint

Furniture

Maintenance history

Photos

Warranty

Predictive reminders.

---

## AI

Photo diagnosis.

Generate:

Problem summary

Required tools

Suggested parts

Priority

Estimated duration

Furniture recommendation from room photo.

Predictive maintenance reminders.

---

## shop

Categories

Wishlist

Bundles

Product page

Reviews

Reservations

Deposits

Inventory

---

## orders

Track status

Invoices

Payment history

Refunds

---

## admin

Dashboard

Job queue

Worker management

Inventory

Analytics

Complaints

Users

Roles

Broadcasts

---

## analytics

Revenue

Response time

Completion rate

Worker performance

Popular products

Complaint trends

---

# database

Tables:

users
properties
rooms
appliances
jobs
job_images
workers
worker_locations
products
orders
payments
reviews
notifications
maintenance_history
wishlists

Use UUIDs everywhere.

---

# coding standards

Never duplicate code.

Use immutable models.

Use extension methods.

Prefer composition.

Keep widgets under 200 lines.

Business logic outside UI.

No magic numbers.

No inline SQL.

---

# performance

Lazy loading

Pagination

Image compression

Optimistic updates

Caching

Background sync

Realtime only where needed

---

# security

Row Level Security

JWT auth

Signed URLs

Input validation

Role permissions

Encrypted secrets

---

# deliverables

Week goal:

1. Authentication
2. Home
3. Services
4. Worker Flow
5. Shop
6. Admin
7. Payments
8. AI
9. Notifications
10. Polish

Always generate clean, maintainable, production-ready Flutter code with proper documentation and reusable components.
