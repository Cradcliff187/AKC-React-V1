-- Comprehensive Database Setup and Verification
-- This script checks and fixes all critical database elements

-- ======== 1. SETUP ERROR HANDLING ========
DO $$
BEGIN
    RAISE NOTICE '========== STARTING COMPREHENSIVE DATABASE VERIFICATION ==========';
END $$;

-- ======== 2. SETUP ADMIN FUNCTIONS ========
DO $$
BEGIN
    -- Check for is_admin function
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_admin') THEN
        EXECUTE '
        CREATE FUNCTION public.is_admin()
        RETURNS BOOLEAN AS $FUNC$
        BEGIN
            RETURN EXISTS (
                SELECT 1 FROM user_profiles
                WHERE auth_id = auth.uid()::text
                AND role = ''admin''
            );
        END;
        $FUNC$ LANGUAGE plpgsql SECURITY DEFINER;
        ';
        RAISE NOTICE 'Created is_admin() function';
    ELSE
        RAISE NOTICE 'is_admin() function already exists';
    END IF;
    
    -- Check for is_authenticated function
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_authenticated') THEN
        EXECUTE '
        CREATE FUNCTION public.is_authenticated()
        RETURNS BOOLEAN AS $FUNC$
        BEGIN
            RETURN auth.role() = ''authenticated'';
        END;
        $FUNC$ LANGUAGE plpgsql SECURITY DEFINER;
        ';
        RAISE NOTICE 'Created is_authenticated() function';
    ELSE
        RAISE NOTICE 'is_authenticated() function already exists';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error setting up admin functions: %', SQLERRM;
END $$;

-- ======== 3. ENABLE RLS ON ALL TABLES ========
DO $$
DECLARE
    table_record RECORD;
    rls_count INT := 0;
BEGIN
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename NOT IN ('temp_config_export') 
        AND tablename NOT LIKE 'pg_%'
    LOOP
        BEGIN
            -- Check if RLS is already enabled
            IF EXISTS (
                SELECT 1 FROM pg_class 
                WHERE relname = table_record.tablename 
                AND relrowsecurity = true
            ) THEN
                RAISE NOTICE 'RLS already enabled on table %', table_record.tablename;
            ELSE
                EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_record.tablename);
                rls_count := rls_count + 1;
                RAISE NOTICE 'Enabled RLS on table %', table_record.tablename;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error enabling RLS on table %: %', table_record.tablename, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE 'Enabled RLS on % tables', rls_count;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error in RLS setup: %', SQLERRM;
END $$;

-- ======== 4. ENSURE RLS POLICIES EXIST ========
DO $$
DECLARE
    table_record RECORD;
    policy_count INT := 0;
BEGIN
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename NOT IN ('temp_config_export') 
        AND tablename NOT LIKE 'pg_%'
    LOOP
        BEGIN
            -- Check if policy already exists
            IF EXISTS (
                SELECT 1 FROM pg_policies 
                WHERE schemaname = 'public' 
                AND tablename = table_record.tablename 
                AND policyname = 'Allow authenticated access'
            ) THEN
                RAISE NOTICE 'Policy "Allow authenticated access" already exists on table %', table_record.tablename;
            ELSE
                -- Drop conflicting policies
                EXECUTE format('DROP POLICY IF EXISTS "Allow authenticated access" ON public.%I', table_record.tablename);
                
                -- Create universal policy
                EXECUTE format('
                    CREATE POLICY "Allow authenticated access" ON public.%I
                    FOR ALL USING (auth.role() = ''authenticated'');
                ', table_record.tablename);
                
                policy_count := policy_count + 1;
                RAISE NOTICE 'Created policy on table %', table_record.tablename;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error creating policy on table %: %', table_record.tablename, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE 'Created % policies', policy_count;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error in policy setup: %', SQLERRM;
END $$;

-- ======== 5. VERIFY FOREIGN KEYS ========
DO $$
DECLARE
    fk_count INT := 0;
BEGIN
    -- Check tasks -> projects
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_type = 'FOREIGN KEY' 
        AND table_name = 'tasks' 
        AND constraint_name = 'fk_tasks_project'
    ) THEN
        BEGIN
            ALTER TABLE tasks
                ADD CONSTRAINT fk_tasks_project
                FOREIGN KEY (project_id) 
                REFERENCES projects(id)
                ON DELETE CASCADE;
            fk_count := fk_count + 1;
            RAISE NOTICE 'Added foreign key from tasks.project_id to projects.id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error adding foreign key from tasks.project_id to projects.id: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Foreign key from tasks.project_id to projects.id already exists';
    END IF;
    
    -- Check documents -> projects
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_type = 'FOREIGN KEY' 
        AND table_name = 'documents' 
        AND constraint_name = 'fk_documents_project'
    ) THEN
        BEGIN
            ALTER TABLE documents
                ADD CONSTRAINT fk_documents_project
                FOREIGN KEY (project_id) 
                REFERENCES projects(id)
                ON DELETE CASCADE;
            fk_count := fk_count + 1;
            RAISE NOTICE 'Added foreign key from documents.project_id to projects.id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error adding foreign key from documents.project_id to projects.id: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Foreign key from documents.project_id to projects.id already exists';
    END IF;
    
    -- Check documents -> clients
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_type = 'FOREIGN KEY' 
        AND table_name = 'documents' 
        AND constraint_name = 'fk_documents_client'
    ) THEN
        BEGIN
            ALTER TABLE documents
                ADD CONSTRAINT fk_documents_client
                FOREIGN KEY (client_id) 
                REFERENCES clients(id)
                ON DELETE CASCADE;
            fk_count := fk_count + 1;
            RAISE NOTICE 'Added foreign key from documents.client_id to clients.id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error adding foreign key from documents.client_id to clients.id: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Foreign key from documents.client_id to clients.id already exists';
    END IF;
    
    -- Check tasks -> user_profiles (assigned_to)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_type = 'FOREIGN KEY' 
        AND table_name = 'tasks' 
        AND constraint_name = 'fk_tasks_assigned_to'
    ) THEN
        BEGIN
            IF EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_schema = 'public' 
                      AND table_name = 'tasks' 
                      AND column_name = 'assigned_to_id') THEN
                ALTER TABLE tasks
                    ADD CONSTRAINT fk_tasks_assigned_to
                    FOREIGN KEY (assigned_to_id) 
                    REFERENCES user_profiles(id)
                    ON DELETE SET NULL;
                fk_count := fk_count + 1;
                RAISE NOTICE 'Added foreign key from tasks.assigned_to_id to user_profiles.id';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error adding foreign key from tasks.assigned_to_id to user_profiles.id: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Foreign key from tasks.assigned_to_id to user_profiles.id already exists';
    END IF;
    
    RAISE NOTICE 'Added % foreign key constraints', fk_count;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error in foreign key setup: %', SQLERRM;
END $$;

-- ======== 6. VERIFY INDEXES ========
DO $$
DECLARE
    idx_count INT := 0;
BEGIN
    -- Check index on tasks.project_id
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND tablename = 'tasks' 
        AND indexname = 'idx_tasks_project_id'
    ) THEN
        BEGIN
            CREATE INDEX idx_tasks_project_id ON tasks(project_id);
            idx_count := idx_count + 1;
            RAISE NOTICE 'Created index on tasks.project_id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error creating index on tasks.project_id: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Index on tasks.project_id already exists';
    END IF;
    
    -- Check index on tasks.status
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND tablename = 'tasks' 
        AND indexname = 'idx_tasks_status'
    ) THEN
        BEGIN
            CREATE INDEX idx_tasks_status ON tasks(status);
            idx_count := idx_count + 1;
            RAISE NOTICE 'Created index on tasks.status';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error creating index on tasks.status: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Index on tasks.status already exists';
    END IF;
    
    -- Check composite index on tasks (project + status)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND tablename = 'tasks' 
        AND indexname = 'idx_tasks_project_status'
    ) THEN
        BEGIN
            CREATE INDEX idx_tasks_project_status ON tasks(project_id, status);
            idx_count := idx_count + 1;
            RAISE NOTICE 'Created composite index on tasks(project_id, status)';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error creating composite index on tasks(project_id, status): %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Composite index on tasks(project_id, status) already exists';
    END IF;
    
    -- Check index on documents.project_id
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND tablename = 'documents' 
        AND indexname = 'idx_documents_project_id'
    ) THEN
        BEGIN
            CREATE INDEX idx_documents_project_id ON documents(project_id);
            idx_count := idx_count + 1;
            RAISE NOTICE 'Created index on documents.project_id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error creating index on documents.project_id: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Index on documents.project_id already exists';
    END IF;
    
    -- Check index on documents.client_id
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND tablename = 'documents' 
        AND indexname = 'idx_documents_client_id'
    ) THEN
        BEGIN
            CREATE INDEX idx_documents_client_id ON documents(client_id);
            idx_count := idx_count + 1;
            RAISE NOTICE 'Created index on documents.client_id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error creating index on documents.client_id: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Index on documents.client_id already exists';
    END IF;
    
    RAISE NOTICE 'Added % indexes', idx_count;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error in index setup: %', SQLERRM;
END $$;

-- ======== 7. SUMMARY ========
DO $$
BEGIN
    RAISE NOTICE '========== DATABASE VERIFICATION COMPLETE ==========';
    
    -- Count foreign keys
    RAISE NOTICE 'Foreign key count:';
    -- Output will come from this query
END $$;

-- Output foreign key count
SELECT 
    table_name, 
    COUNT(*) AS foreign_key_count
FROM (
    SELECT
        tc.table_name
    FROM 
        information_schema.table_constraints AS tc 
    WHERE 
        tc.constraint_type = 'FOREIGN KEY' 
        AND tc.table_schema = 'public'
) subquery
GROUP BY table_name
ORDER BY table_name;

-- Output index count
SELECT 
    tablename, 
    COUNT(*) AS index_count
FROM 
    pg_indexes
WHERE 
    schemaname = 'public'
GROUP BY 
    tablename
ORDER BY 
    tablename;

-- Output RLS policy count
SELECT 
    tablename, 
    COUNT(*) AS policy_count
FROM 
    pg_policies
WHERE 
    schemaname = 'public'
GROUP BY 
    tablename
ORDER BY 
    tablename;

-- Output RLS status
SELECT 
    tablename,
    CASE 
        WHEN relrowsecurity THEN 'Enabled'
        ELSE 'Disabled'
    END AS rls_status
FROM 
    pg_tables t
    JOIN pg_class c ON t.tablename = c.relname AND t.schemaname = c.relnamespace::regnamespace::text
WHERE 
    t.schemaname = 'public'
ORDER BY 
    t.tablename;

-- Output enum types
SELECT 
    t.typname AS enum_type,
    string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) AS enum_values
FROM 
    pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    JOIN pg_catalog.pg_namespace n ON t.typnamespace = n.oid
WHERE 
    n.nspname = 'public'
GROUP BY 
    t.typname
ORDER BY 
    t.typname; 