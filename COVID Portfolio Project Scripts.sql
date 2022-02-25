/*

Covid 19 Data Exploration Showcase
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
Order By 3,4


-- Selecting the Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order By 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
Order By 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

Select Location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Order By 1,2


-- Looking at Countries with Highest Infection Rate compared to Population

Select Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS 
	PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group By Location, Population
Order By PercentPopulationInfected DESC


-- Looking at Countries with Highest Death Count per Population

Select Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group By Location
Order By TotalDeathCount DESC


-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

Select location, MAX(cast(total_deaths as int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is null
Group By location
Order By TotalDeathCount DESC


-- Global Numbers

Select SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) AS total_death, 
	SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
--Group By date
Order By 1,2


-- Looking at Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order By dea.location,
	dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths AS dea
Join PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
Order By 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order By dea.location,
	dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths AS dea
Join PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
--Order By 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
