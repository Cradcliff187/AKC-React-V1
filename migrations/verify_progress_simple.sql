-- Simple verification script with counts and summaries

-- 1. Count foreign key constraints by table
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

-- 2. Count indexes by table
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

-- 3. List enum types and their values (concisely)
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

-- 4. Count RLS policies by table and command
SELECT 
    tablename, 
    cmd,
    COUNT(*) AS policy_count
FROM 
    pg_policies
WHERE 
    schemaname = 'public'
GROUP BY 
    tablename, cmd
ORDER BY 
    tablename, cmd;

-- 5. Check which tables have RLS enabled
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

-- 6. Verify key functions exist
SELECT 
    proname AS function_name,
    CASE 
        WHEN proname IS NOT NULL THEN 'Exists'
        ELSE 'Missing'
    END AS status
FROM 
    pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE 
    n.nspname = 'public'
    AND p.proname IN ('is_admin', 'is_authenticated', 'safe_create_policy', 'safe_drop_policy')
ORDER BY 
    p.proname; 