# Applicazione Web - MadeMyToys

Questa cartella contiene il codice sorgente per l'applicazione web frontend del progetto MadeMyToys.

## Tecnologie consigliate

- React / Vue.js / Angular per il frontend
- TypeScript per tipizzazione statica
- Sass/Less per gli stili
- Webpack / Vite per il bundling

## Struttura consigliata

```
src/web/
├── public/           # Asset statici
├── src/
│   ├── components/   # Componenti UI
│   ├── pages/        # Pagine dell'applicazione
│   ├── services/     # Servizi API
│   ├── styles/       # Stili globali
│   ├── utils/        # Utility functions
│   └── App.jsx       # Componente principale
├── package.json      # Dipendenze e script
└── README.md         # Questo file
```

## Script di sviluppo

```bash
# Installare le dipendenze
npm install

# Avviare il server di sviluppo
npm run dev

# Build per produzione
npm run build

# Eseguire i test
npm test
```

## Configurazione

Consulta i file in `../.spec/templates/ux/` per template e regole di design specifiche per WITUP.