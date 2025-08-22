# Mare Synchronos API - Deployment Guide

This guide will help you deploy the Mare Synchronos API to a small subset of users.

## What is Mare Synchronos?

Mare Synchronos is a Final Fantasy XIV mod synchronization service that allows players to share character data, mods, and poses with other players in real-time. This API provides the backend services for the synchronization functionality.

## Prerequisites

- .NET 8 SDK installed on your machine
- Git (for version control)
- Docker (optional, for containerized deployment)

## Quick Start - Local Development

### 1. Build and Run Locally

```bash
# Navigate to the project directory
cd api-main/api-main/MareSynchronosAPI

# Build the project
dotnet build

# Run the API
dotnet run
```

The API will be available at:
- HTTP: http://localhost:5000
- HTTPS: https://localhost:5001
- SignalR Hub: http://localhost:5000/mare

### 2. Test the API

You can test the API using curl or a tool like Postman:

```bash
# Test the health endpoint
curl http://localhost:5000/health

# Test SignalR connection (requires a SignalR client)
```

## Deployment Options for Small User Groups

### Option 1: Local Network Deployment (Easiest)

**Best for:** 5-10 users on the same network

1. **Run on your local machine:**
   ```bash
   dotnet run --urls "http://0.0.0.0:5000;https://0.0.0.0:5001"
   ```

2. **Configure firewall:**
   - Allow incoming connections on ports 5000 and 5001
   - Share your local IP address with users

3. **Users connect to:** `http://YOUR_LOCAL_IP:5000`

**Pros:** Free, simple setup
**Cons:** Only works when your machine is running, limited to local network

### Option 2: Cloud Hosting (Recommended)

#### A. Azure App Service (Microsoft)

1. **Install Azure CLI:**
   ```bash
   # Windows
   winget install Microsoft.AzureCLI
   
   # macOS
   brew install azure-cli
   ```

2. **Login and deploy:**
   ```bash
   az login
   az group create --name mare-sync-rg --location eastus
   az appservice plan create --name mare-sync-plan --resource-group mare-sync-rg --sku B1
   az webapp create --name your-mare-api --resource-group mare-sync-rg --plan mare-sync-plan --runtime "DOTNETCORE:8.0"
   az webapp deployment source config-local-git --name your-mare-api --resource-group mare-sync-rg
   ```

3. **Deploy your code:**
   ```bash
   git remote add azure <azure-git-url>
   git push azure main
   ```

**Cost:** ~$13/month for B1 tier (suitable for small groups)

#### B. Railway (Simple)

1. **Sign up at railway.app**
2. **Connect your GitHub repository**
3. **Deploy automatically on push**

**Cost:** Free tier available, then $5/month

#### C. Render (Simple)

1. **Sign up at render.com**
2. **Create a new Web Service**
3. **Connect your GitHub repository**
4. **Set build command:** `dotnet publish -c Release -o out`
5. **Set start command:** `dotnet out/MareSynchronos.API.dll`

**Cost:** Free tier available, then $7/month

### Option 3: Self-Hosted VPS

#### A. DigitalOcean Droplet

1. **Create a droplet:**
   - Choose Ubuntu 22.04
   - Select Basic plan ($6/month)
   - Choose a datacenter close to your users

2. **Install .NET 8:**
   ```bash
   wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
   sudo dpkg -i packages-microsoft-prod.deb
   sudo apt-get update
   sudo apt-get install -y dotnet-sdk-8.0
   ```

3. **Deploy your application:**
   ```bash
   git clone <your-repo>
   cd MareSynchronosAPI
   dotnet publish -c Release -o /var/www/mare-api
   ```

4. **Create a systemd service:**
   ```bash
   sudo nano /etc/systemd/system/mare-api.service
   ```

   Add this content:
   ```ini
   [Unit]
   Description=Mare Synchronos API
   After=network.target

   [Service]
   WorkingDirectory=/var/www/mare-api
   ExecStart=/usr/bin/dotnet /var/www/mare-api/MareSynchronos.API.dll
   Restart=always
   RestartSec=10
   User=www-data
   Environment=ASPNETCORE_ENVIRONMENT=Production
   Environment=ASPNETCORE_URLS=http://localhost:5000

   [Install]
   WantedBy=multi-user.target
   ```

5. **Start the service:**
   ```bash
   sudo systemctl enable mare-api
   sudo systemctl start mare-api
   ```

6. **Configure Nginx (optional):**
   ```bash
   sudo apt install nginx
   sudo nano /etc/nginx/sites-available/mare-api
   ```

   Add this configuration:
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

       location / {
           proxy_pass http://localhost:5000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection keep-alive;
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

   Enable the site:
   ```bash
   sudo ln -s /etc/nginx/sites-available/mare-api /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

**Cost:** $6-12/month depending on droplet size

## Docker Deployment

### Using Docker Compose

1. **Build and run:**
   ```bash
   docker-compose up -d
   ```

2. **Access the API:**
   - HTTP: http://localhost:5000
   - HTTPS: http://localhost:5001

### Using Docker directly

1. **Build the image:**
   ```bash
   docker build -t maresynchronos-api .
   ```

2. **Run the container:**
   ```bash
   docker run -d -p 5000:80 -p 5001:443 --name mare-api maresynchronos-api
   ```

## Configuration

### Environment Variables

Create a `appsettings.Production.json` file:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:5000"
      },
      "Https": {
        "Url": "https://0.0.0.0:5001"
      }
    }
  }
}
```

### CORS Configuration

For production, update the CORS policy in `Program.cs`:

```csharp
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("https://yourdomain.com", "http://localhost:3000")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});
```

## Security Considerations

### 1. HTTPS in Production

Always use HTTPS in production. You can get free SSL certificates from Let's Encrypt:

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d yourdomain.com
```

### 2. Authentication

Consider implementing authentication for your API:

```csharp
// Add to Program.cs
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = "your-issuer",
            ValidAudience = "your-audience",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes("your-secret-key"))
        };
    });
```

### 3. Rate Limiting

Add rate limiting to prevent abuse:

```bash
dotnet add package Microsoft.AspNetCore.RateLimiting
```

```csharp
// Add to Program.cs
builder.Services.AddRateLimiter(options =>
{
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: context.User.Identity?.Name ?? context.Request.Headers.Host.ToString(),
            factory: partition => new FixedWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1)
            }));
});
```

## Monitoring and Logging

### 1. Application Insights (Azure)

```bash
dotnet add package Microsoft.ApplicationInsights.AspNetCore
```

### 2. Health Checks

```csharp
// Add to Program.cs
builder.Services.AddHealthChecks();

// Add to app configuration
app.MapHealthChecks("/health");
```

### 3. Logging

Configure structured logging:

```csharp
// Add to Program.cs
builder.Services.AddLogging(logging =>
{
    logging.AddConsole();
    logging.AddDebug();
    logging.AddEventLog();
});
```

## Scaling Considerations

### For Small Groups (< 50 users):
- Single instance deployment is sufficient
- Monitor CPU and memory usage
- Consider upgrading if usage increases

### For Medium Groups (50-200 users):
- Consider load balancing
- Implement caching (Redis)
- Monitor database performance

### For Large Groups (200+ users):
- Multiple instances behind a load balancer
- Database clustering
- CDN for static content

## Troubleshooting

### Common Issues:

1. **Port already in use:**
   ```bash
   # Find process using port
   netstat -ano | findstr :5000
   
   # Kill process
   taskkill /PID <process-id> /F
   ```

2. **Permission denied:**
   ```bash
   # On Linux/Mac
   sudo chown -R $USER:$USER /var/www/mare-api
   ```

3. **SSL certificate issues:**
   ```bash
   # Trust development certificate
   dotnet dev-certs https --trust
   ```

### Logs:

```bash
# View application logs
dotnet run --environment Production

# View systemd logs (Linux)
sudo journalctl -u mare-api -f

# View Docker logs
docker logs mare-api
```

## Support and Maintenance

### Regular Maintenance:

1. **Update dependencies:**
   ```bash
   dotnet list package --outdated
   dotnet add package <package-name> --version <new-version>
   ```

2. **Backup data:**
   - Regular backups of any persistent data
   - Version control for configuration

3. **Monitor performance:**
   - CPU and memory usage
   - Response times
   - Error rates

### Getting Help:

- Check the original Mare Synchronos documentation
- Review .NET 8 documentation
- Monitor application logs for errors

## Cost Summary

| Deployment Option | Monthly Cost | Setup Complexity | Maintenance |
|------------------|--------------|------------------|-------------|
| Local Network | $0 | Low | Low |
| Railway/Render | $5-7 | Very Low | Low |
| Azure App Service | $13+ | Medium | Low |
| DigitalOcean VPS | $6-12 | High | Medium |
| AWS/GCP | $20+ | High | Medium |

Choose based on your technical expertise, budget, and user requirements.
