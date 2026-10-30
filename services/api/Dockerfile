# Build context: repository root (see infra/docker/docker-compose.yml).
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY global.json ./
COPY services/api/src/LedCare.Api/LedCare.Api.csproj services/api/src/LedCare.Api/
RUN dotnet restore services/api/src/LedCare.Api/LedCare.Api.csproj
COPY services/api/src/ services/api/src/
RUN dotnet publish services/api/src/LedCare.Api/LedCare.Api.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app ./
USER $APP_UID
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "LedCare.Api.dll"]
