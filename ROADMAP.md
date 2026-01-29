gira# Draw2Toy - Roadmap Implementazione

## ✅ FASE 1-2: COMPLETATA (Oggi)

### Implementato
- [x] Setup progetto Flutter con Supabase
- [x] Sistema di autenticazione completo (Email, Google, Apple)
- [x] Splash Screen animata
- [x] Onboarding (4 pagine con animazioni)
- [x] Login Screen
- [x] Signup Screen
- [x] Home Screen (3 tabs: Home, Gallery, Profile)
- [x] Routing completo con go_router
- [x] Theme system child-friendly
- [x] Auth provider con Riverpod

### Per Testare l'App ADESSO
**Nel terminale in esecuzione, digita "1" e premi INVIO per aprire su Chrome**

L'app mostrerà:
1. Splash screen (3 secondi)
2. Onboarding automatico
3. Navigazione completa tra tutte le schermate

---

## 🎯 FASE 3: Camera & Image Capture (Prossima)

### Da Implementare
- [ ] Camera screen per catturare disegni
- [ ] Preview e crop immagine
- [ ] Validazione qualità immagine
- [ ] Upload a Supabase Storage
- [ ] Gestione permessi camera
- [ ] Feedback visivo durante upload

**Tempo stimato:** 2-3 ore  
**Complessità:** Media

---

## 🤖 FASE 4: AI Pipeline Integration

### Da Implementare
- [ ] Setup backend AI (Python microservice)
- [ ] API endpoint per trasformazione 2D → 3D
- [ ] Integrazione con servizi AI esterni (Rodin/CSM)
- [ ] Loading states e progress tracking
- [ ] Gestione coda processing
- [ ] Notifiche real-time quando 3D è pronto
- [ ] Error handling e retry logic

**Tempo stimato:** 5-7 ore  
**Complessità:** Alta

---

## 📦 FASE 5: 3D Viewer & AR Experience

### Da Implementare
- [ ] 3D Model Viewer (model_viewer_plus)
- [ ] Controlli gesture (rotate, zoom, pan)
- [ ] AR viewer con ARCore/ARKit
- [ ] Placement 3D nel mondo reale
- [ ] Screenshot AR
- [ ] Animazioni 3D personalizzate
- [ ] Salvataggio nella gallery personale

**Tempo stimato:** 4-6 ore  
**Complessità:** Alta

---

## 🖼️ FASE 6: Gallery Management

### Da Implementare
- [ ] Lista creazioni da Supabase
- [ ] Grid view con thumbnails
- [ ] Detail view per ogni creazione
- [ ] Delete, Edit, Share operations
- [ ] Filtri (data, tipo, status)
- [ ] Ricerca
- [ ] Infinite scroll / pagination
- [ ] Pull to refresh
- [ ] Offline caching

**Tempo stimato:** 3-4 ore  
**Complessità:** Media

---

## 🛒 FASE 7: Marketplace & Orders

### Da Implementare
- [ ] Schermata di ordinazione
- [ ] Configurazione prodotto (size, colore)
- [ ] Preview rendering del giocattolo fisico
- [ ] Integrazione Stripe Checkout
- [ ] Gestione indirizzi di spedizione
- [ ] Tracking ordini in tempo reale
- [ ] Storico ordini
- [ ] Receipt e invoices

**Tempo stimato:** 6-8 ore  
**Complessità:** Alta

---

## 💎 FASE 8: Subscription & Monetization

### Da Implementare
- [ ] Subscription plans UI (Free, Magic, Family)
- [ ] Stripe Subscription integration
- [ ] Quota management (disegni/mese)
- [ ] Feature gating per tier
- [ ] Upgrade/downgrade flow
- [ ] Payment methods management
- [ ] Billing history

**Tempo stimato:** 4-5 ore  
**Complessità:** Media-Alta

---

## 🔧 FASE 9: Polish & Features Secondarie

### Da Implementare
- [ ] Editing profilo utente
- [ ] Change password
- [ ] Delete account
- [ ] Push notifications (Firebase)
- [ ] In-app notifications
- [ ] Settings screen completo
- [ ] Dark mode support
- [ ] Internationalization (i18n)
- [ ] Error tracking (Sentry)
- [ ] Analytics (PostHog)
- [ ] App tour / tips
- [ ] Feedback system
- [ ] Share creations sui social

**Tempo stimato:** 5-7 ore  
**Complessità:** Media

---

## 🚀 FASE 10: Testing & Deployment

### Da Implementare
- [ ] Unit tests core logic
- [ ] Widget tests screens
- [ ] Integration tests flow completo
- [ ] Performance testing
- [ ] iOS app setup (App Store Connect)
- [ ] Android app setup (Play Console)
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Beta testing (TestFlight/Play Console)
- [ ] Store listing (screenshots, description)
- [ ] Release production

**Tempo stimato:** 6-10 ore  
**Complessità:** Alta

---

## 📊 Riepilogo Timeline

| Fase | Tempo Stimato | Complessità | Status |
|------|---------------|-------------|--------|
| 1-2: Foundation | ✅ Completato | Media | ✅ DONE |
| 3: Camera | 2-3 ore | Media | ⏳ Next |
| 4: AI Pipeline | 5-7 ore | Alta | 🔜 Planned |
| 5: 3D/AR | 4-6 ore | Alta | 🔜 Planned |
| 6: Gallery | 3-4 ore | Media | 🔜 Planned |
| 7: Orders | 6-8 ore | Alta | 🔜 Planned |
| 8: Subscription | 4-5 ore | Media-Alta | 🔜 Planned |
| 9: Polish | 5-7 ore | Media | 🔜 Planned |
| 10: Deploy | 6-10 ore | Alta | 🔜 Planned |

**Totale rimanente:** ~35-50 ore di sviluppo

---

## 🎯 MVP Minimale (Per Demo/Test)

Per avere una versione dimostrabile funzionante serve:
- ✅ Auth & Navigation (FATTO)
- ⏳ Camera Capture (Fase 3)
- ⏳ Mock AI (simulazione con delay)
- ⏳ 3D Viewer base

**Tempo per MVP Demo:** ~6-8 ore aggiuntive

---

## 💡 Note Importanti

1. **Database Supabase:** Va configurato con le tabelle necessarie
2. **AI Backend:** Può essere mockato inizialmente per test
3. **AR:** Richiede device fisico (non funziona su emulatore)
4. **Apple Developer Account:** Necessario per iOS (€99/anno)
5. **Google Play Developer:** Necessario per Android (€25 one-time)

---

**Aggiornato:** 27 Gennaio 2026  
**Versione App:** 1.0.0+1  
**Status:** Foundation Complete - Ready for Camera Feature
