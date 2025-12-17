# HOSPEDAGEM

## Ambiente de Produção

### Pré-requisitos

- **.NET 10 Runtime** (ou .NET 8.0 LTS)
- **PostgreSQL 14+**
- **Docker & Docker Compose** (opcional, para containerização)
- **Node.js 18+** (para frontend)

### Deploy Local

#### Backend

```bash
cd backend/LegalTech.API
dotnet publish -c Release -o ./publish
cd publish
dotnet LegalTech.API.dll
```

Será acessível em: `https://localhost:5001`

#### Frontend

```bash
cd frontend/legaltech-web
npm run build
# Servir com nginx ou outro servidor
npm run preview
```

### Deploy com Docker Compose

```bash
docker-compose up -d
```

**Serviços iniciados:**
- **PostgreSQL**: Port 5432
- **API**: Port 5000
- **Frontend**: Port 3000

### Configurações de Produção

#### Variáveis de Ambiente (Backend)

```bash
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=https://+:443;http://+:80
ASPNETCORE_Kestrel__Certificates__Default__Path=/etc/legaltech/certs/cert.pfx
ASPNETCORE_Kestrel__Certificates__Default__Password=YourPassword
ConnectionStrings__DefaultConnection=Server=db-host;Database=legaltech;User Id=admin;Password=secure_password;
JwtSettings__Secret=VeryLongSecureKeyMinimum32CharactersHere!
```

#### SSL/TLS

Gere certificados:
```bash
dotnet dev-certs https --export-path ./cert.pfx --password password123
```

Ou use Let's Encrypt com Certbot:
```bash
certbot certonly --standalone -d seu-dominio.com
```

### Health Check

```bash
curl https://localhost:5001/health
```

### Logs

```bash
# Backend
tail -f ~/.aspnet/dataProtection.log

# Frontend
docker logs legaltech-frontend

# Database
docker logs legaltech-postgres
```

### Backup Database

```bash
# Fazer backup
pg_dump -h localhost -U admin -d legaltech > backup_$(date +%Y%m%d).sql

# Restaurar
psql -h localhost -U admin -d legaltech < backup_20250101.sql
```

### Performance

1. **Enable Response Caching** (appsettings.json):
```json
"ResponseCaching": {
  "MaxSize": 104857600
}
```

2. **Database Optimization**:
```sql
VACUUM ANALYZE;
CREATE INDEX idx_tenant_id ON audit_logs(tenant_id);
CREATE INDEX idx_created_at ON cards(created_at DESC);
```

3. **CDN para Assets Frontend**
4. **Redis para Cache** (futuro)

### Monitoramento

- Logs estruturados com Serilog
- Health checks nos endpoints
- Metrics com Prometheus (futuro)

### Próximas Etapas

1. Implementar migrations EF Core
2. Seedar dados iniciais
3. Configurar CI/CD (GitHub Actions)
4. Setup de monitoramento (New Relic, DataDog)
5. Implementar real-time com SignalR
