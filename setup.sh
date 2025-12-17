#!/bin/bash

# Setup Script para LegalTech SaaS

set -e

echo "🚀 Iniciando setup do LegalTech SaaS..."

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar .NET
echo -e "${YELLOW}[1/5]${NC} Verificando .NET SDK..."
if ! command -v dotnet &> /dev/null; then
    echo -e "${RED}✗ .NET SDK não encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}✓ .NET SDK: $(dotnet --version)${NC}"

# Restaurar Backend
echo -e "${YELLOW}[2/5]${NC} Restaurando pacotes Backend..."
cd backend/LegalTech.API
dotnet restore
dotnet build -c Release
echo -e "${GREEN}✓ Backend compilado${NC}"

# Setup Frontend
echo -e "${YELLOW}[3/5]${NC} Instalando dependências Frontend..."
cd ../../frontend/legaltech-web
if ! command -v npm &> /dev/null; then
    echo -e "${RED}✗ Node.js/npm não encontrado${NC}"
    exit 1
fi
npm install
npm run build
echo -e "${GREEN}✓ Frontend compilado${NC}"

# Docker
echo -e "${YELLOW}[4/5]${NC} Verificando Docker..."
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker disponível${NC}"
    echo -e "${YELLOW}[5/5]${NC} Iniciando serviços Docker..."
    cd ../../
    docker-compose up -d
    echo -e "${GREEN}✓ Containers iniciados${NC}"
else
    echo -e "${YELLOW}⚠ Docker não disponível - pule este passo${NC}"
fi

echo -e "${GREEN}✅ Setup concluído!${NC}"
echo ""
echo "URLs de acesso:"
echo "  🌐 Frontend: http://localhost:3000"
echo "  🔌 API:     http://localhost:5000"
echo "  🗄️  DB:      localhost:5432"
