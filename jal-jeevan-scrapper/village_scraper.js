/**
 * Jal Jeevan Mission (JJM) - Village Information Web Scraper & API Helper
 * Target: https://ejalshakti.gov.in/jjm/citizen_corner/villageinformation.aspx
 */

const axios = require('axios');
const cheerio = require('cheerio');
const https = require('https');

const BASE_URL = 'https://ejalshakti.gov.in/jjm/citizen_corner/villageinformation.aspx';

const cache = {
  states: null,
  districts: {},
  villages: {},
};

/**
 * Creates an axios instance configured with cookie tracking and disabled SSL verification.
 */
function createHttpClient() {
  const cookieJar = {};

  const httpsAgent = new https.Agent({
    rejectUnauthorized: false,
  });

  const client = axios.create({
    baseURL: BASE_URL,
    httpsAgent,
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    },
    timeout: 45000,
  });

  client.interceptors.request.use((config) => {
    const cookieHeader = Object.entries(cookieJar)
      .map(([k, v]) => `${k}=${v}`)
      .join('; ');
    if (cookieHeader) {
      config.headers['Cookie'] = cookieHeader;
    }
    return config;
  });

  client.interceptors.response.use((response) => {
    const setCookies = response.headers['set-cookie'];
    if (setCookies) {
      for (const cookieStr of setCookies) {
        const parts = cookieStr.split(';')[0].split('=');
        if (parts.length >= 2) {
          const key = parts[0].trim();
          const val = parts.slice(1).join('=').trim();
          cookieJar[key] = val;
        }
      }
    }
    return response;
  });

  return client;
}

function extractFormFields($) {
  const fields = {};
  $('input').each((_, el) => {
    const name = $(el).attr('name');
    if (name) {
      fields[name] = $(el).attr('value') || '';
    }
  });

  $('select').each((_, el) => {
    const name = $(el).attr('name');
    if (name) {
      const selected = $(el).find('option[selected]').val();
      const first = $(el).find('option').first().val();
      fields[name] = selected !== undefined ? selected : (first || '');
    }
  });

  return fields;
}

function toFormData(fields) {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(fields)) {
    params.append(key, value !== undefined && value !== null ? String(value) : '');
  }
  return params.toString();
}

function matchOption(input, optionsDict, entityName) {
  if (!input) {
    throw new Error(`Missing ${entityName} in request parameters.`);
  }

  const query = String(input).trim().toLowerCase();

  for (const [name, code] of Object.entries(optionsDict)) {
    if (code.toLowerCase() === query) return { name, code };
  }
  for (const [name, code] of Object.entries(optionsDict)) {
    if (name.toLowerCase() === query) return { name, code };
  }
  for (const [name, code] of Object.entries(optionsDict)) {
    if (name.toLowerCase().includes(query) || query.includes(name.toLowerCase())) {
      return { name, code };
    }
  }

  const available = Object.keys(optionsDict).slice(0, 15).join(', ');
  throw new Error(
    `${entityName} "${input}" not found. Available ${entityName}s include: ${available}...`
  );
}

function parseNumber(text, isFloat = false) {
  if (!text) return 0;
  const clean = text.replace(/,/g, '').trim();
  const num = isFloat ? parseFloat(clean) : parseInt(clean, 10);
  return isNaN(num) ? text.trim() : num;
}

function getText($, id) {
  const el = $(`#${id}`);
  return el.length ? el.text().trim() : '';
}

function encodeTxt(s) {
  const encN = 1;
  let str = escape(String(s));
  let ta = [];
  for (let i = 0; i < str.length; i++) {
    ta[i] = str.charCodeAt(i) + encN;
  }
  let res = '';
  for (let i = 0; i < ta.length; i++) {
    res += String.fromCharCode(ta[i]);
  }
  return escape(res) + encN;
}

/**
 * Fetches time-series source quality chart data via WebMethod
 */
async function fetchSourceQualityCharts(villageId) {
  try {
    const url = 'https://ejalshakti.gov.in/jjm/citizen_corner/VillageInformation.aspx/BindSourceList';
    const payload = {
      StateId: encodeTxt('0'),
      VillageId: encodeTxt(villageId),
      ParameterId: encodeTxt('1'),
      GraphtypeId: encodeTxt('2'),
    };

    const res = await axios.post(url, payload, {
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      timeout: 20000,
    });

    const data = res.data.d;
    if (!data || data === '[]') {
      return { sources: [], parameters: {} };
    }

    const result = data.slice(1, -1);
    const parts = result.split(',[');

    const safeParse = (str) => {
      try {
        return JSON.parse(str);
      } catch (e) {
        return [];
      }
    };

    const sources = safeParse(parts[0] || '[]');
    const fluoride = safeParse('[' + (parts[1] || ''));
    const arsenic = safeParse('[' + (parts[2] || ''));
    const ph = safeParse('[' + (parts[3] || ''));
    const turbidity = safeParse('[' + (parts[4] || ''));
    const tds = safeParse('[' + (parts[5] || ''));
    const nitrate = safeParse('[' + (parts[6] || ''));

    return {
      sources: sources.map((s) => ({
        sourceId: s.SourceId,
        sourceName: s.SourceName,
        habitationId: s.HabitationId,
        habitationName: s.HabitationName,
      })),
      parameters: {
        ph,
        turbidity,
        tds,
        nitrate,
        fluoride,
        arsenic,
      },
    };
  } catch (err) {
    console.warn('[JJM Scraper] Could not fetch source charts:', err.message);
    return { sources: [], parameters: {} };
  }
}

/**
 * Fetches "Details of samples tested in laboratories" modal popup records via BindSampleTestedInfo
 */
async function fetchLaboratorySampleDetails(villageId) {
  try {
    const url = 'https://ejalshakti.gov.in/jjm/citizen_corner/VillageInformation.aspx/BindSampleTestedInfo';
    const res = await axios.post(url, { VillageId: String(villageId) }, {
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      timeout: 20000,
    });

    const raw = res.data.d;
    if (!raw || raw === '[]') {
      return { summary: { totalTested: 0, samplesSafe: 0, samplesUnsafe: 0, remedialActionTaken: 0 }, records: [] };
    }

    const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;
    const summaryItem = (parsed[0] && parsed[0][0]) || {};
    const totalTested = summaryItem.total_number_of_sample_taken || 0;
    const samplesUnsafe = summaryItem.sample_found_contaminated || 0;
    const remedialTaken = summaryItem.remedial_action_taken || 0;
    const samplesSafe = Math.max(0, totalTested - samplesUnsafe);

    const records = (parsed[1] || []).map((r, idx) => ({
      sNo: idx + 1,
      testingDate: r.Date_of_sample_taken || '--',
      testType: r.contaminated_found || '--',
      status: r.Statustaken || '--',
      remedialAction: r.remidacialaction || '--',
      location: r.Location || '--',
    }));

    return {
      summary: {
        totalTested,
        samplesSafe,
        samplesUnsafe,
        remedialActionTaken: remedialTaken,
      },
      records,
    };
  } catch (err) {
    console.warn('[JJM Scraper] Could not fetch sample tested details:', err.message);
    return { summary: { totalTested: 0, samplesSafe: 0, samplesUnsafe: 0, remedialActionTaken: 0 }, records: [] };
  }
}

/**
 * Parses village HTML into structured components
 */
function parseVillageHtml(html) {
  const $ = cheerio.load(html);

  // 1. Location & Administrative Details
  const location = {
    state: getText($, 'lblStatename'),
    district: getText($, 'lblDistrictName'),
    block: getText($, 'lblBlockName'),
    panchayat: getText($, 'lblPanchayatName'),
    village: getText($, 'lblVillageName'),
    villageId: $('input[name="VillageID"]').val() || $('input[name="hidVillageId"]').val() || '',
    blockId: $('input[name="BlockID"]').val() || '',
    panchayatId: $('input[name="PanchyatID"]').val() || '',
    habitationsCount: parseNumber(getText($, 'lblNo_of_Habitations')),
  };

  // 2. JJM Status
  const status = {
    harGharJalCertified: getText($, 'lblvillage_certified') || 'Not Certified',
    villageActionPlanStatus: getText($, 'lblVapStatus') || 'N/A',
  };

  // 3. Demographics & Households
  const demographics = {
    population: {
      total: parseNumber(getText($, 'lblTotal_Population')),
      sc: parseNumber(getText($, 'lbl_SC')),
      st: parseNumber(getText($, 'lbl_st')),
      general: parseNumber(getText($, 'lbl_GEN')),
    },
    households: {
      total: parseNumber(getText($, 'lblTotal_nof_households')),
      withTapConnections: parseNumber(getText($, 'lblwith_tap_connections')),
      tapConnectionsPercentage: getText($, 'lblwith_tap_connections_per').replace(/[()]/g, '').trim(),
      remainingHouseholds: parseNumber(getText($, 'lblRemaining_households')),
      beneficiariesCount: parseNumber(getText($, 'lnk_Beneficiary_List')),
    },
  };

  // 4. Institutional Tap Connections (Schools & Anganwadis)
  const institutions = {
    schools: {
      total: parseNumber(getText($, 'lblTotal_Schools')),
      withTapConnections: parseNumber(getText($, 'lbltap')),
    },
    anganwadis: {
      total: parseNumber(getText($, 'lblAnganwadi_Total')),
      withTapConnections: parseNumber(getText($, 'lblAnganwadi_tap')),
    },
  };

  // 5. Pipe Water Supply Schemes with Flow Diagram Data
  const schemesCount = parseNumber(getText($, 'lblSchemeCount')) || 0;
  const schemes = [];

  for (let i = 0; i < 30; i++) {
    const typeEl = $(`#rpt_SchemeDetails_lblSchemeType_${i}`);
    if (!typeEl.length) break;

    const schemeIdText = $(`#rpt_SchemeDetails_lblbtnSchemeID_${i}`).text().trim();
    const schemeId = schemeIdText.replace(/\[.*\]/g, '').trim();
    const schemeLink = $(`#rpt_SchemeDetails_lblbtnSchemeID_${i}`).attr('href') || '';
    const schemeName = $(`#rpt_SchemeDetails_lblbtn_SchemeName_${i}`).text().trim();
    const schemeType = typeEl.text().trim();
    const sourceCount = parseNumber($(`#rpt_SchemeDetails_lblSource_${i}`).text().trim());
    const treatPlant = parseNumber($(`#rpt_SchemeDetails_lbl_TreatPlant_${i}`).text().trim());
    const storage = parseNumber($(`#rpt_SchemeDetails_lbl_Storage_${i}`).text().trim());
    const disinfection = $(`#rpt_SchemeDetails_lbl_Disinfection_${i}`).text().trim() || 'not Present';
    const fhtcProvided = parseNumber($(`#rpt_SchemeDetails_lbl_Households_${i}`).text().trim());

    schemes.push({
      schemeIndex: i + 1,
      schemeId,
      schemeName: schemeName || `Scheme ${schemeId}`,
      schemeType,
      schemeLink: schemeLink ? 'https://ejalshakti.gov.in/jjm/' + schemeLink.replace(/^\.\.\//, '') : '',
      diagram: {
        sourceCount,
        treatmentPlantCount: treatPlant,
        storageReservoirCount: storage,
        disinfectionStatus: disinfection,
        fhtcProvided,
      },
    });
  }

  // 6. Water Quality Testing (Tables with BIS Limits & Nearest Lab)
  const chemicalTests = [];
  const bacteriologicalTests = [];

  $('table').each((_, tbl) => {
    const headerText = $(tbl).find('tr').first().text();
    if (headerText.includes('Parameter name') && headerText.includes('BIS acceptable limit')) {
      $(tbl).find('tbody tr, tr').each((rIdx, row) => {
        if (rIdx === 0 && $(row).find('th').length) return;
        const cells = $(row).find('td').map((_, c) => $(c).text().trim()).get();
        if (cells.length >= 4) {
          const item = {
            parameterName: cells[0],
            testResult: cells[1],
            bisAcceptableLimit: cells[2],
            bisPermissibleLimit: cells[3],
          };
          if (cells[0].toLowerCase().includes('coli') || cells[0].toLowerCase().includes('coliform')) {
            bacteriologicalTests.push(item);
          } else {
            chemicalTests.push(item);
          }
        }
      });
    }
  });

  const nearestLaboratory = { name: '', type: '', address: '' };
  $('h6').each((_, el) => {
    const t = $(el).text();
    if (t.includes('Lab Name :')) {
      nearestLaboratory.name = $(el).find('span').text().trim();
    } else if (t.includes('Type :')) {
      nearestLaboratory.type = $(el).find('span').text().trim();
    } else if (t.includes('Address :')) {
      nearestLaboratory.address = $(el).find('span').text().trim();
    }
  });

  const waterQuality = {
    samplesTestedCount: parseNumber(getText($, 'lblSampleTested')),
    chemicalTestingDate: getText($, 'lbl_chemicaldate'),
    bacteriologicalTestingDate: getText($, 'lbl_bacteriological_TestingDate'),
    bacteriologicalValue: parseNumber(getText($, 'rptBacteriological_tdvalue_in_range_0'), true),
    remedialActionTaken: getText($, 'lblRemedial_action_taken') || '--',
    chemicalTests,
    bacteriologicalTests,
    nearestLaboratory,
  };

  // 7. Community Engagement Members
  const communityEngagement = {
    summaryCounts: {
      gramPanchayatMembers: parseNumber(getText($, 'Water_utility_management_team_of_village')),
      paniSamitiVWSC: parseNumber(getText($, 'VWSC_Pani_Samiti_Water_User_Group')),
      operationAndMaintenance: getText($, 'Operation_and_Maintenance'),
      womenIdentifiedForFTKTesting: parseNumber(getText($, 'Women_identified_for_fieldtest_kit_testing')),
      totalLaboratories: parseNumber(getText($, 'No_of_laboratories')),
      samplesTestedInLaboratories: parseNumber(getText($, 'Samples_tested_in_laboratories')),
    },
    vwscPaniSamiti: [],
    gramPanchayat: [],
    womenFTK: [],
    operationMaintenance: [],
  };

  $('.theight-Community-Engagement').each((i, cont) => {
    const header = $(cont).prev().text().trim();

    const parseMembers = (targetArray) => {
      const seen = new Set();
      $(cont).find('.row.p-3').each((_, m) => {
        const spans = $(m).find('span').map((_, s) => $(s).text().trim()).get();
        const obj = {};
        spans.forEach((s) => {
          if (s.startsWith('Name :')) obj.name = s.replace('Name :', '').trim();
          else if (s.startsWith('Designation :')) obj.designation = s.replace('Designation :', '').trim();
          else if (s.startsWith('Gender :')) obj.gender = s.replace('Gender :', '').trim();
        });
        if (obj.name) {
          const cleanName = obj.name.replace(/\s+/g, ' ').trim();
          const cleanDesig = (obj.designation || '').replace(/\s+/g, ' ').trim();
          const key = `${cleanName.toLowerCase()}|${cleanDesig.toLowerCase()}`;
          if (!seen.has(key)) {
            seen.add(key);
            obj.name = cleanName;
            obj.designation = cleanDesig;
            targetArray.push(obj);
          }
        }
      });
    };

    if (header.includes('VWSC') || header.includes('Pani Samiti')) {
      parseMembers(communityEngagement.vwscPaniSamiti);
    } else if (header.includes('Gram panchayat')) {
      parseMembers(communityEngagement.gramPanchayat);
    } else if (header.includes('Women identified')) {
      const seenFtk = new Set();
      const rows = $(cont).find('.row.p-3');
      const items = rows.length > 0 ? rows : $(cont).children('div, span');

      items.each((_, m) => {
        let t = $(m).text().replace(/\s+/g, ' ').trim();
        t = t.replace(/^\d+\s*[\.\-]\s*/, '').trim();
        if (t && t.length > 1) {
          const key = t.toLowerCase();
          if (!seenFtk.has(key)) {
            seenFtk.add(key);
            communityEngagement.womenFTK.push(t);
          }
        }
      });
    } else if (header.includes('Operation and Maintenance')) {
      parseMembers(communityEngagement.operationMaintenance);
    }
  });

  return {
    location,
    status,
    demographics,
    institutions,
    waterSupplySchemes: {
      totalSchemes: schemesCount || schemes.length,
      schemes,
    },
    waterQuality,
    communityEngagement,
  };
}

async function getStates() {
  if (cache.states) return cache.states;

  const client = createHttpClient();
  const res = await client.get('');
  const $ = cheerio.load(res.data);
  const states = [];

  $('#ddState option').each((_, el) => {
    const code = $(el).attr('value');
    const name = $(el).text().trim();
    if (code && code !== '-1') {
      states.push({ name, code });
    }
  });

  cache.states = states;
  return states;
}

async function getDistricts(stateInput) {
  const states = await getStates();
  const statesDict = {};
  states.forEach((s) => (statesDict[s.name] = s.code));

  const matchedState = matchOption(stateInput, statesDict, 'State');
  const cacheKey = matchedState.code;

  if (cache.districts[cacheKey]) {
    return {
      state: matchedState,
      districts: cache.districts[cacheKey],
    };
  }

  const client = createHttpClient();
  const res1 = await client.get('');
  const $1 = cheerio.load(res1.data);
  const fields1 = extractFormFields($1);

  fields1['__EVENTTARGET'] = 'ddState';
  fields1['__EVENTARGUMENT'] = '';
  fields1['ddState'] = matchedState.code;

  const res2 = await client.post('', toFormData(fields1), {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });
  const $2 = cheerio.load(res2.data);
  const districts = [];

  $2('#ddDistrict option').each((_, el) => {
    const code = $2(el).attr('value');
    const name = $2(el).text().trim();
    if (code && code !== '-1') {
      districts.push({ name, code });
    }
  });

  cache.districts[cacheKey] = districts;
  return {
    state: matchedState,
    districts,
  };
}

const { scrapeOfficialVillageLive, searchVillageLive } = require('./live_jjm_scraper');

async function getVillages(stateInput, districtInput, query = '') {
  try {
    const list = await searchVillageLive(stateInput, districtInput, query);
    return {
      state: stateInput,
      district: districtInput,
      villages: list || [],
    };
  } catch (err) {
    console.warn('[village_scraper] searchVillageLive warning:', err.message);
    return {
      state: stateInput,
      district: districtInput,
      villages: [],
    };
  }
}

async function getVillageInformation(request, verbose = false) {
  const { state, district, village } = request || {};
  if (!state || !district || !village) {
    throw new Error('Please provide state, district, and village in the request parameters.');
  }
  return await scrapeOfficialVillageLive(state, district, village, verbose);
}

module.exports = {
  getStates,
  getDistricts,
  getVillages,
  getVillageInformation,
  scrapeOfficialVillageLive,
  searchVillageLive,
};

if (require.main === module) {
  const args = process.argv.slice(2);
  let state = args[0] || 'Maharashtra';
  let district = args[1] || 'Kolhapur';
  let village = args[2] || 'Gargoti';

  console.log(`\n======================================================`);
  console.log(`  Jal Jeevan Mission - Live Village Scraper CLI`);
  console.log(`  Target: ${village}, ${district}, ${state}`);
  console.log(`======================================================\n`);

  getVillageInformation({ state, district, village }, true)
    .then((result) => {
      const d = result.data;
      console.log('\n================ LIVE SCRAPED DATA SUMMARY ================');
      console.log(`📍 Location:`);
      console.log(`   State:     ${d.location.state}`);
      console.log(`   District:  ${d.location.district}`);
      console.log(`   Block:     ${d.location.block} (ID: ${d.location.blockId || '--'})`);
      console.log(`   Panchayat: ${d.location.panchayat} (ID: ${d.location.panchayatId || '--'})`);
      console.log(`   Village:   ${d.location.village} (ID: ${d.location.villageId || '--'})`);
      console.log(`   Habitations: ${d.location.habitationsCount}`);

      console.log(`\n🏆 Status & Certification:`);
      console.log(`   Har Ghar Jal Certified: ${d.status.harGharJalCertified}`);
      console.log(`   Village Action Plan:    ${d.status.villageActionPlanStatus}`);

      console.log(`\n👥 Demographics:`);
      console.log(`   Total Population: ${d.demographics.population.total}`);
      console.log(`   - SC:      ${d.demographics.population.sc}`);
      console.log(`   - ST:      ${d.demographics.population.st}`);
      console.log(`   - General: ${d.demographics.population.general}`);
      console.log(`   Total Households: ${d.demographics.households.total}`);
      console.log(`   - Tap Connections: ${d.demographics.households.withTapConnections} (${d.demographics.households.tapConnectionsPercentage})`);
      console.log(`   - Remaining:       ${d.demographics.households.remainingHouseholds}`);

      console.log(`\n💧 Piped Water Supply Schemes (${d.waterSupplySchemes.totalSchemes}):`);
      (d.waterSupplySchemes.schemes || []).forEach((s, idx) => {
        console.log(`   ${idx + 1}. ${s.schemeName} [FHTC: ${s.fhtcProvided}]`);
      });

      console.log(`\n🧪 Water Quality & Testing:`);
      console.log(`   Samples Tested in Lab: ${d.waterQuality.samplesTestedCount}`);
      console.log(`   Chemical Testing Date: ${d.waterQuality.chemicalTestingDate}`);
      console.log(`   Bacteriological Date:  ${d.waterQuality.bacteriologicalTestingDate}`);
      console.log(`   Remedial Action Taken: ${d.waterQuality.remedialActionTaken}`);
      if (d.waterQuality.chemicalTests && d.waterQuality.chemicalTests.length > 0) {
        console.log(`   Chemical Parameters:`);
        d.waterQuality.chemicalTests.forEach((t) => {
          console.log(`     - ${t.parameterName}: ${t.testResult} (BIS Acceptable: ${t.bisAcceptableLimit})`);
        });
      }
      if (d.waterQuality.nearestLaboratory && d.waterQuality.nearestLaboratory.name) {
        console.log(`   Nearest Lab: ${d.waterQuality.nearestLaboratory.name} (${d.waterQuality.nearestLaboratory.address})`);
      }
      if (d.waterQuality.laboratorySampleDetails && d.waterQuality.laboratorySampleDetails.summary) {
        const sum = d.waterQuality.laboratorySampleDetails.summary;
        console.log(`   Laboratory Sample History:`);
        console.log(`     - Total Tested: ${sum.totalTested} | Safe: ${sum.samplesSafe} | Unsafe: ${sum.samplesUnsafe} | Remedial: ${sum.remedialActionTaken}`);
        console.log(`     - Detailed Records Scraped: ${d.waterQuality.laboratorySampleDetails.records.length} records`);
      }

      console.log(`\n🤝 Community Engagement:`);
      console.log(`   VWSC / Pani Samiti Members: ${d.communityEngagement.vwscPaniSamiti.length}`);
      d.communityEngagement.vwscPaniSamiti.forEach((m, idx) => {
        console.log(`     ${idx + 1}. ${m.name} (${m.designation || 'Member'}, ${m.gender || '--'})`);
      });
      console.log(`   Gram Panchayat Members: ${d.communityEngagement.gramPanchayat.length}`);
      d.communityEngagement.gramPanchayat.forEach((m, idx) => {
        console.log(`     ${idx + 1}. ${m.name} (${m.designation || 'GP Member'}, ${m.gender || '--'})`);
      });
      console.log(`   Women FTK Testers: ${d.communityEngagement.womenFTK.length}`);
      d.communityEngagement.womenFTK.forEach((name, idx) => {
        console.log(`     ${idx + 1}. ${name}`);
      });
      console.log(`   O&M Technicians / Personnel: ${d.communityEngagement.operationMaintenance.length}`);
      d.communityEngagement.operationMaintenance.forEach((m, idx) => {
        console.log(`     ${idx + 1}. ${m.name} (${m.designation || 'Technician'}, ${m.gender || '--'})`);
      });

      console.log(`\n======================================================`);
      console.log(`  Live Scraping Completed Successfully (100% Real Data)`);
      console.log(`======================================================\n`);
    })
    .catch((err) => {
      console.error('\n[Error]', err.message);
      process.exit(1);
    });
}
