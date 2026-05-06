# ============================================================================
# Docker Infrastructure Deployment Script (Windows PowerShell)
# ============================================================================

param(
    [switch]$Build = $false,
    [switch]$Up = $false,
    [switch]$Down = $false,
    [switch]$Status = $false,
    [switch]$Help = $false
)

# Colors for output
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Text)
    Write-Host "✓ $Text" -ForegroundColor Green
}

function Write-Error {
    param([string]$Text)
    Write-Host "✗ $Text" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Text)
    Write-Host "⚠ $Text" -ForegroundColor Yellow
}

function Show-Help {
    Write-Host @"
Docker Infrastructure Deployment Script

Usage: .\deploy.ps1 [options]

Options:
  -Build          Build Docker images
  -Up             Start all services
  -Down           Stop all services
  -Status         Show service status
  -Help           Show this help message

Examples:
  .\deploy.ps1 -Build -Up        # Build and start all services
  .\deploy.ps1 -Status            # Check service status
  .\deploy.ps1 -Down              # Stop all services

"@
}

# Main logic
if ($Help) {
    Show-Help
    exit 0
}

# Check if .env exists
if (-Not (Test-Path ".env")) {
    Write-Error ".env file not found!"
    if (Test-Path ".env.example") {
        Write-Host "Creating .env from .env.example..."
        Copy-Item ".env.example" ".env"
        Write-Warning "Please edit .env and fill in your values, then run the script again."
    }
    exit 1
}

Write-Header "Docker Infrastructure Deployment"
Write-Success ".env file found"

# Check Docker
try {
    $dockerVersion = docker --version
    Write-Success "Docker is installed: $dockerVersion"
} catch {
    Write-Error "Docker is not installed!"
    exit 1
}

# Build images
if ($Build) {
    Write-Header "Building Docker Images"
    docker-compose build
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Images built successfully"
    } else {
        Write-Error "Failed to build images"
        exit 1
    }
}

# Start services
if ($Up) {
    Write-Header "Starting Services"
    docker-compose up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Services started"
        Write-Host "Waiting 15 seconds for services to initialize..."
        Start-Sleep -Seconds 15
    } else {
        Write-Error "Failed to start services"
        exit 1
    }
}

# Stop services
if ($Down) {
    Write-Header "Stopping Services"
    docker-compose down
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Services stopped"
    } else {
        Write-Error "Failed to stop services"
        exit 1
    }
}

# Check status
if ($Status -or $Up) {
    Write-Header "Checking Service Status"
    
    $services = @(
        @{Name="PostgreSQL"; Port="5432"; Container="infrastructure-postgres"; Check={docker exec infrastructure-postgres pg_isready -U forge *> $null}},
        @{Name="Redis"; Port="6379"; Container="infrastructure-redis"; Check={docker exec infrastructure-redis redis-cli ping *> $null}},
        @{Name="MinIO API"; Port="9000"; Container="infrastructure-minio"; Check={$null}},
        @{Name="MinIO Console"; Port="9001"; Container="infrastructure-minio"; Check={$null}},
        @{Name="Centrifugo"; Port="8000"; Container="infrastructure-centrifugo"; Check={$null}},
        @{Name="PgAdmin"; Port="5050"; Container="infrastructure-pgadmin"; Check={$null}},
        @{Name="Nginx"; Port="80"; Container="infrastructure-nginx"; Check={$null}}
    )
    
    foreach ($service in $services) {
        try {
            $result = docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String $service.Container
            if ($result) {
                Write-Success "$($service.Name) is running (Port: $($service.Port))"
            } else {
                Write-Error "$($service.Name) is not running"
            }
        } catch {
            Write-Error "Failed to check $($service.Name)"
        }
    }
    
    Write-Header "Quick Links"
    Write-Host "PostgreSQL:     localhost:5432" -ForegroundColor White
    Write-Host "Redis:          localhost:6379" -ForegroundColor White
    Write-Host "MinIO API:      localhost:9000" -ForegroundColor White
    Write-Host "MinIO Console:  localhost:9001" -ForegroundColor White
    Write-Host "Centrifugo:     localhost:8000" -ForegroundColor White
    Write-Host "PgAdmin:        localhost:5050" -ForegroundColor White
    Write-Host "Nginx:          localhost:80" -ForegroundColor White
    Write-Host ""
}

# Default action if no options
if (-Not ($Build -or $Up -or $Down -or $Status)) {
    Write-Host "No action specified. Use -Help to see available options."
    Write-Host ""
    Write-Host "Quick start:" -ForegroundColor Yellow
    Write-Host "  .\deploy.ps1 -Build -Up     # Build and start all services"
    Write-Host "  .\deploy.ps1 -Status         # Check service status"
    Write-Host "  .\deploy.ps1 -Help           # Show help"
}
