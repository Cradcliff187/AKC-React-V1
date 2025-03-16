-- Add Foreign Key Relationships
-- Split into multiple transactions for safety

-- Transaction 1: Tasks table relationships
BEGIN;
DO $$
BEGIN
    -- Only add if the constraint doesn't exist
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
EXCEPTION
    WHEN undefined_column THEN
        RAISE WARNING 'Column project_id not found in tasks table';
    WHEN undefined_table THEN
        RAISE WARNING 'Table tasks or projects not found';
    WHEN OTHERS THEN
        RAISE WARNING 'Error adding fk_tasks_project: %', SQLERRM;
END $$;
COMMIT;

-- Transaction 2: Tasks - User relationships
BEGIN;
DO $$
BEGIN
    -- Check if assigned_to_id column exists
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
        RAISE WARNING 'Column assigned_to_id not found in tasks table';
    END IF;
END $$;
COMMIT;

BEGIN;
DO $$
BEGIN
    -- Check if created_by_id column exists
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
        RAISE WARNING 'Column created_by_id not found in tasks table';
    END IF;
END $$;
COMMIT;

-- Transaction 3: Projects - Client relationships
BEGIN;
DO $$
BEGIN
    -- Check if client_id column exists
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
        RAISE WARNING 'Column client_id not found in projects table';
    END IF;
END $$;
COMMIT;

-- Transaction 4: Time entries relationships
BEGIN;
DO $$
BEGIN
    -- Check if time_entries and related columns exist
    IF EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'time_entries'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'time_entries' AND column_name = 'project_id'
    ) THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_time_entries_project') THEN
            ALTER TABLE time_entries
                ADD CONSTRAINT fk_time_entries_project
                FOREIGN KEY (project_id) 
                REFERENCES projects(id)
                ON DELETE CASCADE;
                
            RAISE NOTICE 'Added fk_time_entries_project constraint';
        ELSE
            RAISE NOTICE 'fk_time_entries_project constraint already exists';
        END IF;
    ELSE
        RAISE WARNING 'Table time_entries or column project_id not found';
    END IF;
END $$;
COMMIT;

BEGIN;
DO $$
BEGIN
    -- Check if time_entries and related columns exist
    IF EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'time_entries'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'time_entries' AND column_name = 'task_id'
    ) THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_time_entries_task') THEN
            ALTER TABLE time_entries
                ADD CONSTRAINT fk_time_entries_task
                FOREIGN KEY (task_id) 
                REFERENCES tasks(id)
                ON DELETE CASCADE;
                
            RAISE NOTICE 'Added fk_time_entries_task constraint';
        ELSE
            RAISE NOTICE 'fk_time_entries_task constraint already exists';
        END IF;
    ELSE
        RAISE WARNING 'Table time_entries or column task_id not found';
    END IF;
END $$;
COMMIT;

-- Transaction 5: Documents relationships
BEGIN;
DO $$
BEGIN
    -- Check if documents and related columns exist
    IF EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'documents'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'documents' AND column_name = 'project_id'
    ) THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_documents_project') THEN
            ALTER TABLE documents
                ADD CONSTRAINT fk_documents_project
                FOREIGN KEY (project_id) 
                REFERENCES projects(id)
                ON DELETE CASCADE;
                
            RAISE NOTICE 'Added fk_documents_project constraint';
        ELSE
            RAISE NOTICE 'fk_documents_project constraint already exists';
        END IF;
    ELSE
        RAISE WARNING 'Table documents or column project_id not found';
    END IF;
END $$;
COMMIT;

BEGIN;
DO $$
BEGIN
    -- Check if documents and related columns exist
    IF EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'documents'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'documents' AND column_name = 'client_id'
    ) THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_documents_client') THEN
            ALTER TABLE documents
                ADD CONSTRAINT fk_documents_client
                FOREIGN KEY (client_id) 
                REFERENCES clients(id)
                ON DELETE CASCADE;
                
            RAISE NOTICE 'Added fk_documents_client constraint';
        ELSE
            RAISE NOTICE 'fk_documents_client constraint already exists';
        END IF;
    ELSE
        RAISE WARNING 'Table documents or column client_id not found';
    END IF;
END $$;
COMMIT;

-- Transaction 6: Document access relationships
BEGIN;
DO $$
BEGIN
    -- Check if document_access and related columns exist
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'document_access'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'document_access' AND column_name = 'document_id'
    ) THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_document_access_document') THEN
            ALTER TABLE document_access
                ADD CONSTRAINT fk_document_access_document
                FOREIGN KEY (document_id) 
                REFERENCES documents(id)
                ON DELETE CASCADE;
                
            RAISE NOTICE 'Added fk_document_access_document constraint';
        ELSE
            RAISE NOTICE 'fk_document_access_document constraint already exists';
        END IF;
    ELSE
        RAISE WARNING 'Table document_access or column document_id not found';
    END IF;
END $$;
COMMIT;

-- Transaction 7: Additional indexes for performance
BEGIN;
DO $$
BEGIN
    -- Check if assigned_to_id column exists in tasks
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
        RAISE WARNING 'Column assigned_to_id not found in tasks table';
    END IF;
END $$;
COMMIT;

BEGIN;
DO $$
BEGIN
    -- Check if created_by_id column exists in tasks
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
        RAISE WARNING 'Column created_by_id not found in tasks table';
    END IF;
END $$;
COMMIT;

BEGIN;
DO $$
BEGIN
    -- Check if uploaded_by column exists in documents
    IF EXISTS (
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
        RAISE WARNING 'Column uploaded_by not found in documents table';
    END IF;
END $$;
COMMIT;

-- Transaction 8: Composite indexes for frequently combined queries
BEGIN;
DO $$
BEGIN
    -- Check if project_id and status columns exist in tasks
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
        RAISE WARNING 'Columns required for idx_tasks_project_status not found';
    END IF;
END $$;
COMMIT;

BEGIN;
DO $$
BEGIN
    -- Check if assigned_to_id and status columns exist in tasks
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
        RAISE WARNING 'Columns required for idx_tasks_assigned_status not found';
    END IF;
END $$;
COMMIT;

BEGIN;
DO $$
BEGIN
    -- Check if project_id and date columns exist in time_entries
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
        RAISE WARNING 'Columns required for idx_time_entries_project_date not found';
    END IF;
END $$;
COMMIT;

-- Transaction 9: Add check constraints for data integrity
BEGIN;
DO $$
BEGIN
    -- Check if status column exists in tasks
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
        RAISE WARNING 'Column status not found in tasks table';
    END IF;
END $$;
COMMIT;

BEGIN;
DO $$
BEGIN
    -- Check if priority column exists in tasks
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
        RAISE WARNING 'Column priority not found in tasks table';
    END IF;
END $$;
COMMIT;

BEGIN;
DO $$
BEGIN
    -- Check if status column exists in projects
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
        RAISE WARNING 'Column status not found in projects table';
    END IF;
END $$;
COMMIT;

-- Transaction 10: Add comments for documentation
DO $$
BEGIN
    -- Only add comments if the constraints exist
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_tasks_project') THEN
        COMMENT ON CONSTRAINT fk_tasks_project ON tasks IS 'Ensures each task belongs to a valid project';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_tasks_assigned_to') THEN
        COMMENT ON CONSTRAINT fk_tasks_assigned_to ON tasks IS 'Links tasks to assigned users';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' AND tablename = 'tasks' AND indexname = 'idx_tasks_project_status'
    ) THEN
        COMMENT ON INDEX idx_tasks_project_status IS 'Optimizes queries filtering tasks by project and status';
    END IF;
END $$; 