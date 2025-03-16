-- Fix for RLS policies with incorrect column names
-- This script corrects column references in the RLS policies

-- First, let's check the actual column names in the projects table
DO $$
DECLARE
    column_exists BOOLEAN;
    possible_columns TEXT[] := ARRAY['created_by', 'created_by_id', 'creator_id', 'owner_id', 'user_id'];
    found_column TEXT := NULL;
BEGIN
    RAISE NOTICE 'Checking for creator column in projects table...';
    
    -- Check each possible column name
    FOREACH found_column IN ARRAY possible_columns
    LOOP
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'projects' 
            AND column_name = found_column
        ) INTO column_exists;
        
        IF column_exists THEN
            RAISE NOTICE 'Found column % in projects table', found_column;
            EXIT;
        END IF;
    END LOOP;
    
    -- If no column found, set to a default
    IF found_column IS NULL OR NOT column_exists THEN
        RAISE NOTICE 'No creator column found in projects table, using created_by_id as default';
        found_column := 'created_by_id';
    END IF;
    
    -- Store the column name in a temporary table for later use
    CREATE TEMP TABLE IF NOT EXISTS temp_column_names (
        table_name TEXT PRIMARY KEY,
        creator_column TEXT
    );
    
    -- Delete any existing entry
    DELETE FROM temp_column_names WHERE table_name = 'projects';
    
    -- Insert the found column name
    INSERT INTO temp_column_names (table_name, creator_column)
    VALUES ('projects', found_column);
    
    RAISE NOTICE 'Stored creator column name % for projects table', found_column;
END $$;

-- Function to safely drop a policy if it exists
CREATE OR REPLACE FUNCTION safe_drop_policy(
    policy_name TEXT,
    table_name TEXT
) RETURNS VOID AS $$
DECLARE
    policy_exists BOOLEAN;
    table_exists BOOLEAN;
BEGIN
    -- Check if the table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = safe_drop_policy.table_name
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE 'Table % does not exist, skipping policy drop', table_name;
        RETURN;
    END IF;
    
    -- Check if the policy exists
    SELECT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = safe_drop_policy.table_name AND policyname = safe_drop_policy.policy_name
    ) INTO policy_exists;
    
    IF policy_exists THEN
        EXECUTE format('DROP POLICY IF EXISTS "%s" ON public.%I', policy_name, table_name);
        RAISE NOTICE 'Dropped policy % on table %', policy_name, table_name;
    ELSE
        RAISE NOTICE 'Policy % on table % does not exist, skipping drop', policy_name, table_name;
    END IF;
EXCEPTION 
    WHEN OTHERS THEN
        RAISE NOTICE 'Error dropping policy % on table %: %', policy_name, table_name, SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to safely create a policy with dynamic column names
CREATE OR REPLACE FUNCTION safe_create_policy_dynamic(
    policy_name TEXT,
    table_name TEXT,
    operation TEXT,
    using_expr TEXT DEFAULT NULL,
    check_expr TEXT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    policy_exists BOOLEAN;
    table_exists BOOLEAN;
    sql_command TEXT;
    creator_column TEXT;
BEGIN
    -- Check if the table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = safe_create_policy_dynamic.table_name
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE 'Table % does not exist, skipping policy creation', table_name;
        RETURN;
    END IF;
    
    -- Check if the policy already exists
    SELECT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = safe_create_policy_dynamic.table_name AND policyname = safe_create_policy_dynamic.policy_name
    ) INTO policy_exists;
    
    IF policy_exists THEN
        -- Drop the existing policy to recreate it with the correct column name
        PERFORM safe_drop_policy(policy_name, table_name);
    END IF;
    
    -- Get the correct creator column name for projects
    IF table_name = 'projects' THEN
        SELECT creator_column INTO creator_column
        FROM temp_column_names
        WHERE table_name = 'projects';
        
        -- Replace 'created_by' with the correct column name in the expressions
        IF creator_column IS NOT NULL AND creator_column != 'created_by' THEN
            using_expr := REPLACE(using_expr, 'created_by', creator_column);
            IF check_expr IS NOT NULL THEN
                check_expr := REPLACE(check_expr, 'created_by', creator_column);
            END IF;
            RAISE NOTICE 'Replaced created_by with % in policy expressions', creator_column;
        END IF;
    END IF;
    
    -- Build the policy SQL
    sql_command := 'CREATE POLICY "' || policy_name || '" ON public.' || table_name || ' FOR ' || operation;
    
    IF using_expr IS NOT NULL THEN
        sql_command := sql_command || ' USING (' || using_expr || ')';
    END IF;
    
    IF check_expr IS NOT NULL THEN
        sql_command := sql_command || ' WITH CHECK (' || check_expr || ')';
    END IF;
    
    BEGIN
        -- Execute the policy creation
        EXECUTE sql_command;
        RAISE NOTICE 'Successfully created policy % on table %', policy_name, table_name;
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE NOTICE 'Error creating policy % on table %: %', policy_name, table_name, SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- ===========================================
-- Projects - Fixed policies
-- ===========================================

-- Get the correct creator column
DO $$
DECLARE
    creator_column TEXT;
BEGIN
    SELECT tcn.creator_column INTO creator_column
    FROM temp_column_names tcn
    WHERE tcn.table_name = 'projects';
    
    IF creator_column IS NULL THEN
        RAISE NOTICE 'Creator column not found for projects table, using created_by_id as default';
        creator_column := 'created_by_id';
    END IF;
    
    -- Drop existing policies
    PERFORM safe_drop_policy('Users can view relevant projects', 'projects');
    PERFORM safe_drop_policy('Users can update their own projects', 'projects');
    PERFORM safe_drop_policy('Users can delete their own projects', 'projects');
    
    -- View projects: Users can view projects they created or are involved with
    EXECUTE format('
        CREATE POLICY "Users can view relevant projects"
        ON public.projects FOR SELECT
        USING (
            %I IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            OR id IN (
                SELECT project_id FROM tasks
                WHERE assigned_to_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            )
            OR client_id IN (
                SELECT c.id FROM clients c
                WHERE c.account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            )
        )', creator_column);
    
    -- Update projects: Only project creators, admins, or managers can update projects
    EXECUTE format('
        CREATE POLICY "Users can update their own projects"
        ON public.projects FOR UPDATE
        USING (
            %I IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            OR EXISTS (
                SELECT 1 FROM user_profiles
                WHERE auth_id = auth.uid()::text
                AND role IN (''admin'', ''manager'')
            )
        )', creator_column);
    
    -- Delete projects: Only project creators, admins, or managers can delete projects
    EXECUTE format('
        CREATE POLICY "Users can delete their own projects"
        ON public.projects FOR DELETE
        USING (
            %I IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            OR EXISTS (
                SELECT 1 FROM user_profiles
                WHERE auth_id = auth.uid()::text
                AND role IN (''admin'', ''manager'')
            )
        )', creator_column);
    
    RAISE NOTICE 'Successfully created fixed policies for projects table using column %', creator_column;
END $$;

-- ===========================================
-- Fix policies that reference projects.created_by in joins
-- ===========================================

-- Fix tasks policy
DO $$
DECLARE
    creator_column TEXT;
BEGIN
    SELECT tcn.creator_column INTO creator_column
    FROM temp_column_names tcn
    WHERE tcn.table_name = 'projects';
    
    IF creator_column IS NULL THEN
        RAISE NOTICE 'Creator column not found for projects table, using created_by_id as default';
        creator_column := 'created_by_id';
    END IF;
    
    -- Drop existing policy
    PERFORM safe_drop_policy('Users can view relevant tasks', 'tasks');
    
    -- Create fixed policy
    EXECUTE format('
        CREATE POLICY "Users can view relevant tasks"
        ON public.tasks FOR SELECT
        USING (
            created_by_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            OR assigned_to_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            OR project_id IN (
                SELECT p.id FROM projects p
                JOIN user_profiles up ON p.%I = up.id OR p.client_id IN (
                    SELECT c.id FROM clients c
                    WHERE c.account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
                )
                WHERE up.auth_id = auth.uid()::text
            )
        )', creator_column);
    
    RAISE NOTICE 'Successfully created fixed policy for tasks table referencing projects.%', creator_column;
END $$;

-- Fix documents policy
DO $$
DECLARE
    creator_column TEXT;
BEGIN
    SELECT tcn.creator_column INTO creator_column
    FROM temp_column_names tcn
    WHERE tcn.table_name = 'projects';
    
    IF creator_column IS NULL THEN
        RAISE NOTICE 'Creator column not found for projects table, using created_by_id as default';
        creator_column := 'created_by_id';
    END IF;
    
    -- Drop existing policy
    PERFORM safe_drop_policy('Users can view relevant documents', 'documents');
    
    -- Create fixed policy
    EXECUTE format('
        CREATE POLICY "Users can view relevant documents"
        ON public.documents FOR SELECT
        USING (
            uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            OR project_id IN (
                SELECT p.id FROM projects p
                JOIN user_profiles up ON p.%I = up.id
                WHERE up.auth_id = auth.uid()::text
            )
            OR client_id IN (
                SELECT c.id FROM clients c
                WHERE c.account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            )
            OR id IN (
                SELECT document_id FROM document_access
                WHERE user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            )
        )', creator_column);
    
    RAISE NOTICE 'Successfully created fixed policy for documents table referencing projects.%', creator_column;
END $$;

-- Fix invoices policy
DO $$
DECLARE
    creator_column TEXT;
BEGIN
    SELECT tcn.creator_column INTO creator_column
    FROM temp_column_names tcn
    WHERE tcn.table_name = 'projects';
    
    IF creator_column IS NULL THEN
        RAISE NOTICE 'Creator column not found for projects table, using created_by_id as default';
        creator_column := 'created_by_id';
    END IF;
    
    -- Drop existing policy
    PERFORM safe_drop_policy('Users can view relevant invoices', 'invoices');
    
    -- Create fixed policy
    EXECUTE format('
        CREATE POLICY "Users can view relevant invoices"
        ON public.invoices FOR SELECT
        USING (
            created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            OR project_id IN (
                SELECT p.id FROM projects p
                JOIN user_profiles up ON p.%I = up.id
                WHERE up.auth_id = auth.uid()::text
            )
            OR client_id IN (
                SELECT c.id FROM clients c
                WHERE c.account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            )
            OR EXISTS (
                SELECT 1 FROM user_profiles
                WHERE auth_id = auth.uid()::text
                AND role IN (''admin'', ''manager'', ''accountant'')
            )
        )', creator_column);
    
    RAISE NOTICE 'Successfully created fixed policy for invoices table referencing projects.%', creator_column;
END $$;

-- Fix expenses policy
DO $$
DECLARE
    creator_column TEXT;
BEGIN
    SELECT tcn.creator_column INTO creator_column
    FROM temp_column_names tcn
    WHERE tcn.table_name = 'projects';
    
    IF creator_column IS NULL THEN
        RAISE NOTICE 'Creator column not found for projects table, using created_by_id as default';
        creator_column := 'created_by_id';
    END IF;
    
    -- Drop existing policy
    PERFORM safe_drop_policy('Users can view relevant expenses', 'expenses');
    
    -- Create fixed policy
    EXECUTE format('
        CREATE POLICY "Users can view relevant expenses"
        ON public.expenses FOR SELECT
        USING (
            created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
            OR project_id IN (
                SELECT p.id FROM projects p
                JOIN user_profiles up ON p.%I = up.id
                WHERE up.auth_id = auth.uid()::text
            )
            OR EXISTS (
                SELECT 1 FROM user_profiles
                WHERE auth_id = auth.uid()::text
                AND role IN (''admin'', ''manager'', ''accountant'')
            )
        )', creator_column);
    
    RAISE NOTICE 'Successfully created fixed policy for expenses table referencing projects.%', creator_column;
END $$;

-- Drop the temporary table
DROP TABLE IF EXISTS temp_column_names; 