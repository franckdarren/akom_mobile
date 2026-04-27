# Akôm Scanner — Application Mobile Flutter

## Vue d'ensemble

Application mobile compagnon du SaaS Akôm.
Cible : petits commerces, boutiques, épiceries, restaurants sans caisse enregistreuse.
Marché principal : Gabon / Afrique francophone.
Développeur : solo.

---

## Workspace structure

```
akom-workspace/
├── CLAUDE.md           ← contexte global (ce fichier est dans mobile/)
├── web/                ← App Next.js (dépôt Git séparé)
└── mobile/             ← Ce projet Flutter (dépôt Git séparé)
```

Le projet web expose les API REST consommées par cette app.
Les deux projets partagent le même projet Supabase (même URL, même anon key).

---

## Stack technique

| Élément | Choix |
|---|---|
| Framework | Flutter (Dart) |
| Gestion d'état | Riverpod |
| Navigation | Go Router |
| HTTP client | Dio |
| Auth | supabase_flutter |
| Base locale (offline) | Drift (SQLite) |
| Scanner code-barres | mobile_scanner |
| Lookup produit | Open Food Facts API (gratuit) |
| Impression thermique | flutter_thermal_printer + esc_pos_utils |
| Génération PDF | pdf + printing |
| QR Code | qr_flutter |
| Stockage local | shared_preferences (tokens, prefs légères) |
| Formatage dates | intl |

---

## Architecture des modules (ordre de livraison)

### Module 1 — Création de catalogue (priorité absolue)

Prérequis aux deux autres modules. Sans produits dans le système, rien ne fonctionne.

**Flux A — Produit avec code-barres**
```
Scanner code-barres
  → Lookup Open Food Facts API
  → Pré-remplissage : nom, description, image
  → Utilisateur saisit : prix, catégorie
  → POST /api/mobile/products → création dans Akôm
  → Confirmation + option "scanner suivant"
```

**Flux B — Produit sans code-barres (artisanal, local)**
```
Bouton "Produit manuel"
  → Formulaire : nom, prix, catégorie, photo (optionnelle)
  → Génération QR code maison (UUID produit)
  → POST /api/mobile/products → création dans Akôm
  → Option impression étiquette QR code
```

---

### Module 2 — Inventaire

**Flux**
```
Sélectionner "Faire l'inventaire"
  → Scanner produit (barcode ou QR code Akôm)
  → Affiche : stock théorique actuel
  → Utilisateur saisit : quantité physique comptée
  → Calcul écart automatique
  → PATCH /api/mobile/stock/[productId] → mise à jour
  → Continuer ou terminer la session
```

**Offline first** : Les scans sont stockés localement (Drift/SQLite).
La synchronisation se déclenche au retour de la connexion.

---

### Module 3 — Caisse légère

**Flux**
```
Sélectionner "Caisse"
  → Scanner produits du client (ou recherche textuelle)
  → Panier : quantité modifiable, suppression possible
  → Calcul total automatique (prix en FCFA)
  → Choix paiement : Cash / Airtel Money / Moov Money
  → POST /api/mobile/orders → création commande dans Akôm
  → Génération reçu PDF
  → Option impression thermique Bluetooth (si imprimante disponible)
```

**Règle importante** : La caisse fonctionne sans imprimante thermique.
Le PDF est toujours généré. L'impression est un bonus optionnel.

---

## Authentification

Supabase Auth partagé avec l'app web. Même projet Supabase.

```dart
// Initialisation dans main.dart
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
);
```

**Flux de connexion**
```
Email + mot de passe
  → supabase.auth.signInWithPassword()
  → Récupération session (access_token + refresh_token)
  → Stockage dans shared_preferences
  → Toutes les requêtes API incluent le Bearer token
```

**Gestion de session**
- Token refresh automatique via supabase_flutter
- Si session expirée → redirection vers l'écran de connexion
- Pas d'inscription dans l'app mobile : le compte est créé sur l'app web

---

## Appels API — Conventions

Tous les appels partent vers l'app web Next.js.

```dart
// Base URL
const String baseUrl = 'https://akom.app/api/mobile';

// Header obligatoire sur toutes les requêtes authentifiées
headers: {
  'Authorization': 'Bearer ${session.accessToken}',
  'Content-Type': 'application/json',
  'x-restaurant-id': currentRestaurantId, // Multi-tenant
}
```

**Endpoints consommés par l'app mobile**

| Méthode | Endpoint | Usage |
|---|---|---|
| GET | /api/mobile/products | Liste produits du restaurant |
| POST | /api/mobile/products | Créer un produit |
| PATCH | /api/mobile/products/[id] | Modifier un produit |
| GET | /api/mobile/products/barcode/[code] | Lookup produit par code-barres |
| GET | /api/mobile/stock | Stock actuel |
| PATCH | /api/mobile/stock/[productId] | Mettre à jour le stock |
| POST | /api/mobile/orders | Créer une commande (caisse) |
| GET | /api/mobile/categories | Liste des catégories |

**Ces routes sont à créer dans le projet web** avec vérification du Bearer token Supabase.

---

## Multi-tenant

L'app mobile respecte strictement le multi-tenant d'Akôm.

- Chaque requête envoie `x-restaurant-id` dans le header
- L'utilisateur peut avoir accès à plusieurs restaurants
- Un sélecteur de restaurant est affiché au démarrage si l'utilisateur en a plusieurs
- Le `restaurantId` actif est persisté dans `shared_preferences`
- Côté web : les routes `/api/mobile/*` filtrent TOUJOURS par `restaurantId` extrait du JWT ET vérifié contre `x-restaurant-id`

---

## Gestion offline (Module 1 et 2 uniquement)

La caisse (Module 3) requiert une connexion — les paiements ne peuvent pas être différés.
Le catalogue et l'inventaire supportent le mode offline.

**Stratégie avec Drift (SQLite)**

```dart
// Tables locales
- local_products     : cache des produits
- pending_products   : produits créés offline à synchroniser
- pending_stock      : ajustements stock à synchroniser
- sync_log           : journal de synchronisation
```

**Règle de synchronisation**
```
ConnectivityProvider écoute les changements réseau
  → Retour en ligne → SyncService.sync()
  → Envoie les pending_* dans l'ordre chronologique
  → En cas de conflit → la valeur locale gagne (dernier write wins)
  → Log du résultat dans sync_log
```

---

## Structure du projet Flutter

```
mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # GoRouter + providers globaux
│   │
│   ├── core/
│   │   ├── env/
│   │   │   └── env.dart            # Variables d'environnement (--dart-define)
│   │   ├── network/
│   │   │   ├── dio_client.dart     # Instance Dio + intercepteurs
│   │   │   └── connectivity.dart   # Détection réseau
│   │   ├── storage/
│   │   │   └── local_storage.dart  # shared_preferences wrapper
│   │   └── errors/
│   │       └── app_exception.dart  # Types d'erreurs unifiés
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── login_screen.dart
│   │   │       └── restaurant_picker_screen.dart
│   │   │
│   │   ├── catalog/               # Module 1 : Création catalogue
│   │   │   ├── data/
│   │   │   │   ├── product_repository.dart
│   │   │   │   └── open_food_facts_service.dart
│   │   │   ├── domain/
│   │   │   │   └── product_model.dart
│   │   │   └── presentation/
│   │   │       ├── catalog_screen.dart
│   │   │       ├── scanner_screen.dart
│   │   │       ├── product_form_screen.dart
│   │   │       └── qr_label_screen.dart
│   │   │
│   │   ├── inventory/             # Module 2 : Inventaire
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── inventory_screen.dart
│   │   │       ├── scan_count_screen.dart
│   │   │       └── inventory_summary_screen.dart
│   │   │
│   │   └── pos/                   # Module 3 : Caisse légère
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │           ├── pos_screen.dart
│   │           ├── cart_screen.dart
│   │           ├── payment_screen.dart
│   │           └── receipt_screen.dart
│   │
│   └── shared/
│       ├── widgets/               # Composants réutilisables
│       │   ├── akom_button.dart
│       │   ├── akom_text_field.dart
│       │   ├── product_tile.dart
│       │   └── loading_overlay.dart
│       ├── theme/
│       │   └── app_theme.dart     # Couleurs, typo, thème global
│       └── utils/
│           ├── fcfa_formatter.dart  # Formatage prix FCFA
│           └── date_formatter.dart  # Formatage dates français
│
├── test/
├── android/
├── ios/
├── pubspec.yaml
├── .env.development
├── .env.production
└── CLAUDE.md                      ← ce fichier
```

---

## Open Food Facts API

API gratuite, sans clé, pour le lookup de produits par code-barres.

```dart
// Exemple d'appel
const url = 'https://world.openfoodfacts.org/api/v0/product/$barcode.json';

// Réponse utile
product.product_name_fr ?? product.product_name
product.image_url
product.categories_tags
```

**Important** : Beaucoup de produits locaux gabonais ne sont PAS dans Open Food Facts.
Le fallback vers la saisie manuelle est obligatoire, pas optionnel.

---

## Impression thermique

**Phase 1 (MVP)** : Génération PDF via le package `pdf` + partage via `printing`.
L'utilisateur imprime depuis son téléphone via AirPrint, Google Cloud Print, ou partage le PDF.

**Phase 2** : Connexion Bluetooth à imprimante thermique (Xprinter, Rongta, Epson TM-m30).

```dart
// Format reçu thermique (58mm ou 80mm)
// Utiliser esc_pos_utils pour générer les commandes ESC/POS
// flutter_thermal_printer pour la connexion Bluetooth
```

**Ne jamais bloquer la caisse sur la disponibilité de l'imprimante.**
Le reçu PDF est toujours généré. L'impression est toujours optionnelle.

---

## Formatage prix

Toujours en FCFA (Franc CFA), entier, sans décimales.

```dart
// lib/shared/utils/fcfa_formatter.dart
String formatFCFA(int amount) {
  final formatter = NumberFormat('#,###', 'fr_FR');
  return '${formatter.format(amount)} FCFA';
}

// Exemples
formatFCFA(1500)   // "1 500 FCFA"
formatFCFA(25000)  // "25 000 FCFA"
```

---

## Variables d'environnement

Passées via `--dart-define` au build, jamais committées.

```dart
// lib/core/env/env.dart
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
}
```

```bash
# Développement
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=API_BASE_URL=http://localhost:3000
```

---

## Règles de développement

### Sécurité
- Ne jamais stocker le mot de passe utilisateur localement
- Le `service_role` Supabase n'est JAMAIS utilisé côté mobile
- Toujours valider la session avant chaque requête API
- Le `restaurantId` est toujours validé côté serveur, jamais faire confiance au client seul

### Performance
- Les listes de produits sont paginées (limit 50 par défaut)
- Les images produits sont lazy-loadées et cachées localement
- Le scanner camera ne tourne que quand l'écran de scan est actif

### UX — Contraintes marché gabonais
- L'app DOIT fonctionner correctement sur Android 8+ (API 26+)
- Tester sur appareils d'entrée de gamme (2GB RAM, processeur lent)
- Connexion instable : toujours afficher un état de chargement clair
- Textes en français uniquement
- Les prix sont TOUJOURS en FCFA, jamais d'autre devise

### Conventions Dart
- Nommage : `snake_case` pour fichiers, `camelCase` pour variables, `PascalCase` pour classes
- Toujours typer explicitement — pas de `dynamic` sauf cas justifié
- Un fichier = une classe principale
- Les Widgets sont `const` dès que possible

---

## Flux de démarrage de l'app

```
main.dart
  → Supabase.initialize()
  → Vérifier session locale
    → Pas de session → LoginScreen
    → Session valide
      → Récupérer liste restaurants de l'utilisateur
        → 1 restaurant → Dashboard direct
        → Plusieurs restaurants → RestaurantPickerScreen
          → Sélection → stocker restaurantId actif → Dashboard
```

---

## Ce projet NE fait PAS

- Pas de gestion des rôles (admin, gérant, employé) : géré dans l'app web
- Pas de tableau de bord statistiques : géré dans l'app web
- Pas de gestion des tables de restaurant : géré dans l'app web
- Pas de paiement mobile money intégré (SingPay) dans le MVP : cash uniquement
- Pas d'inscription : le compte se crée sur l'app web Akôm

---

## Roadmap

Légende : ✅ fait · 🔄 en cours · ⬜ à faire

**État actuel** : Phases 0–5 terminées — infrastructure, thème, auth, dashboard, catalogue complets. Prochaine étape : Phase 6 (Inventaire) ou Phase 7 (Caisse).

> **Action requise** : exécuter `dart run build_runner build --delete-conflicting-outputs` dans `mobile/` pour générer les fichiers Freezed (`*.freezed.dart`, `*.g.dart`) des modèles `ProductModel`, `CategoryModel`, `ProductDraft`.

---

### Phase W — Côté web : routes API mobiles ✅ TERMINÉ

#### W.0 Migrations Prisma (`web/prisma/schema.prisma`)

- ✅ `barcode String? @map("barcode")` ajouté sur `Product` + `@@index([restaurantId, barcode])`
- ✅ `mobile_pos` ajouté à l'enum `OrderSource`
- ✅ Client Prisma régénéré (`npx prisma generate`)
- ✅ SQL brut : `web/supabase/migrations/20260425_add_mobile_support.sql` — **à appliquer sur le dashboard Supabase**

#### W.1 Middleware d'auth mobile

- ✅ `web/lib/mobile-auth.ts`
  - `validateToken(req)` — vérifie uniquement le Bearer token (pour `/restaurants`)
  - `validateMobileRequest(req)` — vérifie token + `x-restaurant-id` + appartenance `RestaurantUser`

#### W.2 Route : restaurants

- ✅ `GET web/app/api/mobile/restaurants/route.ts`
  - Retourne `{ restaurants: [{ id, name, logoUrl, slug }] }`

#### W.3 Route : catégories

- ✅ `GET web/app/api/mobile/categories/route.ts`
  - Retourne `{ categories: [{ id, name, position }] }` (isActive, triées par position)

#### W.4 Routes : produits

- ✅ `GET web/app/api/mobile/products/route.ts` — liste paginée cursor-based (limit 50), stock inclus
- ✅ `POST web/app/api/mobile/products/route.ts` — crée `Product` + `Stock` (quantity 0) en transaction
- ✅ `PATCH web/app/api/mobile/products/[id]/route.ts` — mise à jour partielle, vérifie l'appartenance
- ✅ `GET web/app/api/mobile/products/barcode/[code]/route.ts` — retourne `{ product }` ou `{ product: null }`

#### W.5 Routes : stock

- ✅ `GET web/app/api/mobile/stock/route.ts` — stock complet avec noms et seuils d'alerte
- ✅ `PATCH web/app/api/mobile/stock/[productId]/route.ts` — ajustement absolu + `StockMovement(adjustment)` + mise à jour `isAvailable`

#### W.6 Route : commandes (caisse mobile)

- ✅ `POST web/app/api/mobile/orders/route.ts`
  - Crée `Order(source: mobile_pos, status: delivered)` + `OrderItem` + `StockMovement(sale_manual)` en une transaction
  - Retourne `{ orderId, orderNumber, totalAmount }`

---

### Phase 0 — Configuration & infrastructure de base ✅ TERMINÉE

#### 0.1 pubspec.yaml — Dépendances
- ✅ `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`
- ✅ `go_router`
- ✅ `dio`
- ✅ `supabase_flutter`
- ✅ `drift` + `drift_flutter` + `sqlite3_flutter_libs`
- ✅ `mobile_scanner`
- ✅ `qr_flutter`
- ✅ `pdf` + `printing`
- ⬜ `flutter_thermal_printer` + `esc_pos_utils_plus` — ajoutés en Phase 8 (versions à déterminer)
- ✅ `shared_preferences`
- ✅ `connectivity_plus`
- ✅ `intl`
- ✅ `cached_network_image`
- ✅ `image_picker`
- ✅ `freezed` (v3) + `freezed_annotation` (v3) + `json_serializable` (code gen)
- ✅ Dev : `build_runner`, `drift_dev`, `custom_lint`, `riverpod_lint`

#### 0.2 Configuration Android
- ✅ Bundle ID : `com.akom.scanner`
- ✅ `minSdk = 26` dans `android/app/build.gradle.kts`
- ✅ `multiDexEnabled = true` + `coreLibraryDesugaring`
- ✅ Permissions `AndroidManifest.xml` : caméra, Bluetooth (API 26+/31+), internet, `CHANGE_NETWORK_STATE`
- ✅ Nom app : `Akôm Scanner`

#### 0.3 Variables d'environnement
- ✅ `lib/core/env/env.dart` (`String.fromEnvironment`)
- ✅ `.env.development` et `.env.production` (templates, non commités via `.gitignore`)

#### 0.4 Initialisation app
- ✅ `main.dart` : `WidgetsFlutterBinding`, `Supabase.initialize()`, `ProviderScope`
- ✅ `lib/app.dart` : `GoRouter` avec routes `/login`, `/restaurants`, `/dashboard` + redirect auth
- ✅ Écrans placeholder pour les routes (remplacés en Phases 3–4)

---

### Phase 1 — Core (couche technique transverse) ✅ TERMINÉE

#### 1.1 Réseau
- ✅ `lib/core/network/dio_client.dart`
  - ✅ Instance Dio singleton (via Riverpod)
  - ✅ `BaseOptions` : `baseUrl`, timeout 30s
  - ✅ Intercepteur Auth : injection `Authorization: Bearer <token>` automatique
  - ✅ Intercepteur Restaurant : injection `x-restaurant-id` depuis `shared_preferences`
  - ✅ Intercepteur erreurs : parse `DioException` → `AppException`
  - ✅ Retry automatique sur 401 (refresh token puis retry)

#### 1.2 Connectivité
- ✅ `lib/core/network/connectivity.dart`
  - ✅ `ConnectivityProvider` (Riverpod StreamProvider)
  - ✅ Expose `isOnline` en temps réel via `connectivity_plus`

#### 1.3 Stockage local
- ✅ `lib/core/storage/local_storage.dart`
  - ✅ Wrapper `SharedPreferences` typé
  - ✅ Clés : `access_token`, `refresh_token`, `restaurant_id`, `restaurant_name`

#### 1.4 Gestion des erreurs
- ✅ `lib/core/errors/app_exception.dart`
  - ✅ Types : `NetworkException`, `AuthException`, `ServerException`, `OfflineException`, `ValidationException`
  - ✅ Messages d'erreur en français

#### 1.5 Base de données locale (Drift)
- ✅ `lib/core/database/app_database.dart`
  - ✅ Table `local_products` (cache des produits)
  - ✅ Table `pending_products` (produits créés offline à sync)
  - ✅ Table `pending_stock_entries` (ajustements stock offline)
  - ✅ Table `sync_logs` (journal de sync)
  - ✅ DAOs : `ProductDao`, `PendingProductDao`, `StockDao`, `SyncLogDao`
  - ✅ Migrations de schéma versionnées (schemaVersion = 1)
  - ✅ Code généré : `app_database.g.dart` (via `dart run build_runner build`)

#### 1.6 Synchronisation offline
- ✅ `lib/core/sync/sync_service.dart`
  - ✅ `SyncService.sync()` déclenché au retour en ligne
  - ✅ Traitement des `pending_products` dans l'ordre chronologique
  - ✅ Traitement des `pending_stock_entries`
  - ✅ Écriture dans `sync_logs` (succès / erreur)
  - ✅ Règle : conflit → valeur locale gagne (last write wins)

---

### Phase 2 — Thème & composants partagés

#### 2.1 Thème
- ✅ `lib/shared/theme/app_theme.dart`
  - ✅ Palette couleurs Akôm (couleur primaire, secondaire, fond, erreur)
  - ✅ Typographie (police, tailles, poids)
  - ✅ `ThemeData` Material 3
  - ⬜ Thème sombre (optionnel, basse priorité)

#### 2.2 Widgets réutilisables
- ✅ `lib/shared/widgets/akom_button.dart` — bouton primaire/secondaire stylisé
- ✅ `lib/shared/widgets/akom_text_field.dart` — champ de texte avec validation
- ✅ `lib/shared/widgets/product_tile.dart` — carte produit (image, nom, prix, stock)
- ✅ `lib/shared/widgets/loading_overlay.dart` — overlay de chargement bloquant
- ✅ `lib/shared/widgets/error_banner.dart` — bandeau d'erreur/offline
- ✅ `lib/shared/widgets/empty_state.dart` — état liste vide

#### 2.3 Utilitaires
- ✅ `lib/shared/utils/fcfa_formatter.dart` — `formatFCFA(int amount)`
- ✅ `lib/shared/utils/date_formatter.dart` — dates en français (`jj/mm/aaaa`, `il y a X min`)

---

### Phase 3 — Authentification

#### 3.1 Données & domaine
- ⬜ `lib/features/auth/domain/user_model.dart` (id, email, restaurantIds)
- ⬜ `lib/features/auth/domain/restaurant_model.dart` (id, name, logoUrl)
- ⬜ `lib/features/auth/data/auth_repository.dart`
  - ⬜ `signIn(email, password)` → `supabase.auth.signInWithPassword()`
  - ⬜ `signOut()` + nettoyage `shared_preferences`
  - ⬜ `currentSession` (getter)
  - ⬜ `getRestaurantsForUser()` → appel API ou Supabase direct
- ⬜ `lib/features/auth/data/auth_provider.dart` (Riverpod)
  - ⬜ `authStateProvider` écoute `supabase.auth.onAuthStateChange`
  - ⬜ `currentRestaurantIdProvider`

#### 3.2 Écrans
- ⬜ `lib/features/auth/presentation/login_screen.dart`
  - ⬜ Champ email + mot de passe
  - ⬜ Bouton "Se connecter"
  - ⬜ Gestion erreur (identifiants incorrects, réseau)
  - ⬜ État de chargement
  - ⬜ Lien "Créer un compte sur akom.app" (ouvre navigateur)
- ⬜ `lib/features/auth/presentation/restaurant_picker_screen.dart`
  - ⬜ Liste des restaurants accessibles
  - ⬜ Sélection → stockage `restaurantId` → navigation Dashboard
  - ⬜ Affiché uniquement si l'utilisateur a plusieurs restaurants

#### 3.3 Navigation & guards
- ⬜ Guard GoRouter : redirect vers `LoginScreen` si session invalide
- ⬜ Guard GoRouter : redirect vers `RestaurantPickerScreen` si pas de `restaurantId`

---

### Phase 4 — Dashboard ✅ TERMINÉE

- ✅ `lib/features/dashboard/presentation/dashboard_screen.dart`
  - ✅ 3 tuiles : Catalogue · Inventaire · Caisse
  - ✅ Indicateur de connexion (online/offline)
  - ✅ Nom du restaurant actif en header
  - ✅ Bouton changement de restaurant (toujours visible)
  - ✅ Bouton déconnexion

---

### Phase 5 — Module 1 : Catalogue ✅ TERMINÉE

#### 5.1 Domaine & données
- ✅ `lib/features/catalog/domain/product_model.dart`
  - ✅ Champs : id, name, description, price (int FCFA), categoryId, barcode, imageUrl, stock, createdAt
  - ✅ Freezed + JSON serializable
- ✅ `lib/features/catalog/domain/category_model.dart` — Freezed + JSON
- ✅ `lib/features/catalog/domain/product_draft.dart` — Freezed, `toApiJson()`, `isValid`
- ✅ `lib/features/catalog/data/open_food_facts_service.dart`
  - ✅ `lookupBarcode(String barcode)` → `ProductDraft?`
  - ✅ Parse `product_name_fr`, `image_url`, `categories_tags`
  - ✅ Retourne `null` si produit inconnu (fallback manuel obligatoire)
- ✅ `lib/features/catalog/data/product_repository.dart`
  - ✅ `getProducts({cursor})` → liste paginée cursor-based (limit 50)
  - ✅ `createProduct(ProductDraft)` → POST + sauvegarde locale
  - ✅ `updateProduct(id, ProductDraft)` → PATCH
  - ✅ `getProductByBarcode(String code)` → GET `/products/barcode/[code]`
  - ✅ Mode offline : sauvegarde dans `pending_products`, retour optimiste
  - ✅ Cache dans `local_products`
- ✅ `lib/features/catalog/data/category_repository.dart`
  - ✅ `getCategories()` → GET `/categories`

#### 5.2 Providers Riverpod
- ✅ `productsProvider` (AsyncNotifier, paginé — `ProductsNotifier`)
- ✅ `categoriesProvider` (FutureProvider.autoDispose)
- ✅ `productFormProvider` (StateNotifier.family)

#### 5.3 Écrans
- ✅ `lib/features/catalog/presentation/catalog_screen.dart`
  - ✅ Liste produits avec `ProductTile`
  - ✅ Barre de recherche (filtre local)
  - ✅ Filtre par catégorie (chips)
  - ✅ FAB : "Ajouter un produit" (→ scanner ou manuel via bottom sheet)
  - ✅ Pull-to-refresh
  - ✅ Pagination (infinite scroll, loadMore)
  - ✅ État offline (bandeau)
- ✅ `lib/features/catalog/presentation/scanner_screen.dart`
  - ✅ Prévisualisation caméra (`mobile_scanner`)
  - ✅ Détection → lookup Akôm → lookup Open Food Facts → `ProductFormScreen`
  - ✅ Torche (on/off)
  - ✅ Bouton "Saisie manuelle"
  - ✅ Caméra active uniquement quand l'écran est visible (`WidgetsBindingObserver`)
- ✅ `lib/features/catalog/presentation/product_form_screen.dart`
  - ✅ Champs : nom, description, prix (FCFA), catégorie (dropdown), image, code-barres
  - ✅ Pré-remplissage depuis Open Food Facts si disponible
  - ✅ Prise de photo (image_picker)
  - ✅ Validation : nom obligatoire, prix > 0
  - ✅ Mode création et mode édition
  - ✅ Si création sans code-barres → navigation automatique vers QR label
- ✅ `lib/features/catalog/presentation/qr_label_screen.dart`
  - ✅ Affiche le QR code (UUID du produit) via `qr_flutter`
  - ✅ Génération PDF (58mm) via `pdf` + `printing`
  - ✅ Format : nom produit + prix FCFA + QR code

---

### Phase 6 — Module 2 : Inventaire

#### 6.1 Domaine & données
- ⬜ `lib/features/inventory/domain/stock_entry_model.dart`
  - ⬜ Champs : productId, productName, theoreticalStock, countedStock, gap, scannedAt
  - ⬜ Freezed + JSON
- ⬜ `lib/features/inventory/data/inventory_repository.dart`
  - ⬜ `getCurrentStock()` → GET `/stock`
  - ⬜ `updateStock(productId, quantity)` → PATCH `/stock/[productId]`
  - ⬜ Mode offline : sauvegarde dans `pending_stock`, sync différée

#### 6.2 Providers Riverpod
- ⬜ `inventorySessionProvider` (liste des scans en cours)
- ⬜ `stockProvider`

#### 6.3 Écrans
- ⬜ `lib/features/inventory/presentation/inventory_screen.dart`
  - ⬜ Bouton "Démarrer l'inventaire"
  - ⬜ Résumé de la dernière session (date, nombre d'articles scannés)
  - ⬜ Indicateur offline
- ⬜ `lib/features/inventory/presentation/scan_count_screen.dart`
  - ⬜ Scanner code-barres ou QR code Akôm
  - ⬜ Affichage stock théorique du produit scanné
  - ⬜ Champ saisie quantité physique comptée
  - ⬜ Calcul et affichage de l'écart (positif/négatif/égal)
  - ⬜ Bouton "Valider et scanner suivant"
  - ⬜ Bouton "Terminer l'inventaire"
  - ⬜ Sauvegarde locale si offline
- ⬜ `lib/features/inventory/presentation/inventory_summary_screen.dart`
  - ⬜ Tableau récapitulatif : produit / stock théorique / compté / écart
  - ⬜ Total des écarts
  - ⬜ Bouton "Envoyer les ajustements" (POST/PATCH API)
  - ⬜ État de synchronisation (en cours, succès, erreur)

---

### Phase 7 — Module 3 : Caisse

#### 7.1 Domaine & données
- ⬜ `lib/features/pos/domain/cart_item_model.dart` (productId, name, price, quantity)
- ⬜ `lib/features/pos/domain/order_model.dart` (items, total, paymentMethod, createdAt)
- ⬜ `lib/features/pos/data/order_repository.dart`
  - ⬜ `createOrder(Order)` → POST `/orders`
  - ⬜ Pas de mode offline (connexion requise)

#### 7.2 Providers Riverpod
- ⬜ `cartProvider` (StateNotifier)
  - ⬜ `addItem(product)`
  - ⬜ `removeItem(productId)`
  - ⬜ `updateQuantity(productId, quantity)`
  - ⬜ `clearCart()`
  - ⬜ `total` (calculé)

#### 7.3 Écrans
- ⬜ `lib/features/pos/presentation/pos_screen.dart`
  - ⬜ Scanner produit (barcode/QR) ou recherche textuelle
  - ⬜ Résultats de recherche en temps réel (filtre sur `local_products`)
  - ⬜ Tap produit → ajout au panier
  - ⬜ Badge panier avec total courant
  - ⬜ Navigation vers `CartScreen`
- ⬜ `lib/features/pos/presentation/cart_screen.dart`
  - ⬜ Liste des articles : nom, prix unitaire, quantité (modifiable), sous-total
  - ⬜ Modification quantité (+ / -)
  - ⬜ Suppression article (swipe ou icône)
  - ⬜ Total TTC en FCFA (grand, visible)
  - ⬜ Bouton "Valider la vente" → `PaymentScreen`
  - ⬜ Bouton "Continuer les achats" → retour `PosScreen`
- ⬜ `lib/features/pos/presentation/payment_screen.dart`
  - ⬜ Affichage total à payer
  - ⬜ Sélection mode de paiement : Cash / Airtel Money / Moov Money
  - ⬜ Champ montant reçu (pour Cash) → calcul de la monnaie rendue
  - ⬜ Bouton "Confirmer le paiement" → `createOrder()` → `ReceiptScreen`
  - ⬜ Gestion erreur réseau (afficher message, ne pas bloquer)
- ⬜ `lib/features/pos/presentation/receipt_screen.dart`
  - ⬜ Génération PDF du reçu (`pdf` package)
    - ⬜ En-tête : nom du restaurant, date/heure
    - ⬜ Tableau articles : nom, qté, prix unitaire, sous-total
    - ⬜ Total + mode de paiement + monnaie rendue
    - ⬜ Pied : QR code de commande (optionnel)
  - ⬜ Bouton "Partager / Imprimer" (`printing.share()`)
  - ⬜ Bouton "Imprimer Bluetooth" (imprimante thermique, optionnel)
    - ⬜ Scan appareils Bluetooth disponibles
    - ⬜ Connexion et envoi commandes ESC/POS
    - ⬜ Toujours non-bloquant si imprimante absente
  - ⬜ Bouton "Nouvelle vente" → vide le panier → retour `PosScreen`

---

### Phase 8 — Impression thermique Bluetooth (Phase 2)

- ⬜ `lib/features/pos/data/thermal_printer_service.dart`
  - ⬜ `scanDevices()` → liste des imprimantes Bluetooth
  - ⬜ `connect(device)` / `disconnect()`
  - ⬜ `printReceipt(Order)` → génère les commandes ESC/POS (58mm ou 80mm)
  - ⬜ `isConnected` getter
- ⬜ Écran de paramétrage imprimante (`lib/features/settings/presentation/printer_settings_screen.dart`)
  - ⬜ Scan et sélection de l'imprimante
  - ⬜ Test d'impression
  - ⬜ Persistance du choix dans `shared_preferences`

---

### Phase 9 — Paramètres & profil

- ⬜ `lib/features/settings/presentation/settings_screen.dart`
  - ⬜ Nom et email de l'utilisateur connecté
  - ⬜ Restaurant actif (avec changement possible)
  - ⬜ Configuration imprimante thermique (lien vers Phase 8)
  - ⬜ Bouton déconnexion
  - ⬜ Version de l'app

---

### Phase 10 — Qualité, tests & release

#### 10.1 Tests
- ⬜ Tests unitaires : `formatFCFA`, `AppException`, `SyncService`
- ⬜ Tests widget : `LoginScreen`, `ProductFormScreen`, `CartScreen`
- ⬜ Tests d'intégration : flux complet scan → création produit (avec mock réseau)

#### 10.2 Performance & robustesse
- ⬜ Lazy loading et cache images (`cached_network_image`)
- ⬜ Pagination correctement implémentée (cursor-based ou offset)
- ⬜ Profiling sur appareil entrée de gamme (2 GB RAM)
- ⬜ Désactivation de la caméra quand l'écran de scan n'est pas actif

#### 10.3 Release Android
- ⬜ Keystore de signature configuré
- ⬜ Fichier `key.properties` (non commité)
- ⬜ `flutter build apk --release` fonctionnel
- ⬜ Icône d'application personnalisée (Android mipmap)
- ⬜ Splash screen Akôm
- ⬜ Nom d'application : "Akôm Scanner" dans `AndroidManifest.xml`

---

### Récapitulatif par priorité

| Priorité | Phase | Statut | Prérequis |
|---|---|---|---|
| 🔴 Critique | 0 — Setup | ✅ fait | — |
| 🔴 Critique | 1 — Core | ✅ fait | Phase 0 |
| 🔴 Critique | 2 — Thème & widgets | ✅ fait | Phase 0 |
| 🔴 Critique | 3 — Auth | ✅ fait | Phases 0, 1, 2 |
| 🔴 Critique | 4 — Dashboard | ✅ fait | Phase 3 |
| 🟠 Haute | 5 — Catalogue (Module 1) | ✅ fait | Phases 0–4 |
| 🟠 Haute | 6 — Inventaire (Module 2) | ⬜ à faire | Phases 0–5 |
| 🟠 Haute | 7 — Caisse (Module 3) | ⬜ à faire | Phases 0–5 |
| 🟡 Moyenne | 8 — Impression thermique | ⬜ à faire | Phase 7 |
| 🟡 Moyenne | 9 — Paramètres | ⬜ à faire | Phases 3–7 |
| 🟢 Basse | 10 — Tests & release | ⬜ à faire | Phases 0–9 |
