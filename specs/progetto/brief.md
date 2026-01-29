# Draw2Toy - Project Brief

## 🎯 Visione del Progetto

**Draw2Toy** è un SaaS rivoluzionario che trasforma i disegni a mano dei bambini in giocattoli fisici attraverso AI e stampa 3D, creando un'esperienza magica che unisce creatività digitale e mondo fisico.

## 🌟 Unique Value Proposition

### Il Problema
I genitori cercano regali unici e personalizzati che stimolino la creatività dei bambini, ma le opzioni sul mercato sono generiche e prive di significato emotivo.

### La Soluzione
Draw2Toy permette ai bambini di vedere le proprie creazioni prendere vita:
1. **Disegnano** su carta la loro idea
2. **Fotografano** il disegno con l'app
3. **Vedono magia** - AI trasforma in 3D animato
4. **Esplorano** in realtà aumentata (AR)
5. **Ricevono** il giocattolo fisico a casa

### Il Valore
- 🎨 **Per i Bambini**: Potere creativo illimitato + gratificazione immediata (AR) + giocattolo fisico tangibile
- 👨‍👩‍👧 **Per i Genitori**: Regalo unico, educativo, memorabile + esperienza condivisa con i figli
- 💼 **Per il Business**: Doppio revenue stream (SaaS + Marketplace fisico)

## 🎭 Target Audience

### Persona Primaria: "Genitore Premium"
- **Età**: 30-45 anni
- **Reddito**: Alto (€60k+/anno)
- **Profilo**: Professionisti urbani, tech-savvy
- **Valori**: Educazione, creatività, unicità, sostenibilità
- **Comportamento d'acquisto**: 
  - Cerca esperienze premium per i figli
  - Disposto a pagare per qualità e innovazione
  - Influenzato da social proof e recensioni
  - Ama condividere momenti speciali sui social

### Persona Secondaria: "Gift Giver"
- Nonni, zii, padrini
- Cerca regali memorabili e unici
- Meno tech-savvy ma disposti a provare per fare bella figura
- Budget regalo: €50-200

### Mercato
- **Primario**: Italia, USA, UK, Germania, Francia
- **TAM**: Genitori con figli 4-12 anni in paesi sviluppati (~150M famiglie)
- **SAM**: Genitori alto-spendenti tech-savvy (~15M famiglie)
- **SOM** (Year 1): 10,000 famiglie attive

## 💰 Business Model

### Modello Ibrido SaaS + Marketplace

#### 1. SaaS Subscription (Recurring Revenue)
**Tier Free** (0€/mese)
- 1 disegno/mese trasformato in 3D
- Visualizzazione AR base
- Gallery personale (max 5 modelli)
- Watermark su AR

**Tier Magic** (€9.99/mese o €99/anno)
- 10 disegni/mese in 3D
- AR avanzata (animazioni, suoni, interazioni)
- Gallery illimitata
- Condivisione social
- Accesso beta a nuove features

**Tier Family** (€19.99/mese o €199/anno)
- Disegni illimitati
- 3 profili bambino
- AR premium con multiplayer AR
- Priority queue per ordini fisici
- Sconto 20% su marketplace
- Album stampato annuale incluso

#### 2. Marketplace Ordini Fisici (Transaction-based)
- **Giocattolo Piccolo** (5-8cm): €29.99
- **Giocattolo Medio** (10-15cm): €49.99
- **Giocattolo Grande** (20-25cm): €89.99
- **Set Famiglia** (3+ personaggi): €149.99
- **Premium Painted** (+€30): Colorazione manuale professionale
- **Express Delivery** (+€15): 3-5 giorni invece di 10-14

#### 3. Revenue Aggiuntivi
- **B2B Licensing**: Scuole, centri creativi, eventi
- **API Access**: Partner integrations (€99/mese per partner)
- **White Label**: Brand possono offrire servizio ai propri clienti

### Proiezioni Anno 1
- **Users Free**: 50,000 (90% del totale)
- **Subscribers Magic**: 3,000 (5.4%)
- **Subscribers Family**: 500 (0.9%)
- **Physical Orders**: 2,000 unità

**MRR Breakdown**:
- SaaS: €39,970/mese
- Marketplace: ~€24,000/mese (avg)
- **Total MRR**: €63,970
- **ARR**: €767,640

## 🔧 Core Features

### MVP (Fase 1 - 3 mesi)
1. **App Mobile Flutter**
   - Onboarding magico
   - Camera capture ottimizzata per disegni
   - Gallery personale
   - Visualizzatore AR base

2. **AI Pipeline**
   - Image segmentation (rimozione sfondo)
   - Contour extraction
   - Generazione modello 3D base (low-poly)
   - Auto-rigging per animazioni semplici

3. **Backend Supabase**
   - Autenticazione (Email + Social)
   - Database modelli utente
   - Storage immagini e 3D files
   - Payment integration (Stripe)

4. **Web Dashboard**
   - Gestione account
   - Gallery online
   - Ordinazione giocattoli fisici
   - Tracking ordini

### Fase 2 - Engagement (Mesi 4-6)
- Animazioni AR avanzate
- Multiplayer AR (gioca con altri in famiglia)
- Social sharing (Instagram stories format)
- Preset stili per 3D (cartoon, realistic, clay)

### Fase 3 - Monetization (Mesi 7-9)
- Marketplace integrato
- Customization tool (colori, texture)
- Album stampato automatico
- Partnership scuole

### Fase 4 - Scale (Mesi 10-12)
- AI Voice generation (personaggio parla)
- AR Games integrati
- B2B Platform
- Espansione geografica

## 🎨 UX Objectives - "Magia in Ogni Step"

### Principi Guida
1. **Delight Over Function**: Ogni interazione deve stupire
2. **Zero Friction**: Flow senza interruzioni dalla foto al 3D
3. **Instant Gratification**: Preview AR in <10 secondi dalla foto
4. **Emotional Connection**: Celebrare ogni creazione come capolavoro

### Momenti Magici da Progettare
- 📸 **Capture**: Feedback visivo come "scanner magico"
- ⚡ **Processing**: Loading animato con anticipation
- 🎭 **Reveal**: Esplosione di coriandoli quando 3D è pronto
- 🕹️ **AR**: Prima volta che vedono il loro disegno prendere vita
- 📦 **Delivery**: Unboxing experience pensata per video

## 🏗️ Technical Stack (WITUP Framework)

### Mobile (Flutter)
- Framework: Flutter 3.x
- State Management: Riverpod
- AR: ARCore (Android) / ARKit (iOS)
- 3D Rendering: Flutter 3D / Model Viewer

### Web (Next.js)
- Framework: Next.js 14 (App Router)
- Styling: TailwindCSS + Shadcn/UI
- Animation: Framer Motion
- 3D Web: Three.js / React Three Fiber

### Backend (Supabase)
- Database: PostgreSQL
- Auth: Supabase Auth
- Storage: Supabase Storage
- Edge Functions: Deno

### AI Pipeline
- Segmentation: Segment Anything Model (SAM) o U2-Net
- 3D Generation: Custom pipeline o Rodin API / CSM by Common Sense Machines
- Processing: Python microservice
- Queue: Supabase Realtime + PostgreSQL queue

### Infrastructure
- Hosting Web: Vercel
- Mobile: App Store + Google Play
- CDN: Cloudflare
- Payment: Stripe
- Analytics: PostHog
- Monitoring: Sentry

## 📈 Success Metrics (North Star)

### Product Metrics
- **Primary**: Disegni trasformati in 3D/settimana
- **Engagement**: % utenti che ritornano entro 7 giorni
- **Conversion**: Free → Paid (target 8%)
- **Monetization**: LTV/CAC ratio (target >3)

### User Experience
- Time to first 3D: <30 secondi
- AR session duration: >2 minuti
- App rating: >4.5 stelle
- NPS Score: >50

### Business
- MRR Growth: +20% MoM
- Churn Rate: <5% mensile
- Physical orders per subscriber: >2/anno
- Gross Margin: >60%

## 🚀 Go-to-Market Strategy

### Launch Plan (Soft Launch → Scale)

**Fase 1: Beta Privata** (1000 family)
- Invite-only
- Feedback loop intenso
- Pricing testing
- Social proof building

**Fase 2: Product Hunt Launch**
- Community tech-savvy
- Media coverage
- Influencer seeding

**Fase 3: Paid Acquisition**
- Meta Ads (Facebook/Instagram)
- TikTok (UGC content)
- Google Ads (branded + "regali bambini")
- YouTube pre-roll

### Content Strategy
- UGC incentivato (sconto per video unboxing)
- Educational content (sviluppo creatività bambini)
- Behind-the-scenes AI magic
- Success stories genitori

## 🎯 Competitive Advantage

### Cosa Ci Differenzia
1. **End-to-End Experience**: Altri fanno solo digitale O solo fisico
2. **Speed**: AI in <30sec vs 24h di competitor
3. **AR Premium**: Non solo viewer ma giochi interattivi
4. **Emotional Design**: UX pensata per stupire, non solo funzionare
5. **Subscription Model**: Recurring relationship vs one-time purchase

### Moat Building
- Proprietary AI training su disegni bambini
- Database unico di creazioni → migliora AI
- Network effect: multiplayer AR tra famiglie
- Brand: "Draw2Toy" diventa sinonimo della categoria

## 🔐 IP & Legal

### Protezione
- Trademark "Draw2Toy"
- Patent pending su pipeline AI-to-3D per disegni bambini
- Copyright su animazioni AR proprietarie

### Privacy & Compliance
- GDPR compliant (dati bambini)
- COPPA compliant (USA)
- Parental consent flow
- Data retention policy trasparente

## 💡 Visione Futura (2-5 anni)

### Platform Evolution
- **Draw2Toy Studio**: Tool per creator professionisti
- **Draw2Toy Edu**: Versione per scuole e musei
- **Draw2Toy Universe**: Metaverso dove personaggi interagiscono
- **API Platform**: Altri prodotti integrano la nostra AI

### Exit Strategy
- Acquisition target: Hasbro, Mattel, LEGO, Roblox
- Valuation target: €50-100M entro 3 anni

---

## 📋 Next Steps (Specs to Create)

1. ✅ **Brief** (questo documento)
2. ⏳ **Features Specs** → `/specs/features/`
3. ⏳ **API Contracts** → `/specs/api/`
4. ⏳ **Database Schema** → `/specs/database/`
5. ⏳ **UI/UX Design System** → `/specs/ui-ux/`
6. ⏳ **Architecture Decisions** → `/specs/architecture/`
7. ⏳ **Roadmap & Tasks** → `/specs/plan/`

---

**Documento Creato**: 27 Gennaio 2026  
**Owner**: Giovanni Sapere  
**Status**: ✅ Approved for Specs Generation  
**Framework**: WITUP Master Blueprint v1.0
