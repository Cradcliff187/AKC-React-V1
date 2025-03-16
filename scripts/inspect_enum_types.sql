-- Script to inspect all enum types and their values in the database
-- Run this to see what enum types exist and what values they accept

-- List all enum types in the database
SELECT
    n.nspname AS schema,
    t.typname AS enum_name,
    string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) AS enum_values
FROM
    pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    JOIN pg_catalog.pg_namespace n ON t.typnamespace = n.oid
WHERE
    n.nspname = 'public'
GROUP BY
    n.nspname, t.typname
ORDER BY
    t.typname;

-- List all columns that use enum types
SELECT
    t.relname AS table_name,
    a.attname AS column_name,
    pg_type.typname AS enum_type
FROM
    pg_attribute a
    JOIN pg_class t ON a.attrelid = t.oid
    JOIN pg_type ON a.atttypid = pg_type.oid
    JOIN pg_namespace ON pg_type.typnamespace = pg_namespace.oid
WHERE
    pg_namespace.nspname = 'public'
    AND pg_type.typtype = 'e'
    AND t.relkind = 'r'
    AND NOT a.attisdropped
ORDER BY
    t.relname, a.attnum; 