# Jal Jeevan Mission & Official IMD Weather Forecasting Scraper

Full-stack, production-grade Web Scraper and Analytical Dashboard integrating:
1. **Jal Jeevan Mission (JJM) Citizen Corner Portal**: [https://ejalshakti.gov.in/jjm/citizen_corner/villageinformation.aspx](https://ejalshakti.gov.in/jjm/citizen_corner/villageinformation.aspx)
2. **India Meteorological Department (IMD) Ministry of Earth Sciences**: [https://api.imd.gov.in/public/api_reference.html](https://api.imd.gov.in/public/api_reference.html)
3. **Ministry of Panchayati Raj eGramSwaraj Mausamgram**: [https://egramswaraj.gov.in/mausam.do](https://egramswaraj.gov.in/mausam.do)

---

## 📁 Essential Project Files

All files for this scraper are fully self-contained in this directory:

```
├── server.js                     # Express Web Server & Unified REST API Engine
├── village_scraper.js            # JJM Citizen Corner Scraper (ViewState, PWS, Water Quality, FTK, GP)
├── weather_service.js            # Official IMD Weather & Calibrated PoP Precipitation Prediction Engine
├── index.js                      # Core scraper library exports
├── example.js                    # Standalone CLI demonstration script
├── imd_api_ref.html              # Local copy of official IMD API documentation
├── package.json                  # Dependencies (express, axios, cheerio)
├── package-lock.json             # Deterministic dependency lock
├── START_SCRAPER_WEB_UI.bat      # One-click desktop launcher (starts server + opens browser)
├── public/                       # Web UI Dashboard & Local Static Assets
│   ├── index.html                # Single-Page Dashboard (JJM Scraper & IMD Weather)
│   ├── vendor/                   # Offline self-hosted libraries (TailwindCSS, Chart.js, Leaflet, FontAwesome)
│   └── webfonts/                 # FontAwesome vector webfonts
└── node_modules/                 # Pre-installed runtime dependencies
```

---

## 🚀 How to Run

### Option 1: One-Click Desktop Launcher
Simply double-click `START_SCRAPER_WEB_UI.bat` inside this folder. It will:
1. Start the Node.js backend server on port 3000.
2. Automatically open your browser to **[http://localhost:3000](http://localhost:3000)**.

### Option 2: Terminal / Command Prompt
```bash
node server.js
```
Open **[http://localhost:3000](http://localhost:3000)** in any browser.
- Jal Jeevan Mission Dashboard: `http://localhost:3000/#jjm`
- IMD Weather & Rain Analytics: `http://localhost:3000/#weather`

---

## ⚡ Features & Capabilities

- **Cascading State ➔ District ➔ Block ➔ Gram Panchayat Dropdowns**
- **Jal Jeevan Mission Citizen Corner Scraper**:
  - Demographics & House Tap Connections (FHTC).
  - Piped Water Supply (PWS) Scheme Diagrams & Components (Source, Treatment, Storage, Disinfection).
  - Water Quality Testing Lab Results & Multi-Source Parameter History (pH, Turbidity, TDS, Nitrate).
  - Community Engagement: VWSC / Pani Samiti, GP Members, Women FTK Testers, O&M Technicians.
- **Official IMD Weather Forecasting & Rain Prediction**:
  - Synoptic current observations (temperature, humidity, pressure, wind direction & speed).
  - 5-Day NWP Forecast conforming to official eGramSwaraj format with meteorological sky condition icons.
  - Interactive Dual-Axis 24-Hour Precipitation & Calibrated Probability of Precipitation (PoP) curve.
  - Live Doppler radar stream integration.
  - Multi-model consensus matrix (ECMWF IFS, NOAA GFS, DWD ICON, AI Blend).
- **100% Offline Asset Resilience**: Self-hosted TailwindCSS, Chart.js, and FontAwesome for uninterrupted operation even during local DNS resolution disruptions.
