require('dotenv').config();
const express = require('express');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const port = 3000;

// Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Add middleware to parse JSON bodies
app.use(express.json());

// Add error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: err.message });
});

app.get('/', async (req, res) => {
  try {
    console.log('Attempting to connect to Supabase...');
    // Test Supabase connection
    const { data, error } = await supabase.auth.getSession();
    if (error) {
      console.error('Supabase connection error:', error);
      throw error;
    }
    console.log('Supabase connection successful');

    res.send(`
      <h1>Supabase Test Page</h1>
      <p>Supabase Connection: Success</p>
      <h2>Test Database Operations:</h2>
      <button onclick="testWrite()">Test Write</button>
      <button onclick="testRead()">Test Read</button>
      <div id="result"></div>

      <script>
        async function testWrite() {
          try {
            const response = await fetch('/test-write', { method: 'POST' });
            const result = await response.json();
            document.getElementById('result').innerHTML = 'Write Test: ' + JSON.stringify(result, null, 2);
          } catch (error) {
            document.getElementById('result').innerHTML = 'Error: ' + error.message;
          }
        }

        async function testRead() {
          try {
            const response = await fetch('/test-read');
            const result = await response.json();
            document.getElementById('result').innerHTML = 'Read Test: ' + JSON.stringify(result, null, 2);
          } catch (error) {
            document.getElementById('result').innerHTML = 'Error: ' + error.message;
          }
        }
      </script>
    `);
  } catch (error) {
    console.error('Route error:', error);
    res.status(500).send(`Error: ${error.message}`);
  }
});

// Test write operation
app.post('/test-write', async (req, res) => {
  try {
    console.log('Attempting to write to test_table...');
    const { data, error } = await supabase
      .from('test_table')
      .insert([
        { 
          description: 'Test entry',
          timestamp: new Date().toISOString()
        }
      ])
      .select();

    if (error) {
      console.error('Write error:', error);
      throw error;
    }
    console.log('Write successful:', data);
    res.json({ success: true, data });
  } catch (error) {
    console.error('Write operation failed:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Test read operation
app.get('/test-read', async (req, res) => {
  try {
    console.log('Attempting to read from test_table...');
    const { data, error } = await supabase
      .from('test_table')
      .select('*')
      .order('timestamp', { ascending: false })
      .limit(5);

    if (error) {
      console.error('Read error:', error);
      throw error;
    }
    console.log('Read successful:', data);
    res.json({ success: true, data });
  } catch (error) {
    console.error('Read operation failed:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Add a test endpoint to verify server is running
app.get('/ping', (req, res) => {
  res.send('pong');
});

const server = app.listen(port, '0.0.0.0', () => {
  console.log(`Test server running at http://localhost:${port}`);
  console.log('Supabase URL:', process.env.SUPABASE_URL);
}).on('error', (error) => {
  console.error('Server failed to start:', error);
}); 