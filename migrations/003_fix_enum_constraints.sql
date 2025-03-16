-- Fix for enum constraint errors
-- This script checks if columns are enums and adapts constraints accordingly

-- Function to check enum values and set appropriate constraints
DO $$
DECLARE
    project_status_values TEXT[];
    task_status_values TEXT[];
    task_priority_values TEXT[];
BEGIN
    -- Check if projects.status is an enum type
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_attribute a
        JOIN pg_catalog.pg_type t ON a.atttypid = t.oid
        JOIN pg_catalog.pg_namespace n ON t.typnamespace = n.oid
        WHERE a.attrelid = 'public.projects'::regclass
        AND a.attname = 'status'
        AND t.typtype = 'e'
    ) THEN
        -- Get the enum values for project_status
        SELECT array_agg(enumlabel) INTO project_status_values
        FROM pg_catalog.pg_enum
        WHERE enumtypid = (
            SELECT atttypid FROM pg_catalog.pg_attribute a
            JOIN pg_catalog.pg_type t ON a.atttypid = t.oid
            WHERE a.attrelid = 'public.projects'::regclass
            AND a.attname = 'status'
        );
        
        RAISE NOTICE 'projects.status is an enum with values: %', project_status_values;
        
        -- Skip adding the CHECK constraint since the enum already restricts values
        RAISE NOTICE 'Skipping CHECK constraint for projects.status as it is already an enum type';
    ELSE
        -- If it's not an enum, add the check constraint as before
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'projects' AND column_name = 'status'
        ) THEN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_projects_status') THEN
                ALTER TABLE projects
                    ADD CONSTRAINT chk_projects_status
                    CHECK (status IN ('planning', 'active', 'on_hold', 'completed', 'cancelled'));
                RAISE NOTICE 'Added chk_projects_status constraint';
            ELSE
                RAISE NOTICE 'chk_projects_status constraint already exists';
            END IF;
        ELSE
            RAISE NOTICE 'Column status not found in projects table, skipping constraint';
        END IF;
    END IF;

    -- Check if tasks.status is an enum type
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_attribute a
        JOIN pg_catalog.pg_type t ON a.atttypid = t.oid
        JOIN pg_catalog.pg_namespace n ON t.typnamespace = n.oid
        WHERE a.attrelid = 'public.tasks'::regclass
        AND a.attname = 'status'
        AND t.typtype = 'e'
    ) THEN
        -- Get the enum values for task_status
        SELECT array_agg(enumlabel) INTO task_status_values
        FROM pg_catalog.pg_enum
        WHERE enumtypid = (
            SELECT atttypid FROM pg_catalog.pg_attribute a
            JOIN pg_catalog.pg_type t ON a.atttypid = t.oid
            WHERE a.attrelid = 'public.tasks'::regclass
            AND a.attname = 'status'
        );
        
        RAISE NOTICE 'tasks.status is an enum with values: %', task_status_values;
        
        -- Skip adding the CHECK constraint since the enum already restricts values
        RAISE NOTICE 'Skipping CHECK constraint for tasks.status as it is already an enum type';
    ELSE
        -- If it's not an enum, add the check constraint as before
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'status'
        ) THEN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_tasks_status') THEN
                ALTER TABLE tasks
                    ADD CONSTRAINT chk_tasks_status
                    CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'));
                RAISE NOTICE 'Added chk_tasks_status constraint';
            ELSE
                RAISE NOTICE 'chk_tasks_status constraint already exists';
            END IF;
        ELSE
            RAISE NOTICE 'Column status not found in tasks table, skipping constraint';
        END IF;
    END IF;

    -- Check if tasks.priority is an enum type
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_attribute a
        JOIN pg_catalog.pg_type t ON a.atttypid = t.oid
        JOIN pg_catalog.pg_namespace n ON t.typnamespace = n.oid
        WHERE a.attrelid = 'public.tasks'::regclass
        AND a.attname = 'priority'
        AND t.typtype = 'e'
    ) THEN
        -- Get the enum values for task_priority
        SELECT array_agg(enumlabel) INTO task_priority_values
        FROM pg_catalog.pg_enum
        WHERE enumtypid = (
            SELECT atttypid FROM pg_catalog.pg_attribute a
            JOIN pg_catalog.pg_type t ON a.atttypid = t.oid
            WHERE a.attrelid = 'public.tasks'::regclass
            AND a.attname = 'priority'
        );
        
        RAISE NOTICE 'tasks.priority is an enum with values: %', task_priority_values;
        
        -- Skip adding the CHECK constraint since the enum already restricts values
        RAISE NOTICE 'Skipping CHECK constraint for tasks.priority as it is already an enum type';
    ELSE
        -- If it's not an enum, add the check constraint as before
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'priority'
        ) THEN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_tasks_priority') THEN
                ALTER TABLE tasks
                    ADD CONSTRAINT chk_tasks_priority
                    CHECK (priority IN ('low', 'medium', 'high', 'urgent'));
                RAISE NOTICE 'Added chk_tasks_priority constraint';
            ELSE
                RAISE NOTICE 'chk_tasks_priority constraint already exists';
            END IF;
        ELSE
            RAISE NOTICE 'Column priority not found in tasks table, skipping constraint';
        END IF;
    END IF;
END $$;

-- Query to show all enum types and their values in the database
-- Useful for debugging and understanding the existing enum structure
SELECT
    n.nspname AS schema,
    t.typname AS enum_name,
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