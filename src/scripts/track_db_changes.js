require('dotenv').config({ path: 'config/.env' });
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs/promises');
const path = require('path');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE,
  {
    db: {
      schema: 'public'
    }
  }
);

async function saveMetadata(metadata) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `db_metadata_${timestamp}.json`;
  
  // Create metadata history directory if it doesn't exist
  await fs.mkdir('db_metadata_history').catch(() => {});
  
  await fs.writeFile(
    path.join('db_metadata_history', filename),
    JSON.stringify(metadata, null, 2)
  );
  
  // Also save as latest
  await fs.writeFile(
    path.join('db_metadata_history', 'latest.json'),
    JSON.stringify(metadata, null, 2)
  );
}

async function compareWithPrevious(currentMetadata) {
  try {
    const latestContent = await fs.readFile(
      path.join('db_metadata_history', 'latest.json'),
      'utf8'
    );
    const previousMetadata = JSON.parse(latestContent);
    
    const changes = {
      timestamp: new Date().toISOString(),
      changes: []
    };

    // Compare each section
    for (const section of Object.keys(currentMetadata)) {
      const current = currentMetadata[section];
      const previous = previousMetadata[section];
      
      if (JSON.stringify(current) !== JSON.stringify(previous)) {
        changes.changes.push({
          section,
          type: 'modified',
          details: `Changes detected in ${section}`
        });
      }
    }

    if (changes.changes.length > 0) {
      const changelogPath = path.join('db_metadata_history', 'changelog.json');
      let changelog = [];
      try {
        const existingChangelog = await fs.readFile(changelogPath, 'utf8');
        changelog = JSON.parse(existingChangelog);
      } catch (err) {
        // No existing changelog
      }
      
      changelog.push(changes);
      await fs.writeFile(changelogPath, JSON.stringify(changelog, null, 2));
    }
  } catch (err) {
    console.log('No previous metadata found for comparison');
  }
}

async function extractMetadata() {
  try {
    // Get all tables
    const { data: tables, error: tablesError } = await supabase
      .rpc('get_tables', { schema_name: 'public' });

    if (tablesError) {
      console.error('Error fetching tables:', tablesError);
      return;
    }

    const metadata = {
      tables: tables || []
    };

    // Get RLS policies
    const { data: policies, error: policiesError } = await supabase
      .rpc('get_policies', { schema_name: 'public' });

    if (!policiesError && policies) {
      metadata.policies = policies;
    } else if (policiesError) {
      console.error('Error fetching policies:', policiesError);
    }

    // Get indexes
    const { data: indexes, error: indexesError } = await supabase
      .rpc('get_indexes', { schema_name: 'public' });

    if (!indexesError && indexes) {
      metadata.indexes = indexes;
    } else if (indexesError) {
      console.error('Error fetching indexes:', indexesError);
    }

    // Get security configurations
    const { data: security, error: securityError } = await supabase
      .rpc('get_table_security', { schema_name: 'public' });

    if (!securityError && security) {
      metadata.security = security;
    } else if (securityError) {
      console.error('Error fetching security config:', securityError);
    }

    await saveMetadata(metadata);
    await compareWithPrevious(metadata);
    
    console.log('Database metadata extracted and saved successfully');
    console.log('Metadata saved to:', path.join('db_metadata_history', `db_metadata_${new Date().toISOString().replace(/[:.]/g, '-')}.json`));
  } catch (error) {
    console.error('Error extracting metadata:', error);
  }
}

// Run the extraction
extractMetadata(); 