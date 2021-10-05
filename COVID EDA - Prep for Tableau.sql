/*
Covid 19 Death and Vaccination Exploration
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select * 
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
ORDER BY 3,4

-- Select the Data that we will be working with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Total Cases vs Total Deaths for Canada
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'Canada'
ORDER BY 1,2

-- Total Cases vs Total Deaths for United States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Total Cases vs Population (Infection Rates)
SELECT location, date, total_cases, population, ROUND((total_cases/population)*100, 2) as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Countries with Highest Infection Rate as compared to Population
SELECT location, population, MAX(total_cases) as MaxInfectionCount, MAX(total_cases/population)*100 as PercentageInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentageInfected DESC


-- Country with the Highest Death Counts
Select location, MAX(CAST(Total_deaths as int)) as TotalDeathsToDate
From PortfolioProject..CovidDeaths
Group by location
order by TotalDeathsToDate desc

-- Notice that this query includes Continents and world - so we want to fix with WHERE clause
Select location, MAX(CAST(Total_deaths as int)) as TotalDeathsToDate
From PortfolioProject..CovidDeaths
WHERE continent is not null
Group by Location
order by TotalDeathsToDate desc


-- Explore Conutries with Highest Death Count Per Population
SELECT location, population, MAX(CAST(total_deaths as int)) AS TotalDeathstoDate,
	(MAX(CAST(total_deaths as int))/population)*100 AS DeathsPerPop
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY DeathsPerPop DESC


-- Let's break it Down by Continents

-- Continents with Highest Death Count
SELECT continent, MAX(CAST(total_deaths as int)) AS TotalDeathstoDate
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathstoDate DESC

--Notice above query is innacurate (N.A. is only including USA)
-- Try different method with where clause
SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathstoDate
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathstoDate DESC

--Check that NA is accurate
SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathstoDate
FROM PortfolioProject..CovidDeaths
WHERE location in ('United States','Canada','Mexico','North America')
GROUP BY location
ORDER BY TotalDeathstoDate DESC


-- GLOBAL NUMBERS by DATE
SELECT date, SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- GLOBAL Death Percentage
SELECT date, SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- Total Population vs Vaccinations

-- Join Tables
SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Percentage of Population with at Least 1 Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VacToDate
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- CTE Creation and use
WITH PopVsVac (continent, location, date, population, new_vaccinations, VacToDate)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VacToDate
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (VacToDate/population)*100 AS VacPercentage --Some percentage over 100 for double vax
FROM PopVsVac


-- Same thing but with TEMP TABLE
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
VacToDate numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VacToDate
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (VacToDate/population)*100 AS VacPercentage
FROM #PercentPopulationVaccinated


-- CREATE VIEWS for Tableau Use Later


-- View for the Percentage of a Country Vaccinated
CREATE VIEW PercentPopulationVaccinated 
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VacToDate
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent is not null

-- View for Deaths by Country and Percentage of Deaths
CREATE VIEW DeathPercentage AS
SELECT date, location, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--ORDER BY 2,1
