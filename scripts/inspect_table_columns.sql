-- Script to inspect the column structure of key tables
-- Run this in your Supabase SQL Editor to verify columns before creating constraints

-- Check documents table columns
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_schema = 'public' 
    AND table_name = 'documents'
ORDER BY 
    ordinal_position;

-- Check tasks table columns
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_schema = 'public' 
    AND table_name = 'tasks'
ORDER BY 
    ordinal_position;

-- Check projects table columns
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_schema = 'public' 
    AND table_name = 'projects'
ORDER BY 
    ordinal_position;

-- Check time_entries table columns
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_schema = 'public' 
    AND table_name = 'time_entries'
ORDER BY 
    ordinal_position; 