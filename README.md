# SmartSpend 💰

> **AI-Powered Expense Tracker** with Receipt Scanning & Spending Insights  
> Built with Flutter • Riverpod • Hive • Gemini AI

A production-quality Flutter application that helps users track expenses manually or via AI-powered receipt scanning, with intelligent spending analysis powered by Google Gemini 2.5 Flash.

---

## 📱 App Overview

SmartSpend is a full-featured expense tracker designed with **clean architecture**, premium UI, and AI-powered automation. The app works fully offline for expense management, with optional Gemini AI integration for receipt scanning and spending insights.

### Key Highlights
- 🧾 **AI Receipt Scanner** — Point camera at any receipt, AI extracts all details
- 📊 **AI Spending Insights** — Natural-language financial reports with charts
- 🔍 **Smart Search & Filter** — Find any expense instantly
- 📤 **CSV Export** — Export data and share via any app
- 🌙 **Dark/Light Mode** — Premium themed UI with animations
- 📱 **Offline-First** — All data stored locally, works without internet (except AI features)

---

## ✨ Feature Details

### Feature 1: AI Receipt Scanner
Implemented using **Google Gemini 2.5 Flash** multimodal model.

| Capability | Implementation |
|---|---|
| Capture from camera | `image_picker` with `ImageSource.camera` |
| Select from gallery | `image_picker` with `ImageSource.gallery` |
| AI data extraction | Gemini multimodal (image + text prompt → structured JSON) |
| Extracts Merchant Name | ✅ Parsed from JSON response |
| Extracts Date | ✅ Parsed in YYYY-MM-DD format |
| Extracts Amount | ✅ Numeric extraction with decimal handling |
| Extracts Category | ✅ Maps to one of 6 categories |
| Auto-fill expense form | ✅ Each field fills independently |
| Review & edit before saving | ✅ Editable TextFormFields + category picker |
| Handle invalid AI responses | ✅ JSON parse error handling, graceful fallback to empty `ReceiptData` |
| Error state with retry | ✅ Retry with same image or start over |

**Key file:** [`gemini_receipt_service.dart`](lib/features/receipt_scanner/data/services/gemini_receipt_service.dart)

### Feature 2: AI Spending Insights
Generates comprehensive spending reports using Gemini AI.

| Capability | Implementation |
|---|---|
| Analyze all transactions | ✅ Groups expenses by month, builds structured text summary |
| Natural-language report | ✅ Markdown-formatted report from Gemini |
| Total spending | ✅ Included in AI prompt + stats card in UI |
| Category-wise breakdown | ✅ Interactive **pie chart** with `fl_chart` + AI report |
| Largest expenses | ✅ AI identifies top 3 largest expenses |
| Spending trends | ✅ **Monthly bar chart** (last 6 months) + AI pattern analysis |
| Actionable recommendations | ✅ AI provides 2+ specific, practical suggestions |
| Generate on demand | ✅ "Generate Report" button, not auto-generated |

**Key file:** [`gemini_insights_service.dart`](lib/features/insights/data/services/gemini_insights_service.dart)

### Core: Expense Management

| Feature | Implementation |
|---|---|
| Add expenses manually | ✅ Form with validation (merchant, amount, date, category, notes) |
| Edit expenses | ✅ Tap any expense card → opens pre-filled edit form |
| Delete expenses | ✅ Swipe-to-delete with confirmation dialog + **undo via SnackBar** |
| View expense history | ✅ Scrollable list with **date-grouped sections** (Today, Yesterday, This Week, etc.) |
| Categorize expenses | ✅ 6 categories with custom icons and colors |
| Search expenses | ✅ Real-time search by merchant name, category, or notes |
| Filter by category | ✅ Horizontal FilterChip row |
| Export to CSV | ✅ Generates `.csv` file and opens system share sheet |

### Categories
| Category | Icon | Color |
|---|---|---|
| 🍔 Food | `restaurant_rounded` | Orange |
| 🛍️ Shopping | `shopping_bag_rounded` | Pink |
| ✈️ Travel | `flight_rounded` | Blue |
| ⚡ Utilities | `electrical_services_rounded` | Amber |
| 🎬 Entertainment | `movie_rounded` | Purple |
| 📦 Others | `category_rounded` | Grey |

---

## 🏗️ Architecture

### Clean Architecture (Feature-First)

The app follows **Clean Architecture** principles with a **feature-first** directory structure. Each feature is self-contained with its own data, domain, and presentation layers.

```
lib/
├── core/                              # Shared utilities & design system
│   ├── constants/
│   │   └── app_constants.dart         # ExpenseCategory enum, HiveBoxes, AppConstants
│   ├── theme/
│   │   ├── app_colors.dart            # Curated color palette with category colors
│   │   └── app_theme.dart             # Material 3 dark/light themes with Google Fonts
│   ├── utils/
│   │   ├── formatters.dart            # Currency (₹), date, relative date formatting
│   │   └── csv_exporter.dart          # CSV generation + share_plus integration
│   └── widgets/
│       ├── shared_widgets.dart        # GlassCard, EmptyState, LoadingOverlay, CategoryChip
│       └── splash_screen.dart         # Animated splash with scale/fade/slide
│
├── features/
│   ├── expenses/                      # Core expense management feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── expense_model.dart          # Hive TypeAdapter model
│   │   │   │   └── expense_model.g.dart        # Generated adapter (build_runner)
│   │   │   └── repositories/
│   │   │       └── hive_expense_repository.dart # Hive implementation
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── expense.dart                # Pure Dart entity (no framework deps)
│   │   │   └── repositories/
│   │   │       └── expense_repository.dart     # Abstract interface
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── expense_providers.dart      # StateNotifier + search/filter + chart data
│   │       └── screens/
│   │           ├── expense_list_screen.dart     # Main list with search, filter, date groups
│   │           └── add_edit_expense_screen.dart # Form with validation
│   │
│   ├── receipt_scanner/               # AI receipt scanning feature
│   │   ├── data/
│   │   │   └── services/
│   │   │       └── gemini_receipt_service.dart  # Gemini multimodal image → JSON
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── scanner_providers.dart       # Scanning state machine
│   │       └── screens/
│   │           └── receipt_scanner_screen.dart  # Scanner UI with 4 states
│   │
│   ├── insights/                      # AI insights & visualization feature
│   │   ├── data/
│   │   │   └── services/
│   │   │       └── gemini_insights_service.dart # Expense summary → AI analysis
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── insights_providers.dart      # Insights state management
│   │       └── screens/
│   │           └── insights_screen.dart         # Bar chart + pie chart + AI report
│   │
│   └── settings/                      # App configuration feature
│       └── presentation/
│           ├── providers/
│           │   └── settings_providers.dart      # API key + theme persistence
│           └── screens/
│               └── settings_screen.dart         # API key input, theme toggle, about
│
└── main.dart                          # Entry point, Hive init, ProviderScope, navigation
```

### Layer Responsibilities

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTATION                        │
│  Screens (UI) → Providers (State) → Widgets         │
│  • ConsumerWidget / ConsumerStatefulWidget           │
│  • StateNotifierProvider for reactive state          │
├─────────────────────────────────────────────────────┤
│                    DOMAIN                            │
│  Entities (pure Dart) + Repository interfaces        │
│  • No framework dependencies                         │
│  • Business rules and data contracts                 │
├─────────────────────────────────────────────────────┤
│                     DATA                             │
│  Models (Hive) + Repository implementations          │
│  • Hive TypeAdapters for serialization               │
│  • Gemini API services for AI features               │
└─────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack & Rationale

| Component | Choice | Why |
|-----------|--------|-----|
| **State Management** | `flutter_riverpod` | Type-safe, no BuildContext dependency, auto-dispose, testable |
| **Local Storage** | `hive_ce_flutter` | Lightweight NoSQL, fast reads/writes, schema-based with TypeAdapters |
| **AI Model** | Gemini 2.5 Flash | Free tier, multimodal (image+text), fast response times |
| **Charts** | `fl_chart` | Highly customizable, supports pie charts and bar charts with gradients |
| **Image Capture** | `image_picker` | Camera + gallery support, image compression |
| **CSV Export** | `share_plus` | Native share sheet integration across Android/iOS |
| **Typography** | `google_fonts` (Inter) | Modern, readable, professional typeface |
| **Architecture** | Clean Architecture | Separation of concerns, dependency inversion, testable layers |

---

## 🧩 Engineering Decisions

### 1. Repository Pattern with Dependency Inversion
```dart
// Domain layer defines the contract (no Hive dependency)
abstract class ExpenseRepository {
  Future<List<Expense>> getAllExpenses();
  Future<void> addExpense(Expense expense);
  ...
}

// Data layer implements it (can swap Hive for SQLite/API without touching domain)
class HiveExpenseRepository implements ExpenseRepository { ... }
```

### 2. Runtime API Key (Not Hardcoded)
The Gemini API key is stored in Hive at runtime via the Settings screen. This:
- Avoids exposing secrets in source code
- Allows the app to work fully (CRUD) without an API key
- AI features gracefully show "Add API key" prompts when key is missing

### 3. Graceful AI Error Handling
```dart
// Receipt scanner handles partial data — each field fills independently
if (data.merchantName != null) _merchantCtrl.text = data.merchantName!;
if (data.amount != null) _amountCtrl.text = data.amount!.toStringAsFixed(2);
if (data.date != null) _scannedDate = data.date!;

// JSON parsing handles markdown code blocks from Gemini
if (jsonStr.contains('```json')) {
  jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
}
```

### 4. Package Imports Over Relative Imports
All imports use `package:smart_spend/...` instead of relative `../../../` paths. This avoids fragile path resolution in deeply nested feature directories.

### 5. Reactive Search & Filter with Riverpod
```dart
// Search and filter are separate StateProviders
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<ExpenseCategory?>((ref) => null);

// Filtered list derives from both — auto-updates reactively
final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryFilterProvider);
  // ... applies both filters
});
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10+
- Android/iOS device or emulator
- (Optional) Gemini API key for AI features

### Setup
```bash
# 1. Clone the repository
git clone <repo-url>
cd ThinkAlernate

# 2. Install dependencies
flutter pub get

# 3. Generate Hive TypeAdapters
dart run build_runner build

# 4. Run on connected device
flutter run
```

### Enable AI Features
1. Get a free API key from [Google AI Studio](https://aistudio.google.com/apikey)
2. Open the app → **Settings** tab → paste key → tap Save 💾
3. Scanner & Insights will activate immediately

---

## 📦 Dependencies

```yaml
# State Management
flutter_riverpod: ^2.6.1

# Local Storage
hive_ce: ^2.7.0
hive_ce_flutter: ^2.1.0

# AI Integration
google_generative_ai: ^0.4.6

# Image Capture
image_picker: ^1.1.2

# Data Visualization
fl_chart: ^0.70.2

# Utilities
uuid: ^4.5.1          # Unique expense IDs
intl: ^0.20.2         # Currency & date formatting
google_fonts: ^6.2.1  # Typography (Inter)
path_provider: ^2.1.5 # File system access
share_plus: ^10.1.4   # CSV export sharing

# Dev Dependencies
hive_ce_generator: ^1.6.0  # Hive TypeAdapter code generation
build_runner: ^2.4.14       # Code generation runner
```

---

## 📱 Screens

| # | Screen | Description |
|---|--------|-------------|
| 1 | **Splash** | Animated launch screen with brand identity |
| 2 | **Expenses** | Dashboard with monthly summary card, search bar, category filters, date-grouped expense list |
| 3 | **Add/Edit** | Form with validation, date picker, category selector, notes field |
| 4 | **Scanner** | AI receipt scanning with camera/gallery, loading animation, result preview & edit |
| 5 | **Insights** | Stats cards, monthly bar chart, category pie chart, AI spending report |
| 6 | **Settings** | API key management, dark/light mode toggle, app info |

---

## ✅ Code Quality

```
$ flutter analyze
Analyzing ThinkAlernate...
No issues found! ✓
```

- **0 errors, 0 warnings, 0 info messages**
- Package imports used throughout for reliable resolution
- All widgets properly dispose controllers and animations
- Consistent code style and documentation

---

Built with ❤️ using Flutter
