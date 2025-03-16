# Database Migration Scripts

This directory contains SQL scripts for managing the database schema, including creating tables, adding constraints, and setting up indexes. These scripts help maintain data integrity and optimize query performance.

## How to Run These Scripts

### Running in Supabase SQL Editor

1. Log in to your Supabase dashboard
2. Navigate to the SQL Editor
3. Copy and paste the contents of the script you want to run
4. Click "Run" to execute the script

### Order of Execution

Run scripts in the order of their filename prefix:

1. `001_add_foreign_keys.sql` - Basic version (not recommended)
2. `002_robust_foreign_keys_and_indexes.sql` - Recommended version with error handling
3. `003_fix_enum_constraints.sql` - Handles enum type columns properly
4. `004_rls_with_error_handling.sql` - Sets up Row Level Security policies with error handling

### Important Notes

- The `002_robust_foreign_keys_and_indexes.sql` script is preferred as it:
  - Checks for column existence before creating constraints or indexes
  - Handles errors gracefully
  - Provides detailed notifications
  - Won't fail if a column or table doesn't exist

- The `003_fix_enum_constraints.sql` script addresses an important issue:
  - Some columns may be defined as enum types in Supabase
  - Enum types already enforce value constraints
  - Attempting to add CHECK constraints to enum columns causes errors
  - This script detects enum columns and handles them appropriately

- The `004_rls_with_error_handling.sql` script sets up Row Level Security:
  - Creates a helper function to safely add policies
  - Ensures RLS is enabled on all tables
  - Sets up role-based access control
  - Protects data with user-level permissions
  - Adds helper functions for common permission checks

- Before running these scripts, you may want to run:
  - `scripts/inspect_table_columns.sql` to verify your table structure
  - `scripts/inspect_enum_types.sql` to identify enum types and their allowed values

## Troubleshooting

If you encounter errors:

1. Check that all referenced tables and columns actually exist
2. Ensure that any existing data conforms to the constraints being added
3. Look for existing constraints or indexes with the same name
4. Check the error messages - they often provide helpful information

## Adding New Constraints or Indexes

When adding new constraints or indexes, follow the pattern in `002_robust_foreign_keys_and_indexes.sql`:

1. Check if the columns/tables exist
2. Check if the constraint/index already exists
3. Add the constraint/index inside a try-catch block
4. Provide clear NOTICE messages

This approach ensures your scripts are robust and can be run repeatedly without errors. 