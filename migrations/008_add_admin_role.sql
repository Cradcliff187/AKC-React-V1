-- Simple admin role function
-- This adds admin capabilities without changing existing RLS policies

-- Create admin check function (won't fail if it already exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_admin') THEN
        CREATE FUNCTION public.is_admin()
        RETURNS BOOLEAN AS $$
        BEGIN
            RETURN EXISTS (
                SELECT 1 FROM user_profiles
                WHERE auth_id = auth.uid()::text
                AND role = 'admin'
            );
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
        
        RAISE NOTICE 'Created is_admin() function';
    ELSE
        RAISE NOTICE 'is_admin() function already exists';
    END IF;
END $$; 