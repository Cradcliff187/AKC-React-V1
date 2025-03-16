-- Robust Foreign Key and Index Creation Script
-- This script includes error handling and checks for column existence before creating constraints

-- ==================== FOREIGN KEY CONSTRAINTS ====================

-- Tasks -> Projects relationship
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'project_id'
    ) THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_tasks_project') THEN
            ALTER TABLE tasks
                ADD CONSTRAINT fk_tasks_project
                FOREIGN KEY (project_id) 
                REFERENCES projects(id)
                ON DELETE CASCADE;
            RAISE NOTICE 'Added fk_tasks_project constraint';
        ELSE
            RAISE NOTICE 'fk_tasks_project constraint already exists';
        END IF;
    ELSE
        RAISE NOTICE 'Column project_id not found in tasks table, skipping constraint';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating fk_tasks_project: %', SQLERRM;
END $$;

-- Tasks -> User Profiles (assigned_to) relationship
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'assigned_to_id'
    ) THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_tasks_assigned_to') THEN
            ALTER TABLE tasks
                ADD CONSTRAINT fk_tasks_assigned_to
                FOREIGN KEY (assigned_to_id) 
                REFERENCES user_profiles(id)
                ON DELETE SET NULL;
            RAISE NOTICE 'Added fk_tasks_assigned_to constraint';
        ELSE
            RAISE NOTICE 'fk_tasks_assigned_to constraint already exists';
        END IF;
    ELSE
        RAISE NOTICE 'Column assigned_to_id not found in tasks table, skipping constraint';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating fk_tasks_assigned_to: %', SQLERRM;
END $$;

-- Tasks -> User Profiles (created_by) relationship
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'created_by_id'
    ) THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_tasks_created_by') THEN
            ALTER TABLE tasks
                ADD CONSTRAINT fk_tasks_created_by
                FOREIGN KEY (created_by_id) 
                REFERENCES user_profiles(id)
                ON DELETE SET NULL;
            RAISE NOTICE 'Added fk_tasks_created_by constraint';
        ELSE
            RAISE NOTICE 'fk_tasks_created_by constraint already exists';
        END IF;
    ELSE
        RAISE NOTICE 'Column created_by_id not found in tasks table, skipping constraint';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating fk_tasks_created_by: %', SQLERRM;
END $$;

-- Projects -> Clients relationship
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'projects' AND column_name = 'client_id'
    ) THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_projects_client') THEN
            ALTER TABLE projects
                ADD CONSTRAINT fk_projects_client
                FOREIGN KEY (client_id) 
                REFERENCES clients(id)
                ON DELETE RESTRICT;
            RAISE NOTICE 'Added fk_projects_client constraint';
        ELSE
            RAISE NOTICE 'fk_projects_client constraint already exists';
        END IF;
    ELSE
        RAISE NOTICE 'Column client_id not found in projects table, skipping constraint';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating fk_projects_client: %', SQLERRM;
END $$;

-- ==================== STANDARD INDEXES ====================

-- Task assignment index
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'assigned_to_id'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'public' AND tablename = 'tasks' AND indexname = 'idx_tasks_assigned_to_id'
        ) THEN
            CREATE INDEX idx_tasks_assigned_to_id ON tasks(assigned_to_id);
            RAISE NOTICE 'Created index idx_tasks_assigned_to_id';
        ELSE
            RAISE NOTICE 'Index idx_tasks_assigned_to_id already exists';
        END IF;
    ELSE
        RAISE NOTICE 'Column assigned_to_id not found in tasks table, skipping index';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating idx_tasks_assigned_to_id: %', SQLERRM;
END $$;

-- Task creator index
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'created_by_id'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'public' AND tablename = 'tasks' AND indexname = 'idx_tasks_created_by_id'
        ) THEN
            CREATE INDEX idx_tasks_created_by_id ON tasks(created_by_id);
            RAISE NOTICE 'Created index idx_tasks_created_by_id';
        ELSE
            RAISE NOTICE 'Index idx_tasks_created_by_id already exists';
        END IF;
    ELSE
        RAISE NOTICE 'Column created_by_id not found in tasks table, skipping index';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating idx_tasks_created_by_id: %', SQLERRM;
END $$;

-- Document uploader index
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'documents'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'documents' AND column_name = 'uploaded_by'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'public' AND tablename = 'documents' AND indexname = 'idx_documents_uploaded_by'
        ) THEN
            CREATE INDEX idx_documents_uploaded_by ON documents(uploaded_by);
            RAISE NOTICE 'Created index idx_documents_uploaded_by';
        ELSE
            RAISE NOTICE 'Index idx_documents_uploaded_by already exists';
        END IF;
    ELSE
        RAISE NOTICE 'Table documents or column uploaded_by not found, skipping index';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating idx_documents_uploaded_by: %', SQLERRM;
END $$;

-- ==================== COMPOSITE INDEXES ====================

-- Tasks filtered by project and status
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'project_id'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'status'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'public' AND tablename = 'tasks' AND indexname = 'idx_tasks_project_status'
        ) THEN
            CREATE INDEX idx_tasks_project_status ON tasks(project_id, status);
            RAISE NOTICE 'Created index idx_tasks_project_status';
        ELSE
            RAISE NOTICE 'Index idx_tasks_project_status already exists';
        END IF;
    ELSE
        RAISE NOTICE 'Columns required for idx_tasks_project_status not found, skipping index';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating idx_tasks_project_status: %', SQLERRM;
END $$;

-- Tasks filtered by assignee and status
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'assigned_to_id'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'status'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'public' AND tablename = 'tasks' AND indexname = 'idx_tasks_assigned_status'
        ) THEN
            CREATE INDEX idx_tasks_assigned_status ON tasks(assigned_to_id, status);
            RAISE NOTICE 'Created index idx_tasks_assigned_status';
        ELSE
            RAISE NOTICE 'Index idx_tasks_assigned_status already exists';
        END IF;
    ELSE
        RAISE NOTICE 'Columns required for idx_tasks_assigned_status not found, skipping index';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating idx_tasks_assigned_status: %', SQLERRM;
END $$;

-- Time entries by project and date
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'time_entries'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'time_entries' AND column_name = 'project_id'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'time_entries' AND column_name = 'date'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'public' AND tablename = 'time_entries' AND indexname = 'idx_time_entries_project_date'
        ) THEN
            CREATE INDEX idx_time_entries_project_date ON time_entries(project_id, date);
            RAISE NOTICE 'Created index idx_time_entries_project_date';
        ELSE
            RAISE NOTICE 'Index idx_time_entries_project_date already exists';
        END IF;
    ELSE
        RAISE NOTICE 'Table time_entries or required columns not found, skipping index';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating idx_time_entries_project_date: %', SQLERRM;
END $$;

-- ==================== CHECK CONSTRAINTS ====================

-- Task status constraints
DO $$
BEGIN
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
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating chk_tasks_status: %', SQLERRM;
END $$;

-- Task priority constraints
DO $$
BEGIN
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
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating chk_tasks_priority: %', SQLERRM;
END $$;

-- Project status constraints
DO $$
BEGIN
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
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating chk_projects_status: %', SQLERRM;
END $$; 