-- Function to get all tables
CREATE OR REPLACE FUNCTION get_tables(schema_name text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    SELECT json_agg(json_build_object(
      'table_name', table_name,
      'table_type', table_type
    ))
    FROM information_schema.tables
    WHERE table_schema = schema_name
  );
END;
$$;

-- Function to get all policies
CREATE OR REPLACE FUNCTION get_policies(schema_name text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    SELECT json_agg(json_build_object(
      'tablename', tablename,
      'policyname', policyname,
      'permissive', permissive,
      'roles', roles,
      'cmd', cmd,
      'qual', qual,
      'with_check', with_check
    ))
    FROM pg_policies
    WHERE schemaname = schema_name
  );
END;
$$;

-- Function to get all indexes
CREATE OR REPLACE FUNCTION get_indexes(schema_name text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    SELECT json_agg(json_build_object(
      'tablename', tablename,
      'indexname', indexname,
      'indexdef', indexdef
    ))
    FROM pg_indexes
    WHERE schemaname = schema_name
  );
END;
$$;

-- Function to get table security configurations
CREATE OR REPLACE FUNCTION get_table_security(schema_name text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    SELECT json_agg(json_build_object(
      'table_name', t.table_name,
      'public_select', has_table_privilege('public', quote_ident(t.table_name)::regclass, 'SELECT'),
      'public_insert', has_table_privilege('public', quote_ident(t.table_name)::regclass, 'INSERT'),
      'public_update', has_table_privilege('public', quote_ident(t.table_name)::regclass, 'UPDATE'),
      'public_delete', has_table_privilege('public', quote_ident(t.table_name)::regclass, 'DELETE'),
      'rls_enabled', c.relrowsecurity,
      'rls_forced', c.relforcerowsecurity
    ))
    FROM information_schema.tables t
    JOIN pg_class c ON t.table_name = c.relname
    WHERE t.table_schema = schema_name
  );
END;
$$; 