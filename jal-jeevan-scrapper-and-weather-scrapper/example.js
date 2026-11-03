const { getVillageInformation } = require('./index');

async function main() {
  // Input request message
  const requestMessage = {
    state: 'Goa',
    district: 'North Goa',
    village: 'Anjuna',
  };

  console.log('Sending request message:', requestMessage);

  try {
    const result = await getVillageInformation(requestMessage, /* verbose= */ true);
    console.log('\n--- Extraction Successful ---');
    console.log(`Village: ${result.data.location.village} (${result.data.location.panchayat}, ${result.data.location.block})`);
    console.log(`Total Population: ${result.data.demographics.population.total}`);
    console.log(`Households with Tap Connections: ${result.data.demographics.households.withTapConnections} / ${result.data.demographics.households.total} (${result.data.demographics.households.tapConnectionsPercentage})`);
    console.log(`Certification: ${result.data.status.harGharJalCertified}`);
    console.log(`Schemes: ${result.data.waterSupplySchemes.totalSchemes}`);
    console.log(`Schools with tap: ${result.data.institutions.schools.withTapConnections} / ${result.data.institutions.schools.total}`);
    console.log(`Anganwadis with tap: ${result.data.institutions.anganwadis.withTapConnections} / ${result.data.institutions.anganwadis.total}`);
    console.log('\nWater Quality Parameters:');
    const chem = result.data.waterQuality.chemicalTests || result.data.waterQuality.chemicalParameters || [];
    for (const p of chem) {
      console.log(`  - ${p.parameterName || p.parameter}: ${p.testResult || p.value}`);
    }
  } catch (err) {
    console.error('Error fetching village information:', err.message);
  }
}

main();

