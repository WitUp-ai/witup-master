const { Client } = require('pg');
const fs = require('fs');

const connectionString = 'postgresql://postgres:postgres@db.rnfzzmfpykbavuirypfz.supabase.co:5432/postgres';

async function applyMigration() {
  const client = new Client({ connectionString });
  
  try {
    console.log('Connecting to database...');
    await client.connect();
    
    const sql = fs.readFileSync('supabase/migrations/20260203210000_fix_processed_image_fallback.sql', 'utf8');
    
    console.log('Applying migration...');
    await client.query(sql);
    
    console.log('Migration applied successfully!');
  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

applyMigration();