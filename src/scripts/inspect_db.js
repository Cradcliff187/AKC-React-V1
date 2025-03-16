require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  'https://olfbvahswnkpxlnhbwds.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9sZmJ2YWhzd25rcHhsbmhid2RzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MTQ5NDU3MiwiZXhwIjoyMDU3MDcwNTcyfQ.gZRKZ4vVImIEC0QSU7ml1V8_boARGx2WpDVQuJotHnY'
);

async function getTableData(tableName) {
  try {
    // Get all rows to understand structure and content
    const { data, error } = await supabase
      .from(tableName)
      .select('*');

    if (error) {
      console.log(`Error fetching ${tableName}:`, error.message);
      return null;
    }

    // Analyze the first row to get column information
    const structure = data && data.length > 0 ? Object.keys(data[0]).map(key => {
      const value = data[0][key];
      return {
        name: key,
        type: typeof value,
        sample: value,
        nullable: data.some(row => row[key] === null)
      };
    }) : [];

    return {
      name: tableName,
      total_rows: data.length,
      columns: structure,
      sample_data: data.slice(0, 5),
      has_data: data.length > 0
    };
  } catch (error) {
    console.error(`Error analyzing table ${tableName}:`, error);
    return null;
  }
}

async function inspectDatabase() {
  try {
    // Known existing tables
    const tableNames = ['customers', 'payments'];

    console.log('\n=== Database Analysis ===\n');

    const databaseStructure = {
      tables: [],
      timestamp: new Date().toISOString(),
      supabase_url: 'https://olfbvahswnkpxlnhbwds.supabase.co'
    };

    for (const tableName of tableNames) {
      console.log(`Analyzing table: ${tableName}...`);
      const tableInfo = await getTableData(tableName);
      if (tableInfo) {
        databaseStructure.tables.push(tableInfo);
        
        // Print immediate feedback
        console.log(`\nTable: ${tableName}`);
        console.log('Total rows:', tableInfo.total_rows);
        console.log('Columns:', tableInfo.columns.map(c => `${c.name} (${c.type})`).join(', '));
        if (tableInfo.has_data) {
          console.log('Sample row:', JSON.stringify(tableInfo.sample_data[0], null, 2));
        } else {
          console.log('Table is empty');
        }
        console.log('---');
      }
    }

    // Save complete structure to file
    const fs = require('fs');
    fs.writeFileSync('database_structure.json', JSON.stringify(databaseStructure, null, 2));
    console.log('\nComplete database structure has been saved to database_structure.json');

  } catch (error) {
    console.error('Error inspecting database:', error);
  }
}

// Run the inspection
inspectDatabase().catch(console.error); 