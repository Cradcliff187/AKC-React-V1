-- Simplified Row Level Security Policies
-- Based directly on the metadata file structure

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Basic RLS for tasks table
DROP POLICY IF EXISTS "Users can view tasks" ON public.tasks;
CREATE POLICY "Users can view tasks" ON public.tasks
FOR SELECT USING (
  -- Anyone authenticated can view tasks
  auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can insert tasks" ON public.tasks;
CREATE POLICY "Users can insert tasks" ON public.tasks
FOR INSERT WITH CHECK (
  -- Anyone authenticated can create tasks
  auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can update tasks" ON public.tasks;
CREATE POLICY "Users can update tasks" ON public.tasks
FOR UPDATE USING (
  -- Only task creators or admins can update
  (created_by_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)) OR
  public.is_admin()
);

DROP POLICY IF EXISTS "Users can delete tasks" ON public.tasks;
CREATE POLICY "Users can delete tasks" ON public.tasks
FOR DELETE USING (
  -- Only task creators or admins can delete
  (created_by_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)) OR
  public.is_admin()
);

-- Basic RLS for projects table
DROP POLICY IF EXISTS "Users can view projects" ON public.projects;
CREATE POLICY "Users can view projects" ON public.projects
FOR SELECT USING (
  -- Anyone authenticated can view projects
  auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can insert projects" ON public.projects;
CREATE POLICY "Users can insert projects" ON public.projects
FOR INSERT WITH CHECK (
  -- Anyone authenticated can create projects
  auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can update projects" ON public.projects;
CREATE POLICY "Users can update projects" ON public.projects
FOR UPDATE USING (
  -- Only admins can update projects
  public.is_admin()
);

DROP POLICY IF EXISTS "Users can delete projects" ON public.projects;
CREATE POLICY "Users can delete projects" ON public.projects
FOR DELETE USING (
  -- Only admins can delete projects
  public.is_admin()
);

-- Basic RLS for clients table
DROP POLICY IF EXISTS "Users can view clients" ON public.clients;
CREATE POLICY "Users can view clients" ON public.clients
FOR SELECT USING (
  -- Anyone authenticated can view clients
  auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can insert clients" ON public.clients;
CREATE POLICY "Users can insert clients" ON public.clients
FOR INSERT WITH CHECK (
  -- Anyone authenticated can create clients
  auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can update clients" ON public.clients;
CREATE POLICY "Users can update clients" ON public.clients
FOR UPDATE USING (
  -- Only admins can update clients
  public.is_admin()
);

DROP POLICY IF EXISTS "Users can delete clients" ON public.clients;
CREATE POLICY "Users can delete clients" ON public.clients
FOR DELETE USING (
  -- Only admins can delete clients
  public.is_admin()
);

-- Basic RLS for documents table
DROP POLICY IF EXISTS "Users can view documents" ON public.documents;
CREATE POLICY "Users can view documents" ON public.documents
FOR SELECT USING (
  -- Anyone authenticated can view documents
  auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can insert documents" ON public.documents;
CREATE POLICY "Users can insert documents" ON public.documents
FOR INSERT WITH CHECK (
  -- Anyone authenticated can create documents
  auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can update documents" ON public.documents;
CREATE POLICY "Users can update documents" ON public.documents
FOR UPDATE USING (
  -- Only document creators or admins can update documents
  (created_by_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)) OR
  public.is_admin()
);

DROP POLICY IF EXISTS "Users can delete documents" ON public.documents;
CREATE POLICY "Users can delete documents" ON public.documents
FOR DELETE USING (
  -- Only document creators or admins can delete documents
  (created_by_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)) OR
  public.is_admin()
);

-- Basic RLS for other tables
-- Enable RLS on all tables
DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename NOT IN ('temp_config_export', 'tasks', 'projects', 'clients', 'documents')
    AND tablename NOT LIKE 'pg_%'
  LOOP
    BEGIN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_record.tablename);
      RAISE NOTICE 'Enabled RLS on table %', table_record.tablename;
      
      -- Create a basic SELECT policy for each table
      EXECUTE format('
        DROP POLICY IF EXISTS "Allow select for authenticated users" ON public.%I;
        CREATE POLICY "Allow select for authenticated users" ON public.%I
        FOR SELECT USING (auth.role() = ''authenticated'');
      ', table_record.tablename, table_record.tablename);
      
      -- Create a basic INSERT policy for each table
      EXECUTE format('
        DROP POLICY IF EXISTS "Allow insert for authenticated users" ON public.%I;
        CREATE POLICY "Allow insert for authenticated users" ON public.%I
        FOR INSERT WITH CHECK (auth.role() = ''authenticated'');
      ', table_record.tablename, table_record.tablename);
      
      -- Create a basic UPDATE policy for each table (admin only)
      EXECUTE format('
        DROP POLICY IF EXISTS "Allow update for admins" ON public.%I;
        CREATE POLICY "Allow update for admins" ON public.%I
        FOR UPDATE USING (public.is_admin());
      ', table_record.tablename, table_record.tablename);
      
      -- Create a basic DELETE policy for each table (admin only)
      EXECUTE format('
        DROP POLICY IF EXISTS "Allow delete for admins" ON public.%I;
        CREATE POLICY "Allow delete for admins" ON public.%I
        FOR DELETE USING (public.is_admin());
      ', table_record.tablename, table_record.tablename);
      
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Error setting up RLS for table %: %', table_record.tablename, SQLERRM;
    END;
  END LOOP;
END $$; 