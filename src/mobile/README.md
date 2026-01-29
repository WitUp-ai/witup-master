# Applicazione Mobile - MadeMyToys

Questa cartella contiene il codice sorgente per l'applicazione mobile del progetto MadeMyToys.

## Piattaforme supportate

- iOS
- Android
- PWA (Progressive Web App)

## Tecnologie consigliate

- React Native per sviluppo cross-platform
- Flutter per UI nativa
- Expo per sviluppo rapido
- TypeScript per tipizzazione statica

## Struttura consigliata

```
src/mobile/
├── android/          # Codice nativo Android
├── ios/              # Codice nativo iOS
├── src/
│   ├── components/   # Componenti UI
│   ├── screens/      # Schermate dell'app
│   ├── navigation/   # Gestione navigazione
│   ├── services/     # Servizi API
│   ├── store/        # State management
│   ├── utils/        # Utility functions
│   └── App.jsx       # Componente principale
├── package.json      # Dipendenze e script
└── README.md         # Questo file
```

## Script di sviluppo

```bash
# Installare le dipendenze
npm install

# Avviare l'app su iOS
npm run ios

# Avviare l'app su Android
npm run android

# Avviare Expo
npm start

# Build per produzione
npm run build:android
npm run build:ios
```

## Configurazione

Consulta i file in `../.spec/templates/ux/` per template e regole di design specifiche per WITUP.

Per configurazioni specifiche per mobile, crea file di configurazione nella cartella `.spec/templates/mobile/`.