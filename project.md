# Buddhimotta — Project Overview

## What is it?
A **Multiple Intelligence Test app in Bangla (Bengali)**, based on Howard Gardner's Theory of Multiple Intelligences. Users take tests across 8 intelligence categories, get scored, and receive career guidance based on their top 3 intelligences.

---

## Current Stack (React Native / Expo)
- **Framework:** Expo ~52 / React Native 0.76
- **Auth & DB:** Firebase 10 (Auth + Firestore)
- **Navigation:** React Navigation v6 (Stack + Bottom Tabs)
- **Charts:** react-native-chart-kit (PieChart + BarChart)
- **Language:** JavaScript (JSX)
- **Location:** `Buddhimotta---Multiple-Intelligence-Test-App-Bangla/`

## New Stack (Flutter — planned)
- **Framework:** Flutter (already scaffolded at root)
- **Auth & DB:** Firebase Flutter SDK (firebase_auth + cloud_firestore)
- **Navigation:** go_router or Navigator 2.0
- **Charts:** fl_chart
- **Language:** Dart

---

## App Screens & Features

### Auth Flow (unauthenticated)
| Screen | File |
|--------|------|
| Login | `src/Login/Login.jsx` |
| Sign Up | `src/Login/SignUp.jsx` |
| Terms & Conditions | `src/Terms&Condition/Terms.jsx` |

### Main App (authenticated — Bottom Tab Navigator)
| Screen | File |
|--------|------|
| Home Screen | `src/pages/HomeScreen/HomeScreen.jsx` |
| Introduction (Theory) | `src/pages/Introduction/Intro.jsx` |
| About Us | `src/pages/About Us/AboutUs.jsx` |
| Student Classes | `src/pages/StudentClasses/StudentClasses.jsx` |

### Intelligence Tests (8 categories)
All 8 tests share the same reusable `TestScreen` component (`src/components/TestScreen.jsx`).
Each test is paginated (questions split across multiple screens).

| Test | Screen |
|------|--------|
| Musical-Rhythmic | `src/pages/Test/Musical.jsx` |
| Verbal-Linguistic | `src/pages/Test/Linguistic.jsx` |
| Visual-Spatial | `src/pages/Test/Visual.jsx` |
| Logical-Mathematical | `src/pages/Test/Logical.jsx` |
| Bodily-Kinesthetic | `src/pages/Test/Kinesthetic.jsx` |
| Interpersonal | `src/pages/Test/Interpersonal.jsx` |
| Intrapersonal | `src/pages/Test/Intrapersonal.jsx` |
| Naturalistic | `src/pages/Test/Naturalistic.jsx` |

### Real Life Scenarios
| Screen | File |
|--------|------|
| Scenario Test | `src/pages/RealLifeScenarios/RealLifeScenarios.jsx` |
| Scenario Result | `src/pages/RealLifeScenarios/ScenarioResult.jsx` |
| Score History | `src/pages/RealLifeScenarios/ScoreHistory.jsx` |

### Results
| Screen | File |
|--------|------|
| Individual Result | `src/Result/Result.jsx` |
| All Results | `src/Result/AllResult.jsx` |

### Teacher Dashboard
| Screen | File |
|--------|------|
| Teacher Dashboard | `src/pages/TeacherDashboard/TeacherDashboard.jsx` |

---

## Scoring Logic (important — non-trivial)
Located in `src/Result/Result.jsx` → `calculateScore()`.

- Each question has a `type`: `high` or `low`
- Likert scale: "দৃঢ়ভাবে একমত নই" → "দৃঢ়ভাবে একমত" (5 options)
- Score ranges: low type (1–5), high type (2–10)
- Max possible score per category: **70**
- Scores are adjusted after calculation:
  - If top score ≤ 60%: top 3 get +30/+20/+10, bottom 3 get -10
  - If top score ≤ 80%: top 3 get +15/+10/+5, bottom 3 get -10
  - If top score ≤ 90%: top 1 gets +5, bottom 3 get -10
  - If top score > 90%: no adjustment
- Scores saved to Firestore: `users/{uid}` document

---

## Firebase Config
- Project ID: `buddhimotta-e7d07`
- Services used: Auth, Firestore
- Config file: `src/firebaseConfig.js`

---

## Data
- All test questions: `data.json` (root of RN project)
- Scenario data: `src/pages/RealLifeScenarios/scenarioData.js`

---

## Color Palette
| Color | Hex | Usage |
|-------|-----|-------|
| Purple | `#951B7C` | Primary buttons, headers |
| Dark Purple | `#5C4996` | Sub-headers |
| Yellow | `#F2CB05` | Musical test background |
| Green | `#36A633` | Selected option highlight |
| Pink | `#E43C8F` | Intrapersonal |

---

## Flutter Migration Plan

### Why convert?
- Better long-term performance (especially on Android — key market)
- Stronger Dart type safety vs JavaScript
- Flutter Firebase SDK is first-class and well-maintained
- `fl_chart` handles pie + bar charts cleanly
- Flutter scaffold already exists at the root
- Single codebase → iOS + Android + Web

### Migration effort
- **Low effort:** Auth screens, navigation structure, test screens (1 reusable widget replaces 8 identical components), data layer (JSON + Firestore)
- **Medium effort:** Result screen (charts, score display, Bengali text layout)
- **Higher effort:** Scoring algorithm (must be ported carefully, logic has edge cases), Teacher Dashboard, Real Life Scenarios with history

### Key Flutter packages needed
```yaml
dependencies:
  firebase_core: latest
  firebase_auth: latest
  cloud_firestore: latest
  go_router: latest        # navigation
  fl_chart: latest         # pie + bar charts
  google_fonts: latest     # Bengali font support (Hind Siliguri)
```

### Recommended approach
1. Keep RN app as reference — do NOT delete until Flutter version is fully tested
2. Port data layer first (Firebase config, Firestore service)
3. Build reusable `TestScreen` widget — covers all 8 tests
4. Port auth flow
5. Port scoring logic with unit tests
6. Port result screen with charts
7. Port Teacher Dashboard + Real Life Scenarios last
