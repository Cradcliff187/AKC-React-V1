-- Absolute minimal RLS script
-- Only sets up simple authentication rules without column assumptions

-- Function to check if user is authenticated
CREATE OR REPLACE FUNCTION public.is_authenticated()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN auth.role() = 'authenticated';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS on all tables
DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename NOT IN ('temp_config_export')
    AND tablename NOT LIKE 'pg_%'
  LOOP
    BEGIN
      -- Enable RLS
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_record.tablename);
      
      -- Drop any existing policies to avoid conflicts
      EXECUTE format('DROP POLICY IF EXISTS "Allow authenticated access" ON public.%I', table_record.tablename);
      
      -- Create a simple policy that allows authenticated users to do everything
      EXECUTE format('
        CREATE POLICY "Allow authenticated access" ON public.%I
        FOR ALL USING (auth.role() = ''authenticated'');
      ', table_record.tablename);
      
      RAISE NOTICE 'Set up minimal RLS for table %', table_record.tablename;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Error setting up RLS for table %: %', table_record.tablename, SQLERRM;
    END;
  END LOOP;
END $$; 