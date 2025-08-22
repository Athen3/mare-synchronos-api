FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5000

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MareSynchronos.API.csproj", "./"]
RUN dotnet restore "MareSynchronos.API.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "MareSynchronos.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "MareSynchronos.API.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENV ASPNETCORE_URLS=http://+:5000
ENTRYPOINT ["dotnet", "MareSynchronos.API.dll"]
