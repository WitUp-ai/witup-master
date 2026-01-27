# UX CONSTITUTION
Version: 1.0
Scope: All WITUP projects

## 1. Stack Tecnologico Vincolante
### Web (SaaS / B2C)
- **Framework:** Next.js 14+ (App Router)
- **Styling:** TailwindCSS
- **Component Base:** Shadcn/UI (Radix primitives)
- **Animazioni:** Framer Motion
- **High-Impact UI:** Magic UI / Aceternity (SOLO per Hero sections, Onboarding, Feature highlights. VIETATO per layout strutturali).
- **Icons:** Lucide React

### Mobile (Native / B2B)
- **Framework:** Flutter (Latest Stable)
- **Styling:** Package 'mix' (per styling atomico stile CSS)
- **Animazioni:** Package 'flutter_animate' + Rive Runtime
- **Fonts:** Google Fonts

## 2. Principi di Design
- **Mobile-first:** Ogni componente web deve nascere responsive.
- **Feedback Immediato:** Ogni elemento interattivo DEVE avere stati hover, active/pressed e focus visibili.
- **Skeleton Loading:** Mai mostrare spazi bianchi vuoti durante il caricamento dati.
- **Spaziatura:** Usa la scala standard Tailwind (4px grid). Evita "magic numbers".

## 3. Governance e Debito Tecnico
- **Design Debt:** Ogni workaround UX temporaneo o stile hardcoded DEVE essere commentato:
  `// UX-DEBT: [spiegazione breve del perché non è standard]`
- **Pulizia:** Vietato CSS inline o stili annidati complessi senza estrazione in componenti.
