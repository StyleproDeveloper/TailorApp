# Tailor App - Full Stack Application

A comprehensive tailor shop management application built with Flutter (frontend) and Node.js/Express (backend).

## 🏗️ Project Structure

```
tailorapp/
├── lib/                    # Flutter frontend code
├── backend/               # Node.js backend code
├── web/                   # Flutter web assets
├── assets/                # Images and fonts
├── scripts/               # Development scripts
├── package.json           # Root package.json for managing both projects
└── README.md             # This file
```

## 🚀 Quick Start

### Prerequisites

- **Node.js** (v16 or higher)
- **Flutter** (v3.0 or higher)
- **MongoDB** (running locally or remotely)

### Installation

1. **Clone and setup the project:**
   ```bash
   git clone <your-repo-url>
   cd tailorapp
   ```

2. **Install all dependencies:**
   ```bash
   npm run install:all
   ```

3. **Setup environment variables:**
   - Backend: Edit `backend/.env` with your MongoDB connection string
   - Frontend: URLs are configured in `lib/Core/Services/Urls.dart`

### Development

#### Option 1: Run both frontend and backend together
```bash
npm run start:dev
```

#### Option 2: Run using the development script
```bash
./scripts/dev.sh
```

#### Option 3: Run separately
```bash
# Terminal 1 - Backend
npm run start:backend

# Terminal 2 - Frontend  
npm run start:frontend
```

## 🔧 Backend Development

The backend is located in the `backend/` directory and includes:

- **Express.js** server with RESTful APIs
- **MongoDB** with Mongoose ODM
- **JWT** authentication
- **Swagger** API documentation
- **CORS** enabled for frontend integration

### Backend Structure
```
backend/
├── src/
│   ├── controller/        # API controllers
│   ├── models/           # MongoDB models
│   ├── routes/           # API routes
│   ├── service/          # Business logic
│   ├── utils/            # Utility functions
│   ├── validations/      # Request validations
│   └── middlewares/      # Custom middlewares
├── package.json
└── .env                  # Environment variables
```

### API Documentation
Once the backend is running, visit: `http://localhost:5500/api-docs`

## 🎨 Frontend Development

The frontend is a Flutter web application with:

- **Responsive design** for web browsers
- **State management** with setState and ValueNotifier
- **API integration** with Dio HTTP client
- **Form validation** and error handling
- **Custom widgets** and reusable components

### Frontend Structure
```
lib/
├── Core/                 # Core utilities and services
│   ├── Constants/        # App constants
│   ├── Services/         # API services
│   ├── Tools/           # Helper functions
│   └── Widgets/         # Reusable widgets
├── Features/            # Feature-based modules
│   ├── AuthDirectory/   # Authentication
│   ├── RootDirectory/   # Main app features
│   └── Splash/          # Splash screen
└── Routes/              # App routing
```

## 🛠️ Available Scripts

- `npm run install:all` - Install both frontend and backend dependencies
- `npm run start:dev` - Run both frontend and backend in development mode
- `npm run start:backend` - Run only the backend server
- `npm run start:frontend` - Run only the frontend
- `npm run build:frontend` - Build frontend for production
- `npm run clean` - Clean all build artifacts and dependencies

## 🔗 API Endpoints

The backend provides the following main endpoints:

- `POST /auth/login` - User login
- `POST /auth/validate-otp` - OTP verification
- `GET /shops` - Get shops
- `POST /shops` - Create shop
- `GET /customer` - Get customers
- `POST /customer` - Create customer
- `GET /orders` - Get orders
- `POST /orders` - Create order
- And many more...

## 🐛 Troubleshooting

### Common Issues

1. **MongoDB Connection Error:**
   - Ensure MongoDB is running: `brew services start mongodb-community`
   - Check the connection string in `backend/.env`

2. **CORS Issues:**
   - Backend CORS is configured to allow all origins in development
   - Check `backend/src/app.js` for CORS settings

3. **Port Conflicts:**
   - Backend runs on port 5500
   - Frontend runs on port 8144
   - Change ports in respective configuration files if needed

4. **Flutter Web Issues:**
   - Run `flutter clean && flutter pub get`
   - Ensure you're using a compatible Flutter version

## 📝 Development Notes

- The backend uses MongoDB with Mongoose for data persistence
- Frontend uses SharedPreferences for local storage
- API responses follow a consistent format
- Error handling is implemented on both frontend and backend
- The app supports both development and production environments

## 🤝 Contributing

1. Make changes to the backend in the `backend/` directory
2. Make changes to the frontend in the `lib/` directory
3. Test both frontend and backend integration
4. Update documentation as needed

## 📄 License

This project is licensed under the MIT License.