# Kimai Cloud Deployment

This repository contains configuration files for deploying Kimai time tracking application to various cloud platforms.

## 🚀 Deployment Options

### 1. Render.com (Recommended - Free)
- Free PostgreSQL database included
- Easy GitHub integration
- Automatic deployments

**Steps:**
1. Fork this repository to your GitHub account
2. Go to [render.com](https://render.com) and sign up
3. Connect your GitHub account
4. Create a new web service from this repository
5. Render will automatically detect the `render.yaml` configuration

### 2. Local Development (Docker)
```bash
docker compose up -d
```
Access at: http://localhost:8080
- Username: admin
- Password: admin123

### 3. Railway.app (Requires subscription)
```bash
railway up
```

### 4. Fly.io (Requires some configuration)
```bash
flyctl deploy
```

## 📋 Environment Variables Needed

- `DATABASE_URL` - Database connection string
- `APP_SECRET` - Application secret key
- `TRUSTED_HOSTS` - Allowed hostnames
- `APP_ENV` - Environment (prod/dev)

## 🎯 Post-Deployment Steps

1. Visit your deployed URL
2. Create admin user if not automatically created
3. Configure your projects and clients
4. Start tracking time!

## 📊 Features

- ✅ Time tracking
- ✅ Project management  
- ✅ Client management
- ✅ Reporting & analytics
- ✅ Invoice generation
- ✅ REST API
- ✅ Multi-language support

## 🔧 Troubleshooting

If the deployment fails:
1. Check if database is properly connected
2. Verify environment variables are set
3. Check application logs
4. Ensure proper port configuration (8001)

For more help, visit [Kimai Documentation](https://www.kimai.org/documentation/)
