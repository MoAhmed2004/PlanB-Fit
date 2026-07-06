<h1 align="center">🏋️‍♂️ PlanB Fit — Never Skip A Rep</h1>

<p align="center">
  <strong>An AI-powered Flutter app that ensures your workout never gets derailed.</strong>
</p>

> When a gym machine is busy, get an instant biomechanically equivalent alternative. Need a routine? Let AI generate one in 30 seconds.

---

## ✨ What It Does

*   🤖 **Plan B AI Generator:** Machine busy? Input the occupied equipment and instantly get a personalized alternative matched to your profile, injuries, and available gear. Earn +30 XP per alternative.
*   ⚡ **AI Routine Generator:** No routine? Answer 5 quick questions (goal, fitness level, schedule, equipment, injuries) and get a complete personalized training plan in under 30 seconds. Supports PPL, Upper/Lower, Full Body, Bro Split, or "Let AI Decide."
*   🧠 **Smart Features:** XP & streak system for motivation, real-time gym occupancy dashboard, injury-aware constraints, and offline-first local storage.

## 🛠️ Tech Stack

*   **Frontend:** Flutter (Dart) with Provider state management
*   **AI Backend:** Manus AI API (async task polling for production-ready mobile integration)
*   **Local Storage:** SharedPreferences for offline persistence
*   **UI Theme:** Dark mode with neon accents (cyberpunk aesthetic)

## 🎯 Key Features

- [x] Instant AI alternative exercise generation
- [x] Personalized routine generation (< 30 seconds)
- [x] XP & daily streak gamification
- [x] Real-time gym occupancy tracking
- [x] Injury-aware AI constraints
- [x] Offline-first architecture
- [x] Dark mode UI optimized for gym use

## 🏗️ Architecture

```text
Flutter App
│
└──> Manus AI Service (async task API)
     ├── task.create (send prompt)
     ├── task.detail (poll status)
     └── task.listMessages (fetch result)
         │
         └──> Manus AI Backend
              ├── Plan B alternative generation
              ├── Routine generation
              └── Structured JSON responses
```

## 🚀 Getting Started

### Prerequisites 
To run this project, you will need your own Manus AI API key. 

### Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/MoAhmed2004/PlanB-Fit.git](https://github.com/MoAhmed2004/PlanB-Fit.git)
    ```
```bash
cd planb_fit
flutter pub get
flutter run
```


## 🔗 API Integration
The app uses Manus AI's async task API for production-ready mobile integration:

*  task.create — Send a structured prompt with user constraints

*  task.detail — Poll every 3 seconds until the task completes

*  task.listMessages — Fetch the final AI response as structured JSON

This pattern avoids timeouts on mobile and works offline-first.

## 🗺️ Future Roadmap

[ ] Google Calendar auto-scheduling

[ ] Wearable integration (Apple Watch, Wear OS)

[ ] Social features (share routines, compete on streaks)

[ ] Advanced gym occupancy ML predictions

[ ] Nutrition tracking integration

[ ] Voice commands for hands-free operation
