-- Create a function to run SQL queries with proper permissions
CREATE OR REPLACE FUNCTION run_sql_query(query text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (SELECT json_agg(t) FROM json_each(query::json) t);
EXCEPTION WHEN others THEN
  RETURN json_build_array(
    json_build_object(
      'error', SQLERRM,
      'detail', SQLSTATE
    )
  );
END;
$$; 