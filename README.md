# Gcare Backend (Firebase Functions)

This is the Firebase Functions backend for the Gcare application, providing a RESTful API for the mobile and web clients.

## Prerequisites

1. Node.js 18 or later
2. Firebase CLI (`npm install -g firebase-tools`)
3. A Firebase project with Firestore, Authentication, and Storage enabled

## Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd gcare
   ```

2. **Install dependencies**
   ```bash
   cd functions
   npm install
   ```

3. **Set up environment variables**
   - Copy `.env.example` to `.env` in the `functions` directory
   - Update the values with your Firebase project credentials

4. **Initialize Firebase**
   ```bash
   firebase login
   firebase use <your-project-id>
   ```

## Running Locally

1. Start the Firebase emulator:
   ```bash
   firebase emulators:start
   ```

2. The API will be available at: `http://localhost:5001/YOUR-PROJECT-ID/us-central1/api`

## Deployment

1. Build the project:
   ```bash
   cd functions
   npm run build
   ```

2. Deploy to Firebase:
   ```bash
   firebase deploy
   ```

## Project Structure

```
functions/
├── src/
│   ├── controllers/    # Request handlers
│   ├── middlewares/    # Express middlewares
│   ├── routes/         # API routes
│   ├── services/       # Business logic
│   ├── utils/          # Utility functions
│   └── index.ts        # Main entry point
├── .env.example        # Example environment variables
├── package.json        # Dependencies and scripts
└── tsconfig.json       # TypeScript configuration
```

## API Documentation

After starting the server, API documentation is available at:
- Local: `http://localhost:5001/YOUR-PROJECT-ID/us-central1/api/api-docs/`
- Production: `https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/api/api-docs/`

## Environment Variables

See `.env.example` for the list of required environment variables.

## License

This project is proprietary and confidential. All rights reserved.
