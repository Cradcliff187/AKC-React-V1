# AKC React V1

A React-based frontend application for managing construction projects, invoices, and client relationships.

## Features

- User Authentication with Supabase
- Project Management
- Invoice Generation and Tracking
- Client Management
- Time Tracking
- Document Management
- Expense Tracking

## Getting Started

### Prerequisites

- Node.js 16.x or higher
- npm 7.x or higher

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/akc-react-v1.git
cd akc-react-v1
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file in the root directory and add your Supabase credentials:
```env
REACT_APP_SUPABASE_URL=your_supabase_url
REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Start the development server:
```bash
npm start
```

## Available Scripts

- `npm start` - Runs the app in development mode
- `npm test` - Launches the test runner
- `npm run build` - Builds the app for production
- `npm run eject` - Ejects from Create React App

## Project Structure

```
src/
  ├── components/     # Reusable components
  ├── pages/         # Page components
  ├── hooks/         # Custom hooks
  ├── services/      # API and service functions
  ├── utils/         # Utility functions
  ├── types/         # TypeScript type definitions
  ├── assets/        # Static assets
  └── styles/        # Global styles and themes
```

## Technology Stack

- React 18
- TypeScript
- Supabase
- React Router
- Create React App 