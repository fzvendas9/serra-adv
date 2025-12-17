# LegalTech SaaS - CRM Jurídico Enterprise

## 🎯 Visão Geral

Sistema CRM Jurídico SaaS Enterprise de nível profissional, altamente escalável e seguro, voltado para escritórios de advocacia de médio e grande porte. 

**Status**: 🚀 Prototipo arquitetural completo (Backend base + estrutura Frontend)

## 🏗️ Arquitetura

### Backend - C# .NET 8
- **Clean Architecture**: Domain → Application → Infrastructure → API
- **Multi-Tenancy**: Isolamento lógico com middleware obrigatório
- **CQRS**: Aplicado em casos complexos
- **JWT + Refresh Token**: Autenticação segura
- **PostgreSQL**: Banco de dados robusto

### Frontend - React
- **Componentes Reutilizáveis**: Material-UI ou Tailwind CSS
- **Drag & Drop**: Suporte completo para movimentação de cartões
- **Dashboard Executivo**: Métricas em tempo real
- **UX Premium**: Interface moderna e responsiva

## 📁 Estrutura de Pastas

```
LegalTech.SaaS/
├── backend/
│   ├── LegalTech.Domain/          # Entidades de domínio
│   │   └── Entities/
│   │       ├── BaseEntity.cs
│   │       ├── Tenant.cs
│   │       ├── User.cs
│   │       ├── Board.cs
│   │       ├── Card.cs
│   │       ├── LegalCase.cs
│   │       ├── Client.cs
│   │       ├── Document.cs
│   │       └── ... (mais entidades)
│   │
│   ├── LegalTech.Application/     # Lógica de aplicação
│   │   ├── DTOs/
│   │   ├── Interfaces/
│   │   ├── Services/
│   │   └── MediatR/
│   │
│   ├── LegalTech.Infrastructure/  # Acesso a dados e serviços
│   │   ├── Data/
│   │   │   └── AppDbContext.cs
│   │   ├── Security/
│   │   │   ├── PasswordHashService.cs
│   │   │   └── JwtTokenService.cs
│   │   └── Repositories/
│   │
│   └── LegalTech.API/             # Apresentação
│       ├── Controllers/
│       │   ├── AuthController.cs
│       │   ├── BoardsController.cs
│       │   ├── CardsController.cs
│       │   ├── CasesController.cs
│       │   ├── ClientsController.cs
│       │   ├── DocumentsController.cs
│       │   └── DashboardController.cs
│       ├── Middleware/
│       │   └── TenantMiddleware.cs
│       ├── Program.cs
│       └── appsettings.json
│
└── frontend/
    └── legaltech-web/             # React App
        ├── public/
        ├── src/
        │   ├── components/
        │   ├── pages/
        │   ├── services/
        │   ├── hooks/
        │   ├── types/
        │   └── App.tsx
        ├── package.json
        └── tsconfig.json
```

## 🔐 Segurança & Autenticação

### JWT com Multi-Tenancy
```
Token JWT contém:
- userId (NameIdentifier)
- email (Email)
- role (Role)
- tenantId (Custom Claim - OBRIGATÓRIO)
```

### TenantMiddleware
- Extrai `tenantId` do JWT automaticamente
- Isola todas as queries por tenant
- Impede acesso cruzado de dados

### RBAC (Role-Based Access Control)
- **SuperAdmin**: Gerencia todos os escritórios
- **Admin**: Gerencia seu escritório
- **Advogado**: Gerencia seus processos
- **Assistente**: Acesso limitado

## 📊 Modelos de Dados Principais

### Tenant
```csharp
- Id (Guid)
- Name, Slug, Logo
- PlanType (Trial, Basic, Professional, Enterprise)
- MaxUsers, MaxStorageMB, MaxProcesses
- IsActive, PlanExpiresAt
```

### User
```csharp
- Id, Email, FullName, PasswordHash
- Role (SuperAdmin, Admin, Advogado, Assistente)
- MFAEnabled, LastLoginAt
- TenantId (Multi-Tenancy)
```

### Board (Quadro)
```csharp
- Id, Title, Type, Color
- Lists (Listas dentro do quadro)
- Members (Acesso e permissões)
- Templates (Reutilizáveis)
```

### Card (Cartão = Processo Jurídico)
```csharp
- Id, Title, Description, Priority
- Status, DueDate, LegalDeadline
- SLAExpiresAt, SLABreached
- Checklists, Comments, History, Attachments
- ScheduledEvents (Agenda)
```

### LegalCase
```csharp
- Id, CaseNumber, Title, LegalArea
- ClientId, PrimaryLawyerId
- Status, OpenedDate, ClosedDate
- NextHearingDate, Documents, Timeline
```

### Document
```csharp
- Id, FileName, FileUrl, Version
- Versionamento automático
- AccessLogs (Auditoria de acesso)
```

## 🔌 API REST Endpoints

### Autenticação
```
POST   /api/auth/login              # Login
POST   /api/auth/register           # Registrar
POST   /api/auth/refresh            # Renovar token
POST   /api/auth/validate           # Validar token
```

### Quadros (Boards)
```
GET    /api/boards                  # Listar quadros
GET    /api/boards/{id}             # Obter quadro
POST   /api/boards                  # Criar quadro
PUT    /api/boards/{id}             # Atualizar quadro
DELETE /api/boards/{id}             # Deletar quadro
```

### Cartões (Cards)
```
GET    /api/cards/{id}              # Obter cartão
GET    /api/cards/board/{boardId}   # Listar por quadro
POST   /api/cards                   # Criar cartão
PUT    /api/cards/{id}              # Atualizar cartão
DELETE /api/cards/{id}              # Deletar cartão
POST   /api/cards/{id}/move         # Mover cartão (Drag & Drop)
```

### Casos Jurídicos
```
GET    /api/cases                   # Listar casos
GET    /api/cases/{id}              # Obter caso
POST   /api/cases                   # Criar caso
PUT    /api/cases/{id}              # Atualizar caso
DELETE /api/cases/{id}              # Deletar caso
GET    /api/cases/client/{clientId} # Casos por cliente
```

### Clientes
```
GET    /api/clients                 # Listar clientes
GET    /api/clients/{id}            # Obter cliente
POST   /api/clients                 # Criar cliente
PUT    /api/clients/{id}            # Atualizar cliente
DELETE /api/clients/{id}            # Deletar cliente
GET    /api/clients/search/document/{doc} # Buscar por CPF/CNPJ
```

### Documentos
```
GET    /api/documents               # Listar documentos
GET    /api/documents/{id}          # Obter documento
POST   /api/documents/upload        # Upload
GET    /api/documents/{id}/download # Download
DELETE /api/documents/{id}          # Deletar
GET    /api/documents/case/{caseId} # Documentos por caso
POST   /api/documents/{id}/versions # Versionamento
```

### Dashboard
```
GET    /api/dashboard/metrics                # Métricas gerais
GET    /api/dashboard/cases-by-status        # Casos por status
GET    /api/dashboard/critical-deadlines     # Prazos críticos
GET    /api/dashboard/lawyer-performance     # Performance advogados
GET    /api/dashboard/team-productivity      # Produtividade equipe
GET    /api/dashboard/sla-breached           # SLA violado
```

## 🚀 Como Iniciar

### Pré-requisitos
- .NET 8 SDK
- PostgreSQL 14+
- Node.js 18+
- npm ou yarn

### Backend Setup

1. **Restaurar pacotes NuGet**
```bash
cd backend/LegalTech.API
dotnet restore
```

2. **Configurar appsettings.Development.json**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=LegalTechDb_Dev;User Id=postgres;Password=postgres;"
  }
}
```

3. **Executar migrations**
```bash
dotnet ef database update
```

4. **Executar aplicação**
```bash
dotnet run
```

A API estará disponível em `https://localhost:5001`
Swagger UI em `https://localhost:5001/swagger`

### Frontend Setup

1. **Instalar dependências**
```bash
cd frontend/legaltech-web
npm install
```

2. **Variáveis de ambiente (.env)**
```
REACT_APP_API_URL=https://localhost:5001
```

3. **Executar desenvolvimento**
```bash
npm start
```

## 📋 Recursos Implementados

### ✅ Backend
- [x] Estrutura de Clean Architecture
- [x] Multi-Tenancy com middleware
- [x] JWT Authentication
- [x] RBAC completo
- [x] Entidades de domínio
- [x] DbContext com PostgreSQL
- [x] Controllers principais
- [x] DTOs padronizados
- [x] Swagger documentation

### 🔄 Em Desenvolvimento
- [ ] Services (Application layer)
- [ ] Repositories (Data access)
- [ ] Unit of Work pattern
- [ ] MediatR (CQRS)
- [ ] AutoMapper (DTO mapping)
- [ ] Validação (FluentValidation)
- [ ] Migrations do EF Core
- [ ] Seed data

### ⏳ Frontend
- [ ] Configuração React + TypeScript
- [ ] Componentes reutilizáveis
- [ ] Páginas principais
- [ ] Dashboard
- [ ] Boards com Drag & Drop
- [ ] Autenticação
- [ ] Integração com API

## 💳 Planos SaaS

### Trial (14 dias)
- 5 usuários
- 1 GB armazenamento
- 100 processos
- Acesso total aos recursos

### Básico ($99/mês)
- 5 usuários
- 1 GB armazenamento
- 100 processos

### Profissional ($299/mês)
- 25 usuários
- 10 GB armazenamento
- 1000 processos

### Enterprise (Custom)
- Usuários ilimitados
- Armazenamento ilimitado
- Processos ilimitados
- SLA 99.9%
- Suporte dedicado

## 🔒 Conformidade

- ✅ LGPD (Lei Geral de Proteção de Dados)
- ✅ Logs de auditoria imutáveis
- ✅ Criptografia de dados sensíveis
- ✅ Backup automático
- ✅ MFA opcional
- ✅ Controle de sessão

## 📚 Documentação

### Autenticação JWT
```bash
# Login
curl -X POST https://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"usuario@example.com","password":"senha"}'

# Resposta
{
  "access_token": "eyJhbGc...",
  "refresh_token": "base64...",
  "expires_in": 3600,
  "user": {...},
  "tenant": {...}
}

# Usar token
curl -X GET https://localhost:5001/api/boards \
  -H "Authorization: Bearer eyJhbGc..."
```

## 🛠️ Próximos Passos

1. **Services Implementation**
   - AuthenticationService
   - BoardService
   - CardService
   - CaseService
   - DocumentService

2. **Repositories**
   - Generic Repository Pattern
   - Unit of Work

3. **Advanced Features**
   - Real-time WebSocket (SignalR)
   - Notificações
   - Relatórios PDF
   - Integração com APIs externas

4. **Frontend React**
   - Componentes completos
   - State management (Redux/Zustand)
   - Autenticação
   - Integração com API

5. **DevOps**
   - Docker containerization
   - CI/CD pipeline
   - Deployment automático
   - Monitoramento e logs

## 📞 Suporte

Para dúvidas ou sugestões, abra uma issue no repositório.

## 📄 Licença

Propriedade exclusiva - LegalTech SaaS

---

**Desenvolvido com ❤️ para advogados profissionais**
