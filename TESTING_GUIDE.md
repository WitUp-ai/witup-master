# 🧪 Draw2Toy - Guida al Testing

## 📱 App Attualmente in Esecuzione

L'app è **LIVE** su Chrome all'URL che appare nel terminale.

### 🌐 URL dell'App
Cerca nel terminale la riga che dice:
```
The Flutter DevTools debugger and profiler on Chrome is available at:
http://127.0.0.1:9101?uri=http://127.0.0.1:62041/...
```

**La tua app è su:** `http://localhost` (l'URL esatto è nel terminale)

---

## ✅ Come Testare la Form Validation

### **1. Login Screen**

#### Test Email Validation:
1. Clicca nel campo "Email"
2. **Prova 1:** Lascia vuoto e clicca "Login"
   - ✅ Dovrebbe apparire: "Please enter your email"
   
3. **Prova 2:** Scrivi "test" (senza @)
   - ✅ Dovrebbe apparire: "Please enter a valid email"
   
4. **Prova 3:** Scrivi "test@email.com"
   - ✅ Validation passa! ✓

#### Test Password Validation:
1. Clicca nel campo "Password"
2. **Prova 1:** Lascia vuoto e clicca "Login"
   - ✅ Dovrebbe apparire: "Please enter your password"
   
3. **Prova 2:** Scrivi "12345" (meno di 6 caratteri)
   - ✅ Dovrebbe apparire: "Password must be at least 6 characters"
   
4. **Prova 3:** Scrivi "password123"
   - ✅ Validation passa! ✓

#### Test Visibility Password:
1. Clicca l'icona "occhio" accanto al campo password
   - ✅ La password diventa visibile/invisibile

---

### **2. Signup Screen**

Per accedere: Clicca "Sign Up" nella schermata di login

#### Test Name Validation:
1. **Prova:** Lascia vuoto
   - ✅ "Please enter your name"
2. **Prova:** Scrivi "A" (1 carattere)
   - ✅ "Name must be at least 2 characters"

#### Test Email Validation:
(Stesso comportamento del Login)

#### Test Password Validation:
1. **Prova:** Password con meno di 8 caratteri
   - ✅ "Password must be at least 8 characters"

#### Test Confirm Password:
1. **Prova:** Scrivi password diversa nel "Confirm Password"
   - ✅ "Passwords do not match"

#### Test Terms Checkbox:
1. **Prova:** Clicca "Create Account" senza accettare terms
   - ✅ SnackBar: "Please agree to Terms & Privacy Policy"

---

## 🎯 Flow Completo da Testare

### **1. Splash → Onboarding → Login**
```
✅ Splash (3 secondi)
✅ Onboarding (4 pagine)
   - Swipe per cambiare pagina
   - "Skip" per saltare
   - "Next" / "Get Started!"
✅ Login Screen
```

### **2. Login → Signup → Login**
```
✅ Da Login: Clicca "Sign Up"
✅ Compila form Signup
✅ Clicca "Login" sotto per tornare
```

### **3. Animazioni da Verificare**
- Logo che appare con effetto scale
- Testi che slidano dal basso
- Form fields che entrano da sinistra
- Bottoni che appaiono in fade

---

## 🔧 Comandi Hot Reload

Nel terminale dove gira Flutter:
- **`r`** → Hot reload (ricarica veloce)
- **`R`** → Hot restart (ricarica completa)
- **`q`** → Quit (chiudi app)

---

## 🐛 Debugging

### Se la validation NON appare:
1. **Prova a cliccare il bottone Login/Signup senza compilare**
2. **Guarda sotto ogni campo** per i messaggi di errore
3. **Controlla la console del browser** (F12) per errori

### Se l'app si blocca:
1. Nel terminale premi **`R`** per hot restart
2. Ricarica la pagina Chrome (F5)

---

## 📸 Screenshot Comportamento Atteso

### Login Form Validation:
```
📧 Email Field
   [Empty] → "Please enter your email"
   [test] → "Please enter a valid email"
   [test@mail.com] → ✓

🔒 Password Field
   [Empty] → "Please enter your password"
   [12345] → "Password must be at least 6 characters"
   [password123] → ✓
```

### Signup Form Validation:
```
👤 Name: Min 2 caratteri
📧 Email: Formato email valido
🔒 Password: Min 8 caratteri
🔒 Confirm: Deve matchare password
☑️ Terms: Checkbox obbligatorio
```

---

## ✅ Checklist Test Completa

- [ ] Splash screen appare e scompare dopo 3 secondi
- [ ] Onboarding ha 4 pagine navigabili
- [ ] "Skip" porta al login
- [ ] Login form valida email vuota
- [ ] Login form valida email senza @
- [ ] Login form valida password vuota
- [ ] Login form valida password corta
- [ ] Click su "Sign Up" va alla signup
- [ ] Signup valida tutti i campi
- [ ] Confirm password controlla match
- [ ] Terms checkbox è obbligatorio
- [ ] Click su "Login" torna al login
- [ ] Tutte le animazioni funzionano smooth

---

## 🎨 Features Visive Implementate

✅ **Theme child-friendly**
- Gradienti magici purple-cyan
- Colori vivaci e giocosi
- Font Poppins arrotondato
- Animazioni smooth

✅ **Animazioni**
- Scale elastic per logo
- Slide per testi
- Fade-in sequenziali
- Transizioni di pagina

✅ **UX Details**
- Loading states
- Error messages chiari
- SnackBars informativi
- Form validation real-time

---

**Aggiornato:** 27 Gennaio 2026  
**Status:** App Running su Chrome
