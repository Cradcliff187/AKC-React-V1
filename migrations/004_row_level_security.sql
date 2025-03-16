-- Row Level Security Policies
-- This script sets up RLS policies for all tables in the database

-- ===========================================
-- User Profiles - Base table for user access
-- ===========================================
CREATE POLICY "Users can view their own profile"
ON public.user_profiles FOR SELECT
USING (auth.uid() = auth_id::uuid);

CREATE POLICY "Users can update their own profile"
ON public.user_profiles FOR UPDATE
USING (auth.uid() = auth_id::uuid);

-- Admin access to all user profiles
CREATE POLICY "Admins can view all profiles"
ON public.user_profiles FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role = 'admin'
  )
);

CREATE POLICY "Admins can update all profiles"
ON public.user_profiles FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role = 'admin'
  )
);

-- ===========================================
-- Tasks - Core functionality
-- ===========================================
-- View tasks: Users can view tasks they created or are assigned to, or in projects they're part of
CREATE POLICY "Users can view relevant tasks"
ON public.tasks FOR SELECT
USING (
  created_by_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR assigned_to_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR project_id IN (
    SELECT p.id FROM projects p
    JOIN user_profiles up ON p.created_by = up.id OR p.client_id IN (
      SELECT c.id FROM clients c
      WHERE c.account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
    )
    WHERE up.auth_id = auth.uid()::text
  )
);

-- Insert tasks: Users can create tasks
CREATE POLICY "Users can create tasks"
ON public.tasks FOR INSERT
WITH CHECK (
  auth.role() = 'authenticated'
);

-- Update tasks: Users can update tasks they created or are assigned to
CREATE POLICY "Users can update their own tasks"
ON public.tasks FOR UPDATE
USING (
  created_by_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR assigned_to_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- Delete tasks: Only task creators or admins/managers can delete tasks
CREATE POLICY "Users can delete their own tasks"
ON public.tasks FOR DELETE
USING (
  created_by_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- ===========================================
-- Projects
-- ===========================================
-- View projects: Users can view projects they created or are involved with
CREATE POLICY "Users can view relevant projects"
ON public.projects FOR SELECT
USING (
  created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR id IN (
    SELECT project_id FROM tasks
    WHERE assigned_to_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  )
  OR client_id IN (
    SELECT c.id FROM clients c
    WHERE c.account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  )
);

-- Insert projects: Any authenticated user can create projects
CREATE POLICY "Users can create projects"
ON public.projects FOR INSERT
WITH CHECK (
  auth.role() = 'authenticated'
);

-- Update projects: Only project creators, admins, or managers can update projects
CREATE POLICY "Users can update their own projects"
ON public.projects FOR UPDATE
USING (
  created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- Delete projects: Only project creators, admins, or managers can delete projects
CREATE POLICY "Users can delete their own projects"
ON public.projects FOR DELETE
USING (
  created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- ===========================================
-- Clients
-- ===========================================
-- View clients: Account managers, admins, and managers can view clients
CREATE POLICY "Users can view relevant clients"
ON public.clients FOR SELECT
USING (
  account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- Insert clients: Any authenticated user can create clients
CREATE POLICY "Users can create clients"
ON public.clients FOR INSERT
WITH CHECK (
  auth.role() = 'authenticated'
);

-- Update clients: Only account managers, admins, or managers can update clients
CREATE POLICY "Users can update assigned clients"
ON public.clients FOR UPDATE
USING (
  account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- Delete clients: Only admins or managers can delete clients
CREATE POLICY "Admins can delete clients"
ON public.clients FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- ===========================================
-- Time Entries
-- ===========================================
-- View time entries: Users can view their own time entries
CREATE POLICY "Users can view their own time entries"
ON public.time_entries FOR SELECT
USING (
  user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- Insert time entries: Users can create their own time entries
CREATE POLICY "Users can create their own time entries"
ON public.time_entries FOR INSERT
WITH CHECK (
  user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
);

-- Update time entries: Users can update their own time entries
CREATE POLICY "Users can update their own time entries"
ON public.time_entries FOR UPDATE
USING (
  user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- Delete time entries: Users can delete their own time entries
CREATE POLICY "Users can delete their own time entries"
ON public.time_entries FOR DELETE
USING (
  user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- ===========================================
-- Documents
-- ===========================================
-- View documents: Users can view documents for their projects or clients
CREATE POLICY "Users can view relevant documents"
ON public.documents FOR SELECT
USING (
  uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR project_id IN (
    SELECT p.id FROM projects p
    JOIN user_profiles up ON p.created_by = up.id
    WHERE up.auth_id = auth.uid()::text
  )
  OR client_id IN (
    SELECT c.id FROM clients c
    WHERE c.account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  )
  OR id IN (
    SELECT document_id FROM document_access
    WHERE user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  )
);

-- Insert documents: Any authenticated user can upload documents
CREATE POLICY "Users can upload documents"
ON public.documents FOR INSERT
WITH CHECK (
  auth.role() = 'authenticated'
);

-- Update documents: Only document uploaders, admins, or managers can update documents
CREATE POLICY "Users can update their own documents"
ON public.documents FOR UPDATE
USING (
  uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- Delete documents: Only document uploaders, admins, or managers can delete documents
CREATE POLICY "Users can delete their own documents"
ON public.documents FOR DELETE
USING (
  uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- ===========================================
-- Document Access
-- ===========================================
-- View document access: Users can view access records for documents they can access
CREATE POLICY "Users can view document access"
ON public.document_access FOR SELECT
USING (
  user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR document_id IN (
    SELECT id FROM documents
    WHERE uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  )
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- Insert document access: Only document uploaders, admins, or managers can grant access
CREATE POLICY "Users can grant document access"
ON public.document_access FOR INSERT
WITH CHECK (
  document_id IN (
    SELECT id FROM documents
    WHERE uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  )
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- Update document access: Only document uploaders, admins, or managers can update access
CREATE POLICY "Users can update document access"
ON public.document_access FOR UPDATE
USING (
  document_id IN (
    SELECT id FROM documents
    WHERE uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  )
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- Delete document access: Only document uploaders, admins, or managers can revoke access
CREATE POLICY "Users can revoke document access"
ON public.document_access FOR DELETE
USING (
  document_id IN (
    SELECT id FROM documents
    WHERE uploaded_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  )
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  )
);

-- ===========================================
-- Invoices
-- ===========================================
-- View invoices: Users can view invoices for their projects or clients
CREATE POLICY "Users can view relevant invoices"
ON public.invoices FOR SELECT
USING (
  created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR project_id IN (
    SELECT p.id FROM projects p
    JOIN user_profiles up ON p.created_by = up.id
    WHERE up.auth_id = auth.uid()::text
  )
  OR client_id IN (
    SELECT c.id FROM clients c
    WHERE c.account_manager_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  )
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager', 'accountant')
  )
);

-- Insert invoices: Any authenticated user can create invoices
CREATE POLICY "Users can create invoices"
ON public.invoices FOR INSERT
WITH CHECK (
  auth.role() = 'authenticated'
);

-- Update invoices: Only invoice creators, admins, managers, or accountants can update invoices
CREATE POLICY "Users can update their own invoices"
ON public.invoices FOR UPDATE
USING (
  created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager', 'accountant')
  )
);

-- Delete invoices: Only invoice creators, admins, managers, or accountants can delete invoices
CREATE POLICY "Users can delete their own invoices"
ON public.invoices FOR DELETE
USING (
  created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager', 'accountant')
  )
);

-- ===========================================
-- Expenses
-- ===========================================
-- View expenses: Users can view expenses for their projects
CREATE POLICY "Users can view relevant expenses"
ON public.expenses FOR SELECT
USING (
  created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR project_id IN (
    SELECT p.id FROM projects p
    JOIN user_profiles up ON p.created_by = up.id
    WHERE up.auth_id = auth.uid()::text
  )
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager', 'accountant')
  )
);

-- Insert expenses: Any authenticated user can create expenses
CREATE POLICY "Users can create expenses"
ON public.expenses FOR INSERT
WITH CHECK (
  auth.role() = 'authenticated'
);

-- Update expenses: Only expense creators, admins, managers, or accountants can update expenses
CREATE POLICY "Users can update their own expenses"
ON public.expenses FOR UPDATE
USING (
  created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager', 'accountant')
  )
);

-- Delete expenses: Only expense creators, admins, managers, or accountants can delete expenses
CREATE POLICY "Users can delete their own expenses"
ON public.expenses FOR DELETE
USING (
  created_by IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager', 'accountant')
  )
);

-- Helper function to check if user is admin or manager
CREATE OR REPLACE FUNCTION public.is_admin_or_manager()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles
    WHERE auth_id = auth.uid()::text
    AND role IN ('admin', 'manager')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is owner of a resource
CREATE OR REPLACE FUNCTION public.is_owner(creator_id uuid)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = creator_id
    AND auth_id = auth.uid()::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 