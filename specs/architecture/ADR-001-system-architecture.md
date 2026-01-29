# ADR-001: System Architecture - Draw2Toy (Revised for Pivot)

**Status**: ✅ Revised for Pivot to Web App (PWA)  
**Date**: 29 Gennaio 2026  
**Decision Makers**: CTO, Lead Architect  
**Framework**: WITUP Master Blueprint (Updated)

---

## Context

Draw2Toy PIVOT: Passaggio da "Mobile First" a "Web App (PWA) First" per maggiore stabilità, configurabilità e distribuzione rapida.

Nuovi requisiti post-pivot:
- **Flutter Web App (PWA)**: Unica codebase per web e mobile, ottimizzata per browser (Chrome/Safari mobile)
- **Configurazione Dinamica**: API Keys e modelli AI gestiti dinamicamente tramite DB (tabella `system_config`), NO hardcoding
- **Pipeline Intelligente**: Validazione disegno prima della generazione 3D (Vision AI filter)
- **UI Semplificata**: Solo funzionalità core: Login → Dashboard → Upload/Scatta → Viewer 3D
- **Admin Human Panel**: Sistema di gestione configurazione senza toccare codice

Obiettivi tecnici:
- **Stabilità**: Sistema configurabile senza deploy
- **Velocità MVP**: Web App pronta in giorni, non mesi
- **Scalabilità**: Architettura pronta per step multipli (cleanup → generation → printing)
- **Manutenibilità**: Configurazione centralizzata nel DB

---

## Decision

Architettura **Serverless Hybrid** con:
1. **Backend-as-a-Service** (Supabase) per velocità MVP
2. **Microservizi AI** isolati per scalabilità processing
3. **Edge Computing** per latenza ottimale
4. **Event-Driven Architecture** per processing asincrono

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │   Mobile App     │              │   Web Dashboard  │         │
│  │   (Flutter)      │              │   (Next.js 14)   │         │
│  │                  │              │                  │         │
│  │  • AR Viewer     │              │  • Admin Panel   │         │
│  │  • Camera        │              │  • Gallery       │         │
│  │  • Gallery       │              │  • Orders        │         │
│  │  • Profile       │              │  • Analytics     │         │
│  └────────┬─────────┘              └────────┬─────────┘         │
│           │                                 │                   │
└───────────┼─────────────────────────────────┼───────────────────┘
            │                                 │
            │         ┌───────────────────────┘
            │         │
            ▼         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API GATEWAY LAYER                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│              ┌──────────────────────────────┐                   │
│              │   Supabase Edge Functions    │                   │
│              │   (Deno Runtime)             │                   │
│              │                              │                   │
│              │  • Auth Middleware           │                   │
│              │  • Rate Limiting             │                   │
│              │  • Request Validation        │                   │
│              │  • Response Caching          │                   │
│              └──────────┬───────────────────┘                   │
│                         │                                        │
└─────────────────────────┼────────────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   SUPABASE   │  │  AI PIPELINE │  │   PAYMENT    │
│   BACKEND    │  │ MICROSERVICE │  │   SERVICE    │
└──────────────┘  └──────────────┘  └──────────────┘
         │                │                │
         ▼                ▼                ▼
┌─────────────────────────────────────────────────────┐
│              DATA & STORAGE LAYER                    │
├─────────────────────────────────────────────────────┤
│                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │  PostgreSQL  │  │   S3/Bucket  │  │   Redis   │ │
│  │  (Supabase)  │  │  (Supabase)  │  │  (Cache)  │ │
│  │              │  │              │  │           │ │
│  │ • Users      │  │ • Images     │  │ • Session │ │
│  │ • Drawings   │  │ • 3D Files   │  │ • Queue   │ │
│  │ • Orders     │  │ • Thumbnails │  │ • Temp    │ │
│  │ • Analytics  │  │ • AR Assets  │  │           │ │
│  └──────────────┘  └──────────────┘  └───────────┘ │
│                                                       │
└─────────────────────────────────────────────────────┘
```

---

## Component Details (Post-Pivot)

### 1. Client Layer: Flutter Web App (PWA)

#### Flutter Web App (Progressive Web App)
**Responsabilità**:
- UI/UX unificata per web e mobile browser
- Capture foto usando API web standard (HTML5 Camera)
- Visualizzazione 3D nel browser (Three.js/WebGL)
- Gestione offline parziale (PWA)
- Integrazione Supabase Auth

**Stack**:
- Flutter 3.x (Dart) con target web
- Riverpod (state management)
- `image_picker_for_web` per accesso fotocamera
- `model_viewer_plus` per visualizzazione 3D WebGL
- Supabase Flutter SDK (compatibile web)
- Service Worker per funzionalità PWA

**Performance Targets**:
- First Meaningful Paint: <2s
- Time to Interactive: <3s
- Lighthouse PWA Score: >80
- 3D Model Load: <5s

#### Admin Panel (Integrato nell'App)
**Responsabilità**:
- Gestione configurazione sistema (API Keys, modelli AI)
- Monitoraggio pipeline AI
- Gestione utenti (solo admin)

**Accesso**: Route protetta `/admin/settings` visibile solo a utenti con ruolo admin
**Stack**: Stesso stack Flutter, componenti UI dedicate per admin

### 2. Configuration Layer (Nuovo)

#### Tabella `system_config` (Database)
**Scopo**: Memorizzazione dinamica di configurazioni senza hardcoding
**Schema**:
- `key` (PK): Identificatore univoco (es: `REPLICATE_API_TOKEN`)
- `value`: Valore configurazione (sensibile, crittografato)
- `description`: Descrizione umana dello scopo
- `updated_at`: Timestamp ultima modifica
- `updated_by`: Utente/admin che ha modificato

**Configurazioni Chiave**:
- `REPLICATE_API_TOKEN`: Chiave API per servizi Replicate
- `MODEL_VISION`: Modello Vision AI per validazione disegni (es: `moondream`, `gpt-4o-mini`)
- `MODEL_3D_GENERATOR`: Modello per generazione 3D (es: `triposr`, `rodin`)
- `PRINTER_API_KEY`: Placeholder per servizio stampa 3D
- `SYSTEM_STATUS`: Stato sistema (`active`, `maintenance`)

**Sicurezza**: Valori crittografati a riposo, accesso solo via service_role

#### Config Service (Edge Function)
**Endpoint**: `GET /api/config/:key` (con validazione JWT + ruolo)
**Logica**: Lettura da DB + decrittografia + caching Redis
**Fallback**: Se configurazione mancante → errore gentile "Configurazione mancante", non crash


---

### 2. API Gateway Layer

#### Supabase Edge Functions (Deno)
**Endpoint Categories**:

**Auth & User Management**:
- `POST /auth/register` - Registrazione + onboarding
- `POST /auth/login` - Login social/email
- `GET /auth/profile` - Get user profile
- `PATCH /auth/profile` - Update profile
- `POST /auth/subscription` - Upgrade/downgrade plan

**Drawing Management**:
- `POST /drawings/upload` - Upload immagine disegno
- `GET /drawings/:id` - Get drawing details
- `GET /drawings` - List user drawings (paginated)
- `DELETE /drawings/:id` - Delete drawing
- `POST /drawings/:id/regenerate` - Rigenera 3D con diverso stile

**3D Model Management**:
- `GET /models/:id` - Get 3D model file URL
- `GET /models/:id/ar` - Get AR-ready asset
- `POST /models/:id/customize` - Apply customization
- `GET /models/:id/thumbnail` - Get thumbnail

**Order Management**:
- `POST /orders` - Create physical order
- `GET /orders/:id` - Order status
- `GET /orders` - List user orders
- `POST /orders/:id/cancel` - Cancel order

**Payment**:
- `POST /payments/checkout` - Create Stripe checkout
- `POST /payments/webhook` - Stripe webhook handler
- `GET /payments/subscription` - Get subscription status

**Analytics**:
- `POST /analytics/event` - Track event
- `GET /analytics/dashboard` - Admin analytics

---

### 3. Backend Services

#### Supabase Backend
**Database (PostgreSQL)**:
- Relational data (users, drawings, orders)
- Full-text search on drawings
- Row Level Security (RLS) per tenant isolation
- Real-time subscriptions per updates

**Storage**:
- Bucket: `drawings-original` (immagini raw)
- Bucket: `drawings-processed` (immagini segmentate)
- Bucket: `models-3d` (GLB/GLTF files)
- Bucket: `models-thumbnails` (preview images)
- Bucket: `ar-assets` (USDZ per iOS AR)

**Auth**:
- Email/Password
- Google OAuth
- Apple Sign In
- Magic Link
- JWT tokens

**Realtime**:
- Drawing processing status updates
- Order status changes
- Collaborative AR sessions (future)

#### AI Pipeline Microservice
**Deployment**: Cloud Run (Google) o AWS Lambda  
**Runtime**: Python 3.11  
**GPU**: Optional (T4/A10 for faster processing)

**Pipeline Steps**:

1. **Image Preprocessing**
   ```
   Input: Raw photo (JPG/PNG)
   Output: Cleaned, cropped, enhanced image
   Duration: <2s
   ```
   - Auto-crop/rotate detection
   - Contrast enhancement
   - Noise reduction

2. **Segmentation**
   ```
   Model: U2-Net or SAM (Segment Anything)
   Input: Preprocessed image
   Output: Binary mask + foreground PNG
   Duration: <3s
   ```
   - Background removal
   - Edge refinement
   - Multi-object detection (future)

3. **Contour Extraction**
   ```
   Input: Segmented image
   Output: Vector paths (SVG)
   Duration: <1s
   ```
   - Edge detection (Canny)
   - Contour simplification
   - Feature point extraction

4. **3D Generation**
   ```
   Model: Custom CNN or API (Rodin/CSM)
   Input: Contours + original image
   Output: 3D mesh (GLB format)
   Duration: <15s
   ```
   - Depth estimation
   - Mesh generation (low-poly)
   - Texture mapping
   - Auto-rigging for animation

5. **Post-Processing**
   ```
   Input: Raw 3D mesh
   Output: Optimized AR-ready assets
   Duration: <5s
   ```
   - Mesh optimization (reduce polygons)
   - Texture compression
   - LOD generation
   - Platform-specific export:
     - GLB for Android/Web
     - USDZ for iOS AR

**API Contract**:
```typescript
POST /ai/process
{
  "drawing_id": "uuid",
  "image_url": "https://...",
  "style": "cartoon" | "realistic" | "clay",
  "quality": "fast" | "standard" | "high"
}

Response:
{
  "status": "processing" | "completed" | "failed",
  "model_url": "https://...",
  "thumbnail_url": "https://...",
  "ar_asset_url": "https://...",
  "processing_time_ms": 28500,
  "metadata": {
    "vertices": 5420,
    "faces": 8300,
    "texture_size": "1024x1024"
  }
}
```

**Scaling Strategy**:
- Horizontal scaling with queue-based processing
- Auto-scale based on queue depth
- GPU instances for peak hours
- CPU instances for low traffic

**Cost Optimization**:
- Spot/preemptible instances
- Model caching
- Batch processing when possible
- Fallback to CPU for simple drawings

#### Payment Service (Stripe)
**Integration**:
- Stripe Checkout for subscriptions
- Stripe Payment Links for one-time orders
- Webhooks for event handling
- Customer Portal for self-service

**Subscription Logic**:
```typescript
Plans:
- Free: price_free (€0)
- Magic: price_magic_monthly (€9.99) / price_magic_yearly (€99)
- Family: price_family_monthly (€19.99) / price_family_yearly (€199)

Metering:
- Drawings per month (quota enforcement)
- Storage usage (soft limit)
```

---

### 4. Data & Storage Layer

#### Database Schema (PostgreSQL)
*Detailed schema in `/specs/database/schema.md`*

**Core Tables**:
- `users` - User accounts
- `profiles` - Extended user info
- `subscriptions` - Subscription status
- `drawings` - Drawing metadata
- `models_3d` - 3D model references
- `orders` - Physical orders
- `children_profiles` - Child profiles (Family plan)
- `analytics_events` - Event tracking

**Indexes**:
- User lookup: `idx_users_email`, `idx_users_id`
- Drawing queries: `idx_drawings_user_id`, `idx_drawings_created_at`
- Full-text: `idx_drawings_name_search`

**Row Level Security (RLS)**:
```sql
-- Users can only see their own drawings
CREATE POLICY "Users view own drawings"
ON drawings FOR SELECT
USING (auth.uid() = user_id);

-- Users can only modify their own data
CREATE POLICY "Users update own data"
ON profiles FOR UPDATE
USING (auth.uid() = id);
```

#### Storage Buckets
**Configuration**:
- `drawings-original`: Private, 10MB limit per file
- `drawings-processed`: Private, 5MB limit
- `models-3d`: Private, 50MB limit per file
- `models-thumbnails`: Public (CDN), 500KB limit
- `ar-assets`: Public (CDN), 20MB limit

**CDN Strategy**:
- Cloudflare in front of Supabase Storage
- Aggressive caching for static assets
- Lazy loading for 3D models

---

## Data Flow: Draw-to-3D

```
┌─────────┐
│  USER   │
│  Takes  │
│  Photo  │
└────┬────┘
     │
     ▼
┌─────────────────────────────────┐
│  1. MOBILE APP                  │
│  • Optimize image (resize)      │
│  • Upload to Supabase Storage   │
│  • Create drawing record in DB  │
└────┬────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│  2. EDGE FUNCTION               │
│  • Validate user quota          │
│  • Enqueue AI processing job    │
│  • Return job_id to client      │
└────┬────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│  3. AI MICROSERVICE             │
│  • Poll queue / webhook trigger │
│  • Process image → 3D           │
│  • Upload 3D assets to storage  │
│  • Update DB with model_id      │
└────┬────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│  4. REALTIME UPDATE             │
│  • Supabase Realtime            │
│  • Push notification to client  │
│  • "Your creation is ready! 🎉" │
└────┬────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│  5. MOBILE APP                  │
│  • Load 3D model                │
│  • Show celebration animation   │
│  • Launch AR viewer             │
└─────────────────────────────────┘
```

**Timing Breakdown**:
- Upload (1-3s)
- Queue + Validation (0.5s)
- AI Processing (20-30s)
- Asset Upload (2-5s)
- Notification Delivery (0.5s)
**Total**: ~25-40 seconds (target: <30s)

---

## Scalability Strategy

### Horizontal Scaling
- **Mobile/Web**: Stateless, infinite scale via app stores / Vercel edge
- **Edge Functions**: Auto-scale based on traffic
- **AI Service**: Kubernetes cluster with HPA (Horizontal Pod Autoscaler)
- **Database**: Supabase auto-scaling (read replicas if needed)

### Vertical Scaling
- **Database**: Upgrade Supabase plan as needed
- **AI GPUs**: Larger GPU instances for peak processing

### Caching Strategy
```
Layer 1: Browser cache (static assets)
Layer 2: CDN cache (Cloudflare) - 3D thumbnails, AR assets
Layer 3: Redis cache (Edge Functions) - API responses, user data
Layer 4: Database query cache (PostgreSQL)
```

### Queue Management
- **Tool**: PostgreSQL as queue (pg_queue) or Redis Queue
- **Priority Levels**:
  - High: Paid users (Magic/Family tier)
  - Normal: Free users
  - Low: Regeneration requests
- **Dead Letter Queue**: Failed jobs → manual review

---

## Security Architecture

### Authentication Flow
```
1. User → Mobile/Web App
2. App → Supabase Auth (JWT generation)
3. JWT stored in secure storage (Keychain/LocalStorage)
4. Every API call includes JWT in Authorization header
5. Edge Function validates JWT + checks RLS policies
```

### Data Security
- **At Rest**: AES-256 encryption (Supabase default)
- **In Transit**: TLS 1.3 for all connections
- **API Keys**: Rotated every 90 days
- **Secrets Management**: Supabase Vault / Environment Variables

### Privacy Compliance
- **GDPR**: Right to deletion, data export, consent management
- **COPPA**: Parental consent for children <13
- **Data Retention**: 
  - Active users: Indefinite
  - Deleted accounts: 30-day soft delete, then hard delete
  - Analytics: Anonymized after 18 months

---

## Monitoring & Observability

### Application Monitoring
- **Tool**: Sentry
- **Metrics**:
  - Error rate by endpoint
  - Response time P50/P95/P99
  - API success rate

### Infrastructure Monitoring
- **Tool**: Supabase Dashboard + Custom (Grafana)
- **Metrics**:
  - Database connections
  - Storage usage
  - Function invocations
  - AI processing queue depth

### User Analytics
- **Tool**: PostHog (self-hosted or cloud)
- **Tracked Events**:
  - Drawing uploaded
  - 3D model viewed
  - AR session started
  - Order placed
  - Subscription changed

### Alerting
- **Critical** (PagerDuty):
  - API down >5 min
  - Database CPU >90%
  - AI queue stalled
- **Warning** (Slack):
  - Error rate >5%
  - Processing time >60s
  - Storage >80% quota

---

## Disaster Recovery

### Backup Strategy
- **Database**: Daily automated backups (Supabase)
- **Storage**: S3 versioning enabled
- **Retention**: 30 days

### Recovery Objectives
- **RTO** (Recovery Time Objective): 2 hours
- **RPO** (Recovery Point Objective): 24 hours

### Incident Response Plan
1. **Detection**: Automated alerts
2. **Triage**: On-call engineer assesses
3. **Communication**: Status page update
4. **Resolution**: Fix or rollback
5. **Post-mortem**: Document learnings

---

## Cost Projection (Year 1)

### Infrastructure Costs
```
Supabase (Pro):           €250/month   = €3,000/year
AI Processing (Cloud Run): €500/month   = €6,000/year
Vercel (Pro):             €200/month   = €2,400/year
CDN (Cloudflare):         €50/month    = €600/year
Monitoring (Sentry):      €100/month   = €1,200/year
Other Services:           €200/month   = €2,400/year
────────────────────────────────────────────────────
TOTAL:                    €1,300/month = €15,600/year
```

**At 10,000 users**: €1.56/user/year  
**At 100,000 users**: €0.16/user/year (economies of scale)

### Cost Optimization Opportunities
1. Reserved instances for AI (save 40%)
2. S3 Intelligent Tiering (save 30% on storage)
3. CDN optimization (reduce bandwidth)
4. Database query optimization (reduce compute)

**Optimized Year 1**: ~€12,000

---

## Technology Trade-offs

### Why Supabase over Custom Backend?
✅ **Pros**:
- 10x faster MVP development
- Built-in auth, storage, real-time
- Excellent developer experience
- Scales to 100k+ users easily

❌ **Cons**:
- Vendor lock-in (mitigated by PostgreSQL standard)
- Less control over infrastructure
- Cost at massive scale (>1M users)

**Decision**: Right choice for MVP to Product-Market Fit. Re-evaluate at 500k users.

### Why Microservice for AI vs Edge Function?
✅ **Pros**:
- GPU support
- Independent scaling
- Technology flexibility (Python ML ecosystem)

❌ **Cons**:
- More complex deployment
- Additional monitoring
- Potential cold starts

**Decision**: Necessary due to AI workload requirements.

### Why Flutter over React Native?
✅ **Pros**:
- Better AR support (ARCore/ARKit)
- Superior 3D rendering performance
- Single codebase, true native feel
- Excellent for graphic-heavy apps

❌ **Cons**:
- Smaller ecosystem than React Native
- Larger app size

**Decision**: Performance and AR experience are critical differentiators.

---

## Future Architecture Evolution

### Phase 2 (6-12 months)
- WebSocket server for multiplayer AR
- Video generation from 3D models
- AI voice synthesis for characters

### Phase 3 (12-24 months)
- Multi-region deployment (US, EU, APAC)
- On-premise AI processing for privacy-sensitive clients
- GraphQL API layer for third-party integrations

### Phase 4 (24+ months)
- Edge AI processing (on-device 3D generation)
- Blockchain integration for NFT creation
- Metaverse platform (Draw2Toy Universe)

---

## Conclusion

Questa architettura bilanciata **speed-to-market** e **scalabilità futura**:
- ✅ MVP in 3 mesi con Supabase
- ✅ Scalabile a 100k+ users senza re-architecture
- ✅ Performance targets raggiungibili (<30s processing)
- ✅ Costi ottimizzati per early stage
- ✅ Fondamenta solide per features avanzate

---

**Next Steps**:
1. ✅ Architecture defined
2. ⏳ Database schema detailed design
3. ⏳ API contracts specification
4. ⏳ AI pipeline prototyping
5. ⏳ Security audit planning

**Approval**: ✅ Ready for Implementation

---

**Document Owner**: Lead Architect  
**Last Updated**: 27 Gennaio 2026  
**Version**: 1.0
