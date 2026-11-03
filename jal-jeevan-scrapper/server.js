/**
 * Web UI Server for Jal Jeevan Mission Village Information Scraper & Official IMD Weather Integration
 */

const express = require('express');
const path = require('path');
const {
  getStates,
  getDistricts,
  getVillages,
  getVillageInformation,
} = require('./village_scraper');
const {
  getWeatherStates,
  getZillaPanchayats,
  getBlockPanchayats,
  getGramPanchayats,
  searchImdStations,
  getStationForecast,
  getUnifiedImdWeather,
  resolveGpCode,
  WMO_WEATHER_CODES,
  WIND_DIRECTIONS,
  NOWCAST_CATEGORIES,
  DISTRICT_WARNING_CODES
} = require('./weather_service');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// 1. Get States (JJM)
app.get('/api/states', async (req, res) => {
  try {
    const states = await getStates();
    res.json({ success: true, count: states.length, states });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 2. Get Districts (JJM)
app.get('/api/districts', async (req, res) => {
  const { state } = req.query;
  if (!state) {
    return res.status(400).json({ success: false, error: 'Query parameter "state" is required.' });
  }
  try {
    const data = await getDistricts(state);
    const districts = Array.isArray(data) ? data : (data.districts || []);
    res.json({ success: true, count: districts.length, districts, state: data.state || state });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 3. Search Villages (JJM)
app.get('/api/villages', async (req, res) => {
  const { state, district, query } = req.query;
  if (!state || !district) {
    return res.status(400).json({ success: false, error: 'Parameters "state" and "district" are required.' });
  }
  try {
    const data = await getVillages(state, district, query || '');
    const villages = Array.isArray(data) ? data : (data.villages || []);
    res.json({ success: true, count: villages.length, villages, state: data.state || state, district: data.district || district });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 4. Scrape Full Village Details (JJM + Weather)
const handleVillageScrape = async (req, res) => {
  const { state, district, village } = req.body || {};
  if (!state || !district || !village) {
    return res.status(400).json({
      success: false,
      error: 'Please provide state, district, and village in request body.',
    });
  }

  try {
    const result = await getVillageInformation({ state, district, village }, /* verbose= */ true);
    
    // Attempt auto-resolving weather in background
    try {
      const blockName = result.data?.location?.block || '';
      const gpName = result.data?.location?.panchayat || village;
      const resolved = await resolveGpCode(state, district, blockName, gpName);
      if (resolved && resolved.code) {
        result.data.weatherForecast = await getUnifiedImdWeather({
          gpCode: resolved.code,
          locationMeta: {
            state,
            district,
            block: blockName,
            village: gpName
          }
        });
        result.data.weatherResolvedGp = resolved;
      }
    } catch (wErr) {
      console.warn('[Auto-Weather Resolver Warning]', wErr.message);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

app.post('/api/scrape', handleVillageScrape);
app.post('/api/village-info', handleVillageScrape);

// =========================================================================
// Official IMD Weather Forecasting & eGramSwaraj Gram Panchayat APIs
// =========================================================================

// 5. Get Weather States
app.get('/api/weather/states', (req, res) => {
  try {
    const states = getWeatherStates();
    res.json({ success: true, count: states.length, states });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 6. Get Zilla Panchayats (Districts)
app.get('/api/weather/districts', async (req, res) => {
  const { stateCode } = req.query;
  if (!stateCode) {
    return res.status(400).json({ success: false, error: 'Query parameter "stateCode" is required.' });
  }
  try {
    const districts = await getZillaPanchayats(stateCode);
    res.json({ success: true, count: districts.length, districts });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 7. Get Block Panchayats
app.get('/api/weather/blocks', async (req, res) => {
  const { zillaCode } = req.query;
  if (!zillaCode) {
    return res.status(400).json({ success: false, error: 'Query parameter "zillaCode" is required.' });
  }
  try {
    const blocks = await getBlockPanchayats(zillaCode);
    res.json({ success: true, count: blocks.length, blocks });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 8. Get Gram Panchayats
app.get('/api/weather/gps', async (req, res) => {
  const { blockCode } = req.query;
  if (!blockCode) {
    return res.status(400).json({ success: false, error: 'Query parameter "blockCode" is required.' });
  }
  try {
    const gps = await getGramPanchayats(blockCode);
    res.json({ success: true, count: gps.length, gps });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 9. Search Official IMD Meteorological Stations
app.get('/api/weather/stations', async (req, res) => {
  const { query } = req.query;
  if (!query || query.trim().length < 2) {
    return res.json({ success: true, stations: [] });
  }
  try {
    const stations = await searchImdStations(query.trim());
    res.json({ success: true, stations });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 10. Fetch Unified IMD Weather Forecast (Conforming to #api-1, #api-2, #api-3, #api-4, #api-6, #api-27)
app.get('/api/weather/forecast', async (req, res) => {
  const { gpCode, stationId, district, block, village, gp, state, locName, provider, lat, lon } = req.query;
  try {
    const parsedVillage = village || gp || (locName ? locName.split('(')[0].trim() : null);
    const hasLocation = Boolean(gpCode || parsedVillage || district || block || (lat && lon));
    const forecast = await getUnifiedImdWeather({
      gpCode: gpCode || (hasLocation || stationId ? null : '178330'),
      stationId: stationId || null,
      provider: provider || 'auto',
      locationMeta: {
        state: state || null,
        district: district || null,
        block: block || null,
        village: parsedVillage,
        locName: locName || null,
        lat: lat ? parseFloat(lat) : null,
        lon: lon ? parseFloat(lon) : null
      }
    });
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate');
    res.json({ success: true, forecast });
  } catch (err) {
    if (err.isOffline || (err.message && err.message.includes('NO_INTERNET'))) {
      return res.status(503).json({
        success: false,
        isOffline: true,
        error: 'OFFLINE: External satellite weather APIs unreachable. Please check internet connection.'
      });
    }
    res.status(500).json({ success: false, error: err.message });
  }
});

// 11. Dedicated Current Weather API conforming strictly to https://api.imd.gov.in/public/api_reference.html#api-3
app.get('/api/weather/current_wx', async (req, res) => {
  const { id, gpCode, district, block, village, gp, locName, lat, lon } = req.query;
  try {
    const parsedVillage = village || gp || (locName ? locName.split('(')[0].trim() : null);
    const hasLocation = Boolean(gpCode || parsedVillage || district || block || (lat && lon));
    const forecast = await getUnifiedImdWeather({
      gpCode: gpCode || null,
      stationId: id || (hasLocation ? null : '43157'),
      locationMeta: {
        district: district || null,
        block: block || null,
        village: parsedVillage,
        locName: locName || null,
        lat: lat ? parseFloat(lat) : null,
        lon: lon ? parseFloat(lon) : null
      }
    });
    // Return exact API-3 schema + separated observation and village forecast
    res.json({
      success: true,
      data: forecast.api3CurrentWeather,
      observation: forecast.observation,
      villageForecast: forecast.villageForecast,
      syncStatus: forecast.syncStatus,
      docReference: 'https://api.imd.gov.in/public/api_reference.html#api-3'
    });
  } catch (err) {
    if (err.isOffline || (err.message && err.message.includes('NO_INTERNET'))) {
      return res.status(503).json({
        success: false,
        isOffline: true,
        error: 'OFFLINE: External satellite weather APIs unreachable. Please check internet connection.'
      });
    }
    res.status(500).json({ success: false, error: err.message });
  }
});

// 12a. Reverse Geocode lat/lon → village/block/district/state via Nominatim (OSM)
app.get('/api/geolocate', async (req, res) => {
  const { lat, lon } = req.query;
  if (!lat || !lon) return res.status(400).json({ success: false, error: 'lat and lon are required' });
  try {
    const axios = require('axios');
    // Use zoom=16 for finer village-level granularity
    const url = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json&zoom=16&addressdetails=1`;
    const r = await axios.get(url, {
      headers: { 'User-Agent': 'JalJeevanMission-WeatherScraper/1.0 (jaljeevanmission@gov.in)' },
      timeout: 8000
    });
    const addr = r.data.address || {};

    // === Indian Administrative Hierarchy (Nominatim field mapping) ===
    // Level 1 (finest): village > hamlet > isolated_dwelling > quarter > suburb > neighbourhood
    // Level 2 (taluka/block): county (India county = taluka)
    // Level 3 (district): state_district > district
    // Level 4: state

    // Village: prefer OSM village/hamlet field; fall back to suburb/neighbourhood
    const village = addr.village || addr.hamlet || addr.isolated_dwelling ||
                    addr.quarter || addr.suburb || addr.neighbourhood ||
                    addr.town || addr.city_district || addr.city || 'Unknown';

    // Block/Taluka: In India, Nominatim maps taluka → county
    const block = addr.county || addr.city_district || '';

    // District: state_district is the standard Indian district field
    const district = addr.state_district || addr.district || addr.county || '';

    const state = addr.state || '';

    // Build a clean short display name
    const parts = [village, block !== village ? block : null, district, state].filter(Boolean);
    const uniqueParts = [...new Set(parts)];
    const displayName = uniqueParts.join(', ');

    res.set('Cache-Control', 'no-store');
    res.json({
      success: true,
      lat: parseFloat(lat),
      lon: parseFloat(lon),
      village, block, district, state, displayName,
      raw: addr
    });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Reverse geocode failed: ' + err.message });
  }
});

// 12. Auto-Resolve GP & Fetch Weather
app.post('/api/weather/resolve', async (req, res) => {
  const { state, district, block, village } = req.body || {};
  try {
    const resolved = await resolveGpCode(state, district, block, village);
    const targetGpCode = resolved ? resolved.code : '179026';
    const forecast = await getUnifiedImdWeather({
      gpCode: targetGpCode,
      locationMeta: { state, district, block, village }
    });
    res.json({ success: true, resolvedGp: resolved, forecast });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Robust process resilience handlers to prevent unexpected exits
process.on('uncaughtException', (err) => {
  console.error('[Process UncaughtException]', err.message || err);
});

process.on('unhandledRejection', (reason) => {
  console.error('[Process UnhandledRejection]', reason && reason.message ? reason.message : reason);
});

process.on('SIGINT', () => {
  console.log('[Process Signal] Received SIGINT. Shutting down gracefully.');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('[Process Signal] Received SIGTERM. Shutting down gracefully.');
  process.exit(0);
});

app.listen(PORT, () => {
  console.log(`\n======================================================`);
  console.log(`  Jal Jeevan Mission - Village Web Scraper UI`);
  console.log(`  IMD Weather Forecasting Engine Ready`);
  console.log(`  Server running at: http://localhost:${PORT}`);
  console.log(`======================================================\n`);
});
