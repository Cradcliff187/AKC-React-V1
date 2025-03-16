-- SQL script to verify the current state of your database

-- 1. Check foreign key constraints
SELECT
    tc.table_schema, 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public';

-- 2. Check indexes
SELECT
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname = 'public'
ORDER BY
    tablename,
    indexname;

-- 3. Check enum types
SELECT
    n.nspname AS schema,
    t.typname AS enum_type,
    e.enumlabel AS enum_value
FROM
    pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    JOIN pg_catalog.pg_namespace n ON t.typnamespace = n.oid
WHERE
    n.nspname = 'public'
ORDER BY
    t.typname,
    e.enumsortorder;

-- 4. Check RLS policies
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM
    pg_policies
WHERE
    schemaname = 'public'
ORDER BY
    tablename,
    policyname;

-- 5. Check RLS enabled tables
SELECT
    t.tablename,
    CASE WHEN rl.oid IS NOT NULL THEN true ELSE false END AS has_rls_enabled
FROM
    pg_tables t
    LEFT JOIN pg_class c ON t.tablename = c.relname AND t.schemaname = c.relnamespace::regnamespace::text
    LEFT JOIN (
        SELECT oid FROM pg_class WHERE relrowsecurity = true
    ) rl ON c.oid = rl.oid
WHERE
    t.schemaname = 'public'
ORDER BY
    t.tablename;

-- 6. Check stored procedures/functions
SELECT
    p.proname AS function_name,
    pg_get_functiondef(p.oid) AS function_definition
FROM
    pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE
    n.nspname = 'public'
    AND p.proname IN ('is_admin', 'is_authenticated')
ORDER BY
    p.proname; 