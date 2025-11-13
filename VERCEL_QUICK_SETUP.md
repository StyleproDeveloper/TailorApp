# ⚡ Vercel Quick Setup Reference

## 🎨 FRONTEND PROJECT

**Import from GitHub:** `StyleproDeveloper/TailorApp`

**Settings:**
- **Framework Preset:** `Other`
- **Root Directory:** `./` (or leave empty)
- **Build Command:** `chmod +x build.sh && bash build.sh`
- **Output Directory:** `build/web`
- **Install Command:** `echo 'Install handled in build script'`

**Environment Variables:** None required

---

## 🔧 BACKEND PROJECT

**Import from GitHub:** `StyleproDeveloper/TailorApp` (same repo)

**Settings:**
- **Framework Preset:** `Other`
- **Root Directory:** `./backend` ⚠️ **CRITICAL - MUST SET THIS**
- **Build Command:** `npm install` (or leave empty - auto-detected)
- **Output Directory:** (leave empty)

**Environment Variables (Required):**
```
MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/dbname
NODE_ENV=production
JWT_SECRET=your-random-secret-key-here
PORT=5500
```

---

## ✅ Quick Checklist

- [ ] Frontend: Root = `./`
- [ ] Frontend: Build = `chmod +x build.sh && bash build.sh`
- [ ] Frontend: Output = `build/web`
- [ ] Backend: Root = `./backend` ⚠️
- [ ] Backend: MONGO_URL set
- [ ] Backend: NODE_ENV=production
- [ ] Backend: JWT_SECRET set
- [ ] Both projects deployed

---

## 🚨 Most Common Mistake

**Forgetting to set Root Directory to `./backend` for the backend project!**

This will cause 404 errors because Vercel won't find `api/index.js`.

---

For detailed instructions, see: `VERCEL_SETUP_COMPLETE.md`

