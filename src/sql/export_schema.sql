-- Export table definitions
SELECT 
    'CREATE TABLE ' || tablename || ' (' ||
    string_agg(
        column_name || ' ' ||  
        data_type || 
        CASE 
            WHEN character_maximum_length IS NOT NULL THEN '(' || character_maximum_length || ')'
            ELSE ''
        END || 
        CASE 
            WHEN is_nullable = 'NO' THEN ' NOT NULL'
            ELSE ''
        END ||
        CASE 
            WHEN column_default IS NOT NULL THEN ' DEFAULT ' || column_default
            ELSE ''
        END,
        ', '
    ) || ');'
FROM information_schema.columns
WHERE table_schema = 'public'
GROUP BY tablename;

-- Export foreign keys
SELECT
    'ALTER TABLE ' || tc.table_schema || '.' || tc.table_name || 
    ' ADD CONSTRAINT ' || tc.constraint_name || 
    ' FOREIGN KEY (' || string_agg(kcu.column_name, ', ') || 
    ') REFERENCES ' || ccu.table_schema || '.' || ccu.table_name || 
    ' (' || string_agg(ccu.column_name, ', ') || ');'
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
GROUP BY tc.table_schema, tc.table_name, tc.constraint_name, 
         ccu.table_schema, ccu.table_name;

-- Export indexes
SELECT
    'CREATE INDEX IF NOT EXISTS ' || indexname || ' ON ' || 
    schemaname || '.' || tablename || ' USING ' || 
    indexdef.substring(indexdef.position('USING ') + 6);
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname NOT IN (
    SELECT constraint_name 
    FROM information_schema.table_constraints
    WHERE constraint_type IN ('PRIMARY KEY', 'UNIQUE')
);

-- Export RLS policies
SELECT 
    'CREATE POLICY ' || quote_ident(polname) || 
    ' ON ' || quote_ident(schemaname) || '.' || quote_ident(tablename) ||
    ' AS ' || permissive || 
    ' FOR ' || cmd || 
    ' TO ' || roles ||
    ' USING (' || qual || ')' ||
    CASE WHEN with_check IS NOT NULL 
        THEN ' WITH CHECK (' || with_check || ')'
        ELSE ''
    END || ';'
FROM pg_policies
WHERE schemaname = 'public'; 