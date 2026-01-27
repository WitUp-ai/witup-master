# 🎨 v0.dev - Setup e Configurazione

> **Data**: 26 Gennaio 2026  
> **Status**: 📋 Pronto per configurazione  
> **Purpose**: Design e generazione componenti UI Web

---

## 📋 Cosa è v0.dev

**v0.dev** è una piattaforma AI-powered di Vercel per generare componenti UI React/Next.js da prompt testuali.

### Caratteristiche Principali
- 🤖 Generazione AI di componenti React
- 🎨 Design system integrato
- 📱 Responsive by default
- ⚡ Tailwind CSS
- 🔄 Iterazione rapida con AI
- 📦 Codice production-ready

---

## 🚀 Setup Account

### Step 1: Registrazione

1. **Vai su [v0.dev](https://v0.dev)**
2. **Sign up** con:
   - Email
   - GitHub (consigliato per integrazione)
   - Google

### Step 2: Verifica Account
- Conferma email
- Completa profilo

### Step 3: Esplora Dashboard
- Familiarizza con l'interfaccia
- Vedi esempi di componenti
- Prova generazione test

---

## 💡 Come Usare v0.dev

### Workflow Base

1. **Scrivi Prompt**
   ```
   "Create a dashboard card component showing user statistics 
   with a chart, using Tailwind CSS and shadcn/ui style"
   ```

2. **AI Genera Componente**
   - v0 crea il componente React
   - Mostra preview live
   - Fornisce codice completo

3. **Itera se Necessario**
   - Chiedi modifiche: "Add a dark mode variant"
   - Affina design: "Make it more minimal"
   - Aggiungi features: "Add loading state"

4. **Copia Codice**
   - Copy component code
   - Salva in `/src/web/components/`

---

## 📁 Integrazione nel Progetto

### Struttura Directory Web

```
/src/web/
├── components/
│   ├── ui/              # v0.dev generated components
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Input.tsx
│   │   └── ...
│   ├── layout/          # Layout components
│   │   ├── Header.tsx
│   │   ├── Sidebar.tsx
│   │   └── Footer.tsx
│   └── features/        # Feature-specific components
│       ├── Dashboard/
│       ├── Auth/
│       └── Settings/
├── lib/
│   └── utils.ts        # Utility functions (cn, etc.)
└── styles/
    └── globals.css     # Tailwind + custom styles
```

### Step-by-Step Integration

#### 1. Setup Tailwind CSS (se non già fatto)

```bash
# Install dependencies
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Install shadcn/ui (v0 usa questo)
npx shadcn-ui@latest init
```

#### 2. Configura `tailwind.config.js`

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        border: "hsl(var(--border))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        // ... altri colori v0
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
```

#### 3. Genera Componente su v0.dev

**Esempio Prompt**:
```
Create a modern dashboard header component with:
- Logo on the left
- Navigation menu in the center
- User profile dropdown on the right
- Dark/Light theme toggle
- Responsive mobile menu
Using shadcn/ui and Tailwind CSS
```

#### 4. Copia Codice nel Progetto

```bash
# Crea file componente
touch src/web/components/layout/Header.tsx

# Incolla codice generato da v0
```

#### 5. Import e Usa

```typescript
// In tua pagina/app
import { Header } from '@/components/layout/Header'

export default function DashboardPage() {
  return (
    <div>
      <Header />
      {/* resto del contenuto */}
    </div>
  )
}
```

---

## 🎯 Best Practices

### 1. Prompt Efficaci

**❌ Prompt Vago**:
```
"Make a button"
```

**✅ Prompt Dettagliato**:
```
"Create a primary button component with:
- Medium size (px-6 py-3)
- Blue background (#3B82F6)
- White text
- Rounded corners
- Hover effect with darker shade
- Loading state with spinner
- Disabled state
- Icon support (left/right)
Using TypeScript and Tailwind CSS"
```

### 2. Organizzazione Componenti

```
ui/              → Componenti base atomici (Button, Input, Card)
layout/          → Struttura pagina (Header, Footer, Sidebar)
features/        → Componenti specifici funzionalità
shared/          → Componenti riusabili cross-feature
```

### 3. Naming Conventions

```typescript
// PascalCase per componenti
Button.tsx
DashboardCard.tsx
UserProfileDropdown.tsx

// camelCase per utilities
formatDate.ts
validateEmail.ts
```

### 4. TypeScript Types

Assicurati che v0 generi con TypeScript:
```typescript
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline'
  size?: 'sm' | 'md' | 'lg'
  isLoading?: boolean
}
```

---

## 🔄 Workflow Completo

### Fase 1: Design System

1. **Definisci Palette Colori**
   ```
   Primary: #3B82F6
   Secondary: #8B5CF6
   Success: #10B981
   Error: #EF4444
   Warning: #F59E0B
   ```

2. **Definisci Typography**
   ```
   Headings: Inter Bold
   Body: Inter Regular
   Code: Fira Code
   ```

3. **Genera Componenti Base con v0**
   - Button (variants: primary, secondary, outline)
   - Input (text, email, password)
   - Card
   - Badge
   - Alert
   - Modal

### Fase 2: Layout Components

1. **Genera su v0.dev**:
   - Header/Navbar
   - Sidebar
   - Footer
   - Page Container

2. **Copia in `/src/web/components/layout/`**

### Fase 3: Feature Components

1. **Dashboard**:
   - StatsCard
   - RecentActivity
   - ChartWidget

2. **Auth**:
   - LoginForm
   - SignupForm
   - ResetPasswordForm

3. **Settings**:
   - ProfileSettings
   - SecuritySettings
   - NotificationSettings

### Fase 4: Integrazione Supabase

Dopo aver generato UI, aggiungi logica:

```typescript
// components/features/Auth/LoginForm.tsx
import { useState } from 'react'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'

export function LoginForm() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password
    })
    
    if (error) alert(error.message)
    setLoading(false)
  }

  return (
    <form onSubmit={handleLogin} className="space-y-4">
      <Input 
        type="email" 
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
      />
      <Input 
        type="password" 
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
      />
      <Button type="submit" isLoading={loading}>
        Login
      </Button>
    </form>
  )
}
```

---

## 🎨 Esempi Prompt per il Progetto

### Dashboard B2B

```
Create a comprehensive B2B dashboard layout with:
- Top navigation bar with logo, search, and user menu
- Left sidebar with collapsible menu items
- Main content area with grid layout
- Stat cards showing KPIs (4 cards in a row)
- Data table with sorting and filtering
- Chart component for analytics
- Responsive design for tablet and mobile
Using Next.js, TypeScript, Tailwind CSS, and shadcn/ui
```

### Mobile App Landing (Web view)

```
Create a modern mobile app landing section with:
- Hero section with app screenshot
- Feature highlights (3 columns)
- Testimonials carousel
- CTA button to download app
- Modern gradient background
- Smooth animations on scroll
Mobile-first responsive design, Tailwind CSS
```

### Forms

```
Create a multi-step form component with:
- Progress indicator at top
- Step validation
- Next/Previous navigation
- Form fields: text, email, select, checkbox
- Error states and validation messages
- Success confirmation step
TypeScript, React Hook Form, Tailwind CSS
```

---

## 📊 Checklist Setup v0.dev

### Account & Setup
- [ ] Registrato su v0.dev
- [ ] Account verificato
- [ ] Familiarizzato con interfaccia

### Progetto Setup
- [ ] Tailwind CSS installato nel progetto
- [ ] shadcn/ui configurato
- [ ] Directory `/src/web/components/` create
- [ ] `utils.ts` per cn() helper creato

### Design System
- [ ] Palette colori definita
- [ ] Typography definita
- [ ] Componenti base generati (Button, Input, Card)
- [ ] Layout components generati (Header, Sidebar)

### Integration
- [ ] Primi componenti integrati
- [ ] Test componenti funzionanti
- [ ] Responsive verificato
- [ ] Dark mode testato (se richiesto)

---

## 🔗 Risorse Utili

- **v0.dev**: [v0.dev](https://v0.dev)
- **shadcn/ui**: [ui.shadcn.com](https://ui.shadcn.com)
- **Tailwind CSS**: [tailwindcss.com](https://tailwindcss.com)
- **Tailwind UI**: [tailwindui.com](https://tailwindui.com) (esempi)

---

## 💡 Tips & Tricks

### 1. Salva Prompt Efficaci
Mantieni un file con prompt che funzionano bene:
```markdown
# /docs/v0-prompts.md

## Dashboard Card
"Create a stats card with icon, title, value, and trend indicator..."

## Data Table
"Create a data table with..."
```

### 2. Versioning Components
Mantieni versioni se fai modifiche sostanziali:
```
Button.tsx
Button.v2.tsx (se refactor major)
```

### 3. Storybook (Optional)
Per documentare componenti:
```bash
npm install -D @storybook/react
npx storybook init
```

### 4. Component Library Doc
Crea README per ogni categoria:
```markdown
# /src/web/components/ui/README.md

## Button
Usage: ...
Props: ...
Examples: ...
```

---

## 🎯 Next Steps

1. **Crea account v0.dev** ✅ (da fare)
2. **Setup Tailwind nel progetto**
3. **Genera primi 3 componenti base**
4. **Testa integrazione**
5. **Crea design system completo**
6. **Documenta componenti**

---

**Documento Versione**: 1.0.0  
**Ultimo Aggiornamento**: 26 Gennaio 2026  
**Status**: 📋 Ready for Setup  
**Next Action**: Crea account su v0.dev

---

## 🤝 Integrazione con Master Setup

Questo setup si integra con:
- **FlutterFlow**: Per design mobile
- **Supabase**: Per backend e auth
- **Vercel**: Per deploy web
- **Spec-Kit**: Specs UI in `/specs/ui-ux/`

**Workflow Completo**:
```
Spec UI/UX → v0.dev genera → Copia in /src/web → Integra logica → Deploy Vercel
```
