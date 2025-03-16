-- Create a test table
create table if not exists test_table (
    id uuid default uuid_generate_v4() primary key,
    description text,
    timestamp timestamptz default now(),
    created_at timestamptz default now()
);

-- Enable Row Level Security (RLS)
alter table test_table enable row level security;

-- Create a policy that allows all operations for now (for testing)
create policy "Allow all operations for testing"
    on test_table
    for all
    using (true)
    with check (true); 