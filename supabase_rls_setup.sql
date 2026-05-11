-- Supabase RLS Policy Setup for Mobile Auth
-- Run these SQL queries in Supabase SQL Editor if profiles table has RLS enabled

-- Step 1: Enable RLS on profiles table (if not already enabled)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Step 2: Create policies for authenticated users

-- Allow users to INSERT their own profile
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Allow users to READ their own profile
DROP POLICY IF EXISTS "Users can read their own profile" ON profiles;
CREATE POLICY "Users can read their own profile" ON profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Allow users to UPDATE their own profile
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow users to VIEW other profiles (for friends/map feature)
-- Optional: customize based on privacy settings
DROP POLICY IF EXISTS "Users can view other profiles" ON profiles;
CREATE POLICY "Users can view other profiles" ON profiles
  FOR SELECT
  USING (true);  -- or: USING (is_public = true) if you have privacy setting

-- Step 3: Verify policies are in place
-- Query: SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- Step 4: Grant permissions (if using role-based access)
-- Grant authenticated role access to profiles table
GRANT SELECT ON profiles TO authenticated;
GRANT INSERT ON profiles TO authenticated;
GRANT UPDATE ON profiles TO authenticated;

-- Optional: Grant anon role for sign-up flow (if needed)
GRANT SELECT ON profiles TO anon;

-- Verify with:
-- SELECT grantee, privilege_type FROM role_table_grants 
-- WHERE table_name = 'profiles';
