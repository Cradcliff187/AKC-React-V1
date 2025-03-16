-- Row Level Security Policies with Error Handling
-- This script safely adds RLS policies to tables, checking if tables exist first

-- Function to safely create a policy
CREATE OR REPLACE FUNCTION safe_create_policy(
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
BEGIN
    -- Check if the table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = safe_create_policy.table_name
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE 'Table % does not exist, skipping policy creation', table_name;
        RETURN;
    END IF;
    
    -- Check if the policy already exists
    SELECT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = safe_create_policy.table_name AND policyname = safe_create_policy.policy_name
    ) INTO policy_exists;
    
    IF policy_exists THEN
        RAISE NOTICE 'Policy % on table % already exists', policy_name, table_name;
        RETURN;
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

-- Helper function to check if user is admin or manager
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_admin_or_manager') THEN
        CREATE FUNCTION public.is_admin_or_manager()
        RETURNS BOOLEAN AS $$
        BEGIN
            RETURN EXISTS (
                SELECT 1 FROM user_profiles
                WHERE auth_id = auth.uid()::text
                AND role IN ('admin', 'manager')
            );
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
        
        RAISE NOTICE 'Created is_admin_or_manager() function';
    ELSE
        RAISE NOTICE 'is_admin_or_manager() function already exists';
    END IF;
END $$;

-- Function to check if user is owner of a resource
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_owner') THEN
        CREATE FUNCTION public.is_owner(creator_id uuid)
        RETURNS BOOLEAN AS $$
        BEGIN
            RETURN EXISTS (
                SELECT 1 FROM user_profiles
                WHERE id = creator_id
                AND auth_id = auth.uid()::text
            );
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
        
        RAISE NOTICE 'Created is_owner() function';
    ELSE
        RAISE NOTICE 'is_owner() function already exists';
    END IF;
END $$;

-- ===========================================
-- Enable RLS on all tables if not already enabled
-- ===========================================
DO $$
DECLARE
    table_record RECORD;
BEGIN
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename NOT IN ('temp_config_export')
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_record.tablename);
            RAISE NOTICE 'Enabled RLS on table %', table_record.tablename;
        EXCEPTION 
            WHEN OTHERS THEN
                RAISE NOTICE 'Error enabling RLS on table %: %', table_record.tablename, SQLERRM;
        END;
    END LOOP;
END $$;

-- ===========================================
-- User Profiles - Base table for user access
-- ===========================================
SELECT safe_create_policy(
    'Users can view their own profile',
    'user_profiles',
    'SELECT',
    'auth.uid() = auth_id::uuid'
);

SELECT safe_create_policy(
    'Users can update their own profile',
    'user_profiles',
    'UPDATE',
    'auth.uid() = auth_id::uuid'
);

SELECT safe_create_policy(
    'Admins can view all profiles',
    'user_profiles',
    'SELECT',
    'EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role = ''admin''
    )'
);

SELECT safe_create_policy(
    'Admins can update all profiles',
    'user_profiles',
    'UPDATE',
    'EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role = ''admin''
    )'
);

-- ===========================================
-- Tasks - Core functionality
-- ===========================================
SELECT safe_create_policy(
    'Users can view relevant tasks',
    'tasks',
    'SELECT',
    'created_by_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR assigned_to_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR project_id IN (
        SELECT p.id FROM projects p
        JOIN user_profiles up ON p.created_by = up.id OR p.client_id IN (
            SELECT c.id FROM clients c
            WHERE c.account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
        )
        WHERE up.auth_id = auth.uid()::text
    )'
);

SELECT safe_create_policy(
    'Users can create tasks',
    'tasks',
    'INSERT',
    NULL,
    'auth.role() = ''authenticated'''
);

SELECT safe_create_policy(
    'Users can update their own tasks',
    'tasks',
    'UPDATE',
    'created_by_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR assigned_to_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

SELECT safe_create_policy(
    'Users can delete their own tasks',
    'tasks',
    'DELETE',
    'created_by_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

-- ===========================================
-- Projects
-- ===========================================
SELECT safe_create_policy(
    'Users can view relevant projects',
    'projects',
    'SELECT',
    'created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR id IN (
        SELECT project_id FROM tasks
        WHERE assigned_to_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    )
    OR client_id IN (
        SELECT c.id FROM clients c
        WHERE c.account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    )'
);

SELECT safe_create_policy(
    'Users can create projects',
    'projects',
    'INSERT',
    NULL,
    'auth.role() = ''authenticated'''
);

SELECT safe_create_policy(
    'Users can update their own projects',
    'projects',
    'UPDATE',
    'created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

SELECT safe_create_policy(
    'Users can delete their own projects',
    'projects',
    'DELETE',
    'created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

-- ===========================================
-- Clients
-- ===========================================
SELECT safe_create_policy(
    'Users can view relevant clients',
    'clients',
    'SELECT',
    'account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

SELECT safe_create_policy(
    'Users can create clients',
    'clients',
    'INSERT',
    NULL,
    'auth.role() = ''authenticated'''
);

SELECT safe_create_policy(
    'Users can update assigned clients',
    'clients',
    'UPDATE',
    'account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

SELECT safe_create_policy(
    'Admins can delete clients',
    'clients',
    'DELETE',
    'EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

-- ===========================================
-- Time Entries
-- ===========================================
SELECT safe_create_policy(
    'Users can view their own time entries',
    'time_entries',
    'SELECT',
    'user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

SELECT safe_create_policy(
    'Users can create their own time entries',
    'time_entries',
    'INSERT',
    NULL,
    'user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)'
);

SELECT safe_create_policy(
    'Users can update their own time entries',
    'time_entries',
    'UPDATE',
    'user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

SELECT safe_create_policy(
    'Users can delete their own time entries',
    'time_entries',
    'DELETE',
    'user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

-- ===========================================
-- Documents
-- ===========================================
SELECT safe_create_policy(
    'Users can view relevant documents',
    'documents',
    'SELECT',
    'uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR project_id IN (
        SELECT p.id FROM projects p
        JOIN user_profiles up ON p.created_by = up.id
        WHERE up.auth_id = auth.uid()::text
    )
    OR client_id IN (
        SELECT c.id FROM clients c
        WHERE c.account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    )
    OR id IN (
        SELECT document_id FROM document_access
        WHERE user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    )'
);

SELECT safe_create_policy(
    'Users can upload documents',
    'documents',
    'INSERT',
    NULL,
    'auth.role() = ''authenticated'''
);

SELECT safe_create_policy(
    'Users can update their own documents',
    'documents',
    'UPDATE',
    'uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

SELECT safe_create_policy(
    'Users can delete their own documents',
    'documents',
    'DELETE',
    'uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

-- ===========================================
-- Document Access
-- ===========================================
SELECT safe_create_policy(
    'Users can view document access',
    'document_access',
    'SELECT',
    'user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR document_id IN (
        SELECT id FROM documents
        WHERE uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    )
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

SELECT safe_create_policy(
    'Users can grant document access',
    'document_access',
    'INSERT',
    NULL,
    'document_id IN (
        SELECT id FROM documents
        WHERE uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    )
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

SELECT safe_create_policy(
    'Users can update document access',
    'document_access',
    'UPDATE',
    'document_id IN (
        SELECT id FROM documents
        WHERE uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    )
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

SELECT safe_create_policy(
    'Users can revoke document access',
    'document_access',
    'DELETE',
    'document_id IN (
        SELECT id FROM documents
        WHERE uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    )
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'')
    )'
);

-- ===========================================
-- Invoices
-- ===========================================
SELECT safe_create_policy(
    'Users can view relevant invoices',
    'invoices',
    'SELECT',
    'created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR project_id IN (
        SELECT p.id FROM projects p
        JOIN user_profiles up ON p.created_by = up.id
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
    )'
);

SELECT safe_create_policy(
    'Users can create invoices',
    'invoices',
    'INSERT',
    NULL,
    'auth.role() = ''authenticated'''
);

SELECT safe_create_policy(
    'Users can update their own invoices',
    'invoices',
    'UPDATE',
    'created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'', ''accountant'')
    )'
);

SELECT safe_create_policy(
    'Users can delete their own invoices',
    'invoices',
    'DELETE',
    'created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'', ''accountant'')
    )'
);

-- ===========================================
-- Expenses
-- ===========================================
SELECT safe_create_policy(
    'Users can view relevant expenses',
    'expenses',
    'SELECT',
    'created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR project_id IN (
        SELECT p.id FROM projects p
        JOIN user_profiles up ON p.created_by = up.id
        WHERE up.auth_id = auth.uid()::text
    )
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'', ''accountant'')
    )'
);

SELECT safe_create_policy(
    'Users can create expenses',
    'expenses',
    'INSERT',
    NULL,
    'auth.role() = ''authenticated'''
);

SELECT safe_create_policy(
    'Users can update their own expenses',
    'expenses',
    'UPDATE',
    'created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'', ''accountant'')
    )'
);

SELECT safe_create_policy(
    'Users can delete their own expenses',
    'expenses',
    'DELETE',
    'created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM user_profiles
        WHERE auth_id = auth.uid()::text
        AND role IN (''admin'', ''manager'', ''accountant'')
    )'
); 