# Mare Synchronos API

A .NET 8 API for Final Fantasy XIV character data synchronization.

## Quick Start

### Prerequisites
- .NET 8 SDK
- Docker (optional)

### Local Development

1. **Clone and navigate to the project:**
   ```bash
   cd api-main/api-main/MareSynchronosAPI
   ```

2. **Build and run:**
   ```bash
   dotnet build
   dotnet run
   ```

3. **Access the API:**
   - HTTP: http://localhost:5000
   - HTTPS: https://localhost:5001

### Docker Deployment

1. **Build and run with Docker:**
   ```bash
   docker build -t maresynchronos-api .
   docker run -p 5000:80 -p 5001:443 maresynchronos-api
   ```

2. **Or use Docker Compose:**
   ```bash
   docker-compose up -d
   ```

## Deployment Options

### 1. Local Development Server
- **Best for:** Testing with a few users
- **Setup:** Run `dotnet run` locally
- **Access:** Only available when your machine is running

### 2. Cloud Hosting (Recommended)

#### Azure App Service
```bash
# Install Azure CLI
az login
az webapp up --name your-app-name --resource-group your-rg --runtime "DOTNETCORE:8.0"
```

#### AWS Elastic Beanstalk
```bash
# Install AWS CLI and EB CLI
eb init
eb create
eb deploy
```

#### Railway/Render/Heroku
- Connect your GitHub repository
- Deploy automatically on push

### 3. Self-Hosted VPS
```bash
# On your VPS
sudo apt update
sudo apt install dotnet-sdk-8.0
git clone <your-repo>
cd MareSynchronosAPI
dotnet publish -c Release
dotnet ./bin/Release/net8.0/publish/MareSynchronos.API.dll
```

## Configuration

### Environment Variables
- `ASPNETCORE_ENVIRONMENT`: Set to `Production` for production
- `ASPNETCORE_URLS`: Configure binding URLs
- `ConnectionStrings__DefaultConnection`: Database connection string (if using database)

### Port Configuration
- Default HTTP: 5000
- Default HTTPS: 5001
- SignalR Hub: `/mare`

## Security Considerations

1. **HTTPS**: Always use HTTPS in production
2. **CORS**: Configure CORS policies for your domain
3. **Authentication**: Implement proper authentication for production use
4. **Rate Limiting**: Consider adding rate limiting for public APIs

## Monitoring

- Health checks available at `/health`
- Logs are output to console by default
- Consider adding Application Insights or similar for production monitoring

## Scaling

For small user groups (< 100 users):
- Single instance deployment is sufficient
- Consider load balancing for larger deployments
- Monitor memory and CPU usage

## Support

This is a modified version of Mare Synchronos API. For original project information, see the Mare Synchronos community.
