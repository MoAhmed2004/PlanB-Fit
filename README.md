# planb_fit

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


# PlanB Fit — Never Skip A Rep

An AI-powered Flutter app that ensures your workout never gets derailed. When a gym machine is busy, get an instant biomechanically equivalent alternative. Need a routine? Let AI generate one in 30 seconds.

## What It Does

**Plan B AI Generator** — Machine busy? Input the occupied equipment and instantly get a personalized alternative matched to your profile, injuries, and available gear. Earn +30 XP per alternative.

**AI Routine Generator** — No routine? Answer 5 quick questions (goal, fitness level, schedule, equipment, injuries) and get a complete personalized training plan in under 30 seconds. Supports PPL, Upper/Lower, Full Body, Bro Split, or "Let AI Decide."

**Vision Routine Extractor** — Upload a screenshot of any workout routine (table, PDF, coach's plan) and the app converts it to an interactive exercise list using vision AI.

**Smart Features** — XP & streak system for motivation, real-time gym occupancy dashboard, injury-aware constraints, Google Calendar integration for auto-scheduling, and offline-first local storage.

## Tech Stack

- **Frontend:** Flutter (Dart) with Provider state management
- **AI Backend:** Manus AI API (async task polling for production-ready mobile integration)
- **Vision AI:** Multimodal AI for image-to-routine extraction
- **Local Storage:** SharedPreferences for offline persistence
- **UI Theme:** Dark mode with neon accents (cyberpunk aesthetic)

## Key Features

- ✅ Instant AI alternative exercise generation
- ✅ Personalized routine generation (< 30 seconds)
- ✅ Image-to-routine vision extraction
- ✅ XP & daily streak gamification
- ✅ Real-time gym occupancy tracking
- ✅ Injury-aware AI constraints
- ✅ Google Calendar integration (planned)
- ✅ Offline-first architecture
- ✅ Dark mode UI optimized for gym use

## Architecture

