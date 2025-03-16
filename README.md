# AKC Fresh

A modern web application for managing construction projects, built with Next.js 14 and Supabase.

## Features

- 🔐 Authentication with Google OAuth
- 📋 Task Management
- 🏗️ Project Management
- 📊 Invoice Generation and Tracking
- 👥 Client Management
- ⏱️ Time Tracking
- 📄 Document Management
- 💰 Expense Tracking

## Tech Stack

- Next.js 14 (App Router)
- TypeScript
- Supabase (Auth, Database)
- Tailwind CSS
- Shadcn/ui Components

## Getting Started

### Prerequisites

- Node.js 18.x or higher
- npm 9.x or higher
- A Supabase project

### Environment Setup

1. Create a `.env.local` file in the root directory:
```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/akc-fresh.git
cd akc-fresh
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

4. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

```
src/
├── app/                 # Next.js app router pages
│   ├── auth/           # Authentication routes
│   ├── dashboard/      # Dashboard and task management
│   └── layout.tsx      # Root layout
├── components/         # React components
│   ├── auth/          # Authentication components
│   ├── layout/        # Layout components
│   ├── providers/     # Context providers
│   └── ui/            # UI components
├── utils/             # Utility functions
│   └── supabase/      # Supabase client utilities
└── types/             # TypeScript type definitions
```

## Authentication Flow

1. Users can sign in with Google OAuth
2. Session management is handled by Supabase
3. Protected routes redirect to login if not authenticated
4. Row Level Security (RLS) policies protect data in Supabase

## Development

### Commands

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint

## Database Structure

### Tables
The application uses a PostgreSQL database with the following main tables:
- `user_profiles`: Stores user information
- `tasks`: Tracks individual tasks with status, priority, and assignments
- `projects`: Manages construction projects
- `clients`: Stores client information
- `time_entries`: Records time spent on tasks and projects
- `documents`: Manages files and documents
- `invoices`: Tracks billing and payments

### Relationships and Integrity
The database maintains referential integrity through foreign key relationships:
- Tasks are associated with projects (cascade delete)
- Tasks can be assigned to users (set null on delete)
- Projects are linked to clients (restrict delete)
- Time entries are linked to both projects and tasks

### Performance Optimization
The database is optimized for performance with strategic indexes:
- Single-column indexes on frequently queried fields like `project_id`, `assigned_to_id`, etc.
- Composite indexes for common query patterns (e.g., `project_id` + `status`)
- Primary keys on all tables for efficient lookups

### Data Validation
Check constraints ensure data consistency:
- Task status must be one of: 'pending', 'in_progress', 'completed', 'cancelled'
- Task priority must be one of: 'low', 'medium', 'high', 'urgent'
- Project status must be one of: 'planning', 'active', 'on_hold', 'completed', 'cancelled'

### Database Migrations
Database setup and modification scripts are available in the `migrations/` directory:
- `001_add_foreign_keys.sql`: Basic foreign key relationships
- `002_robust_foreign_keys_and_indexes.sql`: Improved version with error handling

## Contributing

1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License

This project is licensed under the MIT License. 