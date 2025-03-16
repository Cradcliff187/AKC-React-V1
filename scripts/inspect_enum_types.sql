-- Script to inspect enum types in the database
-- This provides a clear view of all enum types and their allowed values

-- List all enum types and their values
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

-- Show tables using enum types
SELECT 
    c.table_name,
    c.column_name,
    c.udt_name AS enum_type
FROM 
    information_schema.columns c
WHERE 
    c.udt_schema = 'public' 
    AND c.udt_name IN (
        SELECT t.typname 
        FROM pg_type t 
        JOIN pg_catalog.pg_namespace n ON t.typnamespace = n.oid
        WHERE n.nspname = 'public' AND t.typtype = 'e'
    )
ORDER BY 
    c.table_name, 
    c.column_name; 