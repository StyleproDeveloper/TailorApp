# 🔗 How Frontend and Backend Connect (Separate Vercel Projects)

## Overview

Even though the frontend and backend are deployed as **separate projects** in Vercel, they connect via **HTTP requests** over the internet. The frontend is a **client** that makes API calls to the backend **server**.

---

## 🔄 Connection Flow

```
┌─────────────────┐                    ┌─────────────────┐
│   Frontend      │                    │    Backend      │
│   (Vercel)      │                    │   (Vercel)      │
│                 │                    │                 │
│  Flutter Web    │  HTTP Requests     │  Node.js API    │
│  Application    │ ──────────────────>│  (Express)      │
│                 │                    │                 │
│  URL:           │                    │  URL:           │
│  tailorapp-     │                    │  backend-       │
│  xxx.vercel.app │                    │  xxx.vercel.app │
└─────────────────┘                    └─────────────────┘
         │                                       │
         │                                       │
         └─────────── Internet ───────────────────┘
```

---

## 📍 How It Works

### 1. **Frontend Auto-Detection** (`lib/Core/Services/Urls.dart`)

The frontend automatically detects which backend to use:

```dart
static String get baseUrl {
  // Check if running on localhost
  if (hostname == 'localhost' || hostname == '127.0.0.1') {
    return 'http://localhost:5500';  // Local backend
  }
  
  // Otherwise, use production backend
  return 'https://backend-6gm15jzh9-stylepros-projects.vercel.app';
}
```

**How it works:**
- When you visit the frontend URL (e.g., `https://tailorapp-xxx.vercel.app`)
- The code checks the hostname
- If it's NOT localhost → uses production backend URL
- If it IS localhost → uses local backend (`http://localhost:5500`)

### 2. **API Service** (`lib/Core/Services/Services.dart`)

The `ApiService` class uses the `baseUrl` to make HTTP requests:

```dart
class ApiService {
  final String baseUrl = Urls.baseUrl;  // Gets backend URL
  
  ApiService() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,  // Sets base URL for all requests
      // ...
    );
  }
}
```

### 3. **Making API Calls**

When the frontend needs data, it makes HTTP requests:

```dart
// Example: Login request
final response = await ApiService().post(
  Urls.login,  // '/auth/login'
  context,
  data: {'mobileNumber': '1234567890'}
);

// This becomes: 
// POST https://backend-xxx.vercel.app/auth/login
```

---

## 🔧 Configuration Steps

### Step 1: Deploy Backend First

1. Create backend project in Vercel
2. Set root directory: `./backend`
3. Set environment variables (MONGO_URL, etc.)
4. Deploy and note the URL: `https://backend-xxx.vercel.app`

### Step 2: Update Frontend Code

Update `lib/Core/Services/Urls.dart` with your backend URL:

```dart
// Line 23: Update this URL
final url = 'https://backend-xxx.vercel.app';  // Your backend URL
```

### Step 3: Deploy Frontend

1. Create frontend project in Vercel
2. Set root directory: `./` (root)
3. Deploy
4. Frontend will automatically use the backend URL you configured

---

## 🌐 Example Request Flow

### User Login Flow:

1. **User enters phone number** in frontend
2. **Frontend makes POST request:**
   ```
   POST https://backend-xxx.vercel.app/auth/login
   Body: {"mobileNumber": "1234567890"}
   ```

3. **Backend processes request:**
   - Validates phone number
   - Generates OTP
   - Saves to database
   - Returns response

4. **Frontend receives response:**
   ```json
   {
     "success": true,
     "message": "OTP sent successfully"
   }
   ```

5. **Frontend shows success message** to user

---

## 🔐 CORS Configuration

Since frontend and backend are on **different domains**, CORS must be configured:

### Backend (`backend/vercel.json`):
```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Access-Control-Allow-Origin",
          "value": "*"
        }
      ]
    }
  ]
}
```

This allows the frontend (different domain) to make requests to the backend.

---

## 📝 Important Points

### ✅ **They are NOT physically connected:**
- Frontend and backend are separate applications
- They communicate via HTTP/HTTPS over the internet
- No shared code or files between them

### ✅ **Backend URL is hardcoded in frontend:**
- The frontend code contains the backend URL
- When you deploy a new backend, update the URL in frontend code
- Then redeploy the frontend

### ✅ **Both can be updated independently:**
- Update backend → Frontend still works (same URL)
- Update frontend → Still connects to same backend
- Change backend URL → Must update frontend code

### ✅ **Environment-based detection:**
- **Localhost:** Frontend → `http://localhost:5500` (local backend)
- **Production:** Frontend → `https://backend-xxx.vercel.app` (Vercel backend)

---

## 🔄 Updating Backend URL

If your backend URL changes (new deployment):

1. **Update `lib/Core/Services/Urls.dart`:**
   ```dart
   final url = 'https://new-backend-url.vercel.app';
   ```

2. **Commit and push:**
   ```bash
   git add lib/Core/Services/Urls.dart
   git commit -m "Update backend URL"
   git push
   ```

3. **Frontend auto-redeploys** (if auto-deploy is enabled)

---

## 🧪 Testing the Connection

### Test Backend:
```bash
curl https://backend-xxx.vercel.app/
# Should return: {"success":true,"status":200,...}
```

### Test from Frontend:
1. Open browser console on frontend
2. Look for: `✅ Using PRODUCTION backend: https://...`
3. Try to login - check network tab for API calls

---

## 🚨 Common Issues

### Issue: CORS Errors
**Solution:** Backend must have CORS headers configured (already done in `backend/vercel.json`)

### Issue: 404 Errors
**Solution:** Check backend URL is correct in `Urls.dart`

### Issue: Connection Refused
**Solution:** 
- Verify backend is deployed and running
- Check backend URL is accessible
- Verify environment variables are set

---

## 📊 Summary

| Aspect | Frontend | Backend |
|--------|----------|---------|
| **Deployment** | Separate Vercel project | Separate Vercel project |
| **URL** | `tailorapp-xxx.vercel.app` | `backend-xxx.vercel.app` |
| **Connection** | Makes HTTP requests | Receives HTTP requests |
| **Configuration** | Backend URL in code | CORS headers in config |
| **Update** | Update URL in code | Update CORS if needed |

**Key Point:** They're connected via **HTTP requests**, not by being in the same project!


