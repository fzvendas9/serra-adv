# GUIA TÉCNICO - LegalTech SaaS

## 📋 Índice
1. [Arquitetura](#arquitetura)
2. [Multi-Tenancy](#multi-tenancy)
3. [Autenticação e Segurança](#autenticação-e-segurança)
4. [Estrutura de Banco de Dados](#estrutura-de-banco-de-dados)
5. [Padrões de Desenvolvimento](#padrões-de-desenvolvimento)
6. [Guia de Implementação](#guia-de-implementação)

## 🏗️ Arquitetura

### Camadas

```
┌─────────────────────────────────────────┐
│         Frontend (React + TypeScript)    │
│  - Components, Pages, Stores, Services  │
└─────────────────┬───────────────────────┘
                  │
                  │ HTTP/REST
                  │
┌─────────────────▼───────────────────────┐
│      API Layer (Controllers)             │
│  - AuthController, BoardsController, etc │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│   Application Layer (Services)           │
│  - Business Logic, CQRS, Validation     │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      Domain Layer (Entities)             │
│  - Business Models, Interfaces           │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│   Infrastructure Layer (Data & Services)│
│  - DbContext, Repositories, Security    │
└─────────────────┬───────────────────────┘
                  │
                  │ SQL
                  │
┌─────────────────▼───────────────────────┐
│         PostgreSQL Database              │
└─────────────────────────────────────────┘
```

### Benefícios
- **Separação de responsabilidades**: Cada camada tem um propósito claro
- **Testabilidade**: Fácil de testar cada camada isoladamente
- **Manutenibilidade**: Código organizado e fácil de entender
- **Escalabilidade**: Estrutura preparada para crescimento

## 🏢 Multi-Tenancy

### Conceito
Cada escritório (Tenant) é totalmente isolado de outro, compartilhando a mesma infraestrutura (SaaS).

### Implementação

#### 1. TenantId em Todas as Tabelas
```csharp
public abstract class BaseEntity
{
    public Guid TenantId { get; set; }  // OBRIGATÓRIO em todas entidades
}
```

#### 2. TenantMiddleware Obrigatório
```csharp
// Extrai TenantId do JWT e isola queries
public class TenantMiddleware
{
    // Aplica SetTenant ao DbContext
    // Impede acesso cruzado de dados
}
```

#### 3. Global Query Filters
```csharp
// DbContext aplica automaticamente:
modelBuilder.Entity<Board>()
    .HasQueryFilter(x => x.TenantId == _tenantId);
```

### Fluxo de Requisição
```
1. Cliente faz request com Authorization header
2. TenantMiddleware extrai tenantId do JWT
3. DbContext.SetTenant(tenantId) é chamado
4. Todas as queries filtram automaticamente por TenantId
5. Resposta contém apenas dados do tenant
```

### Segurança
- ✅ Isolamento lógico automático
- ✅ Impossível acessar dados de outro tenant
- ✅ TenantId vem do JWT (validado)
- ✅ Índices por (TenantId, Campo) para performance

## 🔐 Autenticação e Segurança

### JWT Token Structure
```json
{
  "nameid": "user-uuid",
  "email": "user@example.com",
  "role": "Advogado",
  "TenantId": "tenant-uuid"  // Custom claim para multi-tenancy
}
```

### Fluxo de Autenticação
```
1. POST /api/auth/login
2. Valida email/senha contra PasswordHash
3. Gera AccessToken (1 hora) + RefreshToken (7 dias)
4. Retorna AuthResponse com user + tenant
5. Cliente armazena tokens no localStorage
```

### Refresh Token
```
1. AccessToken expira em 1 hora
2. Cliente envia RefreshToken para renovar
3. API valida RefreshToken (7 dias)
4. Retorna novo AccessToken
5. Se ambos expiram → Login novamente
```

### Password Hashing
```csharp
// PBKDF2 com SHA-256
// 10.000 iterações
// 16 bytes salt + 20 bytes hash
// Formato: iterations.salt.hash
```

## 📊 Estrutura de Banco de Dados

### Tabelas Principais

#### Tenants
```sql
CREATE TABLE Tenants (
    Id UUID PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Slug VARCHAR(255) UNIQUE,
    PlanType VARCHAR(50),
    MaxUsers INT,
    MaxStorageMB BIGINT,
    MaxProcesses INT,
    IsActive BOOLEAN
);
```

#### Users (Multi-Tenant)
```sql
CREATE TABLE Users (
    Id UUID PRIMARY KEY,
    TenantId UUID NOT NULL REFERENCES Tenants(Id),
    Email VARCHAR(255) NOT NULL,
    FullName VARCHAR(255),
    PasswordHash VARCHAR(255),
    Role VARCHAR(50),
    UNIQUE(TenantId, Email)
);
```

#### Boards (Multi-Tenant)
```sql
CREATE TABLE Boards (
    Id UUID PRIMARY KEY,
    TenantId UUID NOT NULL REFERENCES Tenants(Id),
    Title VARCHAR(255),
    Type VARCHAR(50),
    Color VARCHAR(7),
    ClientId UUID
);
```

#### Cards (Processos Jurídicos)
```sql
CREATE TABLE Cards (
    Id UUID PRIMARY KEY,
    TenantId UUID NOT NULL,
    BoardListId UUID NOT NULL,
    CaseId UUID,
    AssignedToUserId UUID,
    Title VARCHAR(255),
    Priority VARCHAR(50),
    Status VARCHAR(50),
    DueDate TIMESTAMP,
    LegalDeadline TIMESTAMP,
    SLAExpiresAt TIMESTAMP,
    SLABreached BOOLEAN
);
```

#### LegalCases
```sql
CREATE TABLE LegalCases (
    Id UUID PRIMARY KEY,
    TenantId UUID NOT NULL,
    CaseNumber VARCHAR(50) UNIQUE,
    Title VARCHAR(255),
    LegalArea VARCHAR(100),
    ClientId UUID,
    Status VARCHAR(50)
);
```

#### Documents
```sql
CREATE TABLE Documents (
    Id UUID PRIMARY KEY,
    TenantId UUID NOT NULL,
    CaseId UUID,
    CardId UUID,
    FileName VARCHAR(255),
    FileUrl VARCHAR(2048),
    Version INT,
    FileSizeBytes BIGINT
);
```

#### AuditLogs (Imutável)
```sql
CREATE TABLE AuditLogs (
    Id UUID PRIMARY KEY,
    TenantId UUID NOT NULL,
    UserId UUID,
    Action VARCHAR(100),
    EntityType VARCHAR(100),
    Details TEXT,
    LoggedAt TIMESTAMP DEFAULT NOW()
);
```

## 🔄 Padrões de Desenvolvimento

### Repository Pattern
```csharp
public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(Guid id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<T> AddAsync(T entity);
    Task<T> UpdateAsync(T entity);
    Task<bool> DeleteAsync(Guid id);
}
```

### Unit of Work Pattern
```csharp
public interface IUnitOfWork
{
    IRepository<Board> Boards { get; }
    IRepository<Card> Cards { get; }
    Task<int> SaveChangesAsync();
    Task BeginTransactionAsync();
    Task CommitAsync();
}
```

### CQRS (Command Query Responsibility Segregation)
```csharp
// Comando
public class CreateBoardCommand : IRequest<BoardDto>
{
    public string Title { get; set; }
    public string? Description { get; set; }
}

// Handler
public class CreateBoardCommandHandler : IRequestHandler<CreateBoardCommand, BoardDto>
{
    public async Task<BoardDto> Handle(CreateBoardCommand request, CancellationToken cancellationToken)
    {
        // Lógica de criação
    }
}
```

### DTO (Data Transfer Object)
```csharp
// Separar entidades de domínio do que é enviado na API
public class BoardDto
{
    public Guid Id { get; set; }
    public string Title { get; set; }
    public ICollection<BoardListDto> Lists { get; set; }
}
```

## 🚀 Guia de Implementação

### Próximos Passos

#### 1. Implementar Services (Application Layer)
```csharp
// IAuthenticationService
public interface IAuthenticationService
{
    Task<AuthResponseDto> LoginAsync(string email, string password);
    Task<AuthResponseDto> RefreshTokenAsync(string refreshToken);
}

// AuthenticationService implementation
public class AuthenticationService : IAuthenticationService
{
    private readonly IRepository<User> _userRepository;
    private readonly PasswordHashService _passwordHashService;
    private readonly JwtTokenService _jwtTokenService;

    public async Task<AuthResponseDto> LoginAsync(string email, string password)
    {
        // 1. Buscar usuário por email
        // 2. Validar senha com hash
        // 3. Gerar JWT tokens
        // 4. Retornar AuthResponseDto
    }
}
```

#### 2. Implementar Repositories (Infrastructure Layer)
```csharp
public class Repository<T> : IRepository<T> where T : BaseEntity
{
    private readonly AppDbContext _context;

    public async Task<T?> GetByIdAsync(Guid id)
    {
        return await _context.Set<T>().FindAsync(id);
    }

    public async Task<IEnumerable<T>> GetAllAsync()
    {
        return await _context.Set<T>().ToListAsync();
    }
}
```

#### 3. Configurar Injeção de Dependência
```csharp
// Program.cs
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddScoped<IAuthenticationService, AuthenticationService>();
builder.Services.AddScoped<IBoardService, BoardService>();
```

#### 4. Adicionar Validação com FluentValidation
```csharp
public class CreateBoardValidator : AbstractValidator<CreateBoardDto>
{
    public CreateBoardValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("Título é obrigatório")
            .MaximumLength(255).WithMessage("Título não pode exceder 255 caracteres");
    }
}
```

#### 5. Implementar AutoMapper
```csharp
public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<Board, BoardDto>().ReverseMap();
        CreateMap<Card, CardDto>().ReverseMap();
    }
}
```

#### 6. Implementar Frontend Components
```tsx
// Board List Component com Drag & Drop
export function BoardListComponent() {
    const { data: boards } = useQuery(['boards'], () => apiService.get('/boards'));
    
    return (
        <div className="grid grid-cols-3 gap-6">
            {boards.map(board => (
                <BoardCard key={board.id} board={board} />
            ))}
        </div>
    );
}
```

#### 7. Configurar CI/CD
```yaml
# .github/workflows/build-test-deploy.yml
name: Build, Test & Deploy

on:
  push:
    branches: [main, develop]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build Backend
        run: dotnet build backend/
      - name: Build Frontend
        run: npm install && npm run build
  
  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Run Tests
        run: dotnet test backend/
```

### Checklist de Desenvolvimento

- [ ] Implementar todos os Services
- [ ] Implementar todos os Repositories
- [ ] Adicionar FluentValidation em todos os DTOs
- [ ] Configurar AutoMapper
- [ ] Implementar CQRS com MediatR
- [ ] Criar testes unitários
- [ ] Criar testes de integração
- [ ] Configurar Docker & docker-compose
- [ ] Implementar componentes React completos
- [ ] Adicionar Drag & Drop aos Boards
- [ ] Implementar Dashboard com gráficos
- [ ] Configurar CI/CD pipeline
- [ ] Documentar API com Swagger
- [ ] Preparar para deploy

## 📚 Recursos Adicionais

- [Entity Framework Core Documentation](https://learn.microsoft.com/ef/core/)
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [CQRS Pattern](https://martinfowler.com/bliki/CQRS.html)
- [JWT Authentication Best Practices](https://tools.ietf.org/html/rfc7519)
- [React Best Practices](https://react.dev)

---

**Desenvolvido para alcançar excelência em software jurídico profissional**
