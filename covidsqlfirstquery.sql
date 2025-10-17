/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From tarek..CovidDeaths$
Where continent is not null 
order by 3,4

-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From tarek..CovidDeaths$
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From tarek..CovidDeaths$
Where location like '%egypt%'
and continent is not null 
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From tarek..CovidDeaths$
--Where location like '%egypt%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT location , population , MAX(CovidDeaths$.total_cases) AS HighestInfectionCount , MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM tarek..CovidDeaths$
--WHERE location like '%egypt%'
GROUP BY location , population 
ORDER BY PercentPopulationInfected desc

-- Countries with Highest Death Count per Population

SELECT location , MAX(CAST(CovidDeaths$.total_deaths as int)) AS TotalDeathCount
FROM tarek..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent , MAX(CAST(CovidDeaths$.total_deaths as int)) AS TotalDeathCount
FROM tarek..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT SUM(CovidDeaths$.new_cases) AS Total_Cases , SUM(CAST(CovidDeaths$.total_deaths AS int)) AS Total_death , SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage 
FROM tarek..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1 , 2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location , dea.date) AS RollingPeopleVaccinated
FROM tarek..CovidDeaths$ AS dea
JOIN tarek..Covidvax$ AS vac 
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2 , 3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM tarek..CovidDeaths$ AS dea
JOIN tarek..Covidvax$ AS vac 
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
Select *, (RollingPeopleVaccinated/Population)*100 AS PeopleVaccinatedPercentage
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

--DROP Table if exists #PercentPopulationVaccinated
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;


CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM tarek..CovidDeaths$ AS dea
JOIN tarek..Covidvax$ AS vac 
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated
as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM tarek..CovidDeaths$ AS dea
JOIN tarek..Covidvax$ AS vac 
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL