-- Get tables with automatic timestamp columns
SELECT json_build_object(
    'type', 'timestamp_columns',
    'data', json_agg(json_build_object(
        'table_name', t.table_name,
        'column_name', c.column_name,
        'column_default', c.column_default,
        'is_nullable', c.is_nullable
    ))
)
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public'
    AND (c.column_default LIKE 'now()%' 
        OR c.column_default LIKE 'CURRENT_TIMESTAMP%'
        OR c.column_default LIKE 'timezone%')
ORDER BY t.table_name, c.column_name;

-- Get detailed RLS policies with rules
SELECT json_build_object(
    'type', 'rls_policies',
    'data', json_agg(json_build_object(
        'schema', schemaname,
        'table', tablename,
        'policy_name', policyname,
        'permissive', permissive,
        'roles', roles,
        'command', cmd,
        'using_expression', qual,
        'with_check_expression', with_check,
        'definition', pg_get_policy_def(p.oid)
    ))
)
FROM pg_policies pol
JOIN pg_policy p ON pol.policyname = p.polname
WHERE pol.schemaname = 'public'
ORDER BY pol.tablename, pol.policyname;

-- Get tables with RLS status
SELECT json_build_object(
    'type', 'rls_enabled_tables',
    'data', json_agg(json_build_object(
        'table_name', t.tablename,
        'rls_enabled', t.relrowsecurity,
        'rls_forced', c.relforcerowsecurity
    ))
)
FROM pg_tables t
JOIN pg_class c ON t.tablename = c.relname
WHERE t.schemaname = 'public'
ORDER BY t.tablename;

-- Get detailed index information
SELECT json_build_object(
    'type', 'indexes',
    'data', json_agg(json_build_object(
        'table_name', t.table_name,
        'index_name', i.indexname,
        'index_definition', i.indexdef,
        'table_size', pg_size_pretty(pg_relation_size(quote_ident(t.table_name)::text)),
        'index_size', pg_size_pretty(pg_relation_size(quote_ident(i.indexname)::text)),
        'is_unique', i.indexdef LIKE '%UNIQUE%'
    ))
)
FROM pg_indexes i
JOIN information_schema.tables t ON i.tablename = t.table_name
WHERE t.table_schema = 'public'
ORDER BY t.table_name, i.indexname;

-- Get table security configurations
SELECT json_build_object(
    'type', 'table_security',
    'data', json_agg(json_build_object(
        'table_name', t.table_name,
        'public_select', has_table_privilege('public', quote_ident(t.table_name)::regclass, 'SELECT'),
        'public_insert', has_table_privilege('public', quote_ident(t.table_name)::regclass, 'INSERT'),
        'public_update', has_table_privilege('public', quote_ident(t.table_name)::regclass, 'UPDATE'),
        'public_delete', has_table_privilege('public', quote_ident(t.table_name)::regclass, 'DELETE'),
        'rls_enabled', c.relrowsecurity,
        'rls_forced', c.relforcerowsecurity
    ))
)
FROM information_schema.tables t
JOIN pg_class c ON t.table_name = c.relname
WHERE t.table_schema = 'public'
ORDER BY t.table_name;

-- Get triggers
SELECT json_build_object(
    'type', 'triggers',
    'data', json_agg(json_build_object(
        'table_name', event_object_table,
        'trigger_name', trigger_name,
        'event_manipulation', event_manipulation,
        'action_timing', action_timing,
        'action_statement', action_statement
    ))
)
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name; 