FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj files
COPY ["backend/LegalTech.API/LegalTech.API.csproj", "LegalTech.API/"]
COPY ["backend/LegalTech.Application/LegalTech.Application.csproj", "LegalTech.Application/"]
COPY ["backend/LegalTech.Infrastructure/LegalTech.Infrastructure.csproj", "LegalTech.Infrastructure/"]
COPY ["backend/LegalTech.Domain/LegalTech.Domain.csproj", "LegalTech.Domain/"]

# Restore
RUN dotnet restore "LegalTech.API/LegalTech.API.csproj"

# Copy source
COPY backend/ .

# Build
RUN dotnet build "LegalTech.API/LegalTech.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "LegalTech.API/LegalTech.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "LegalTech.API.dll"]
