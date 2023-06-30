-- Covid Deaths Table
Select * 
From Covid19..CovidDeaths
Where continent is not Null
Order by 3,4

/*Select * 
From Covid19_Project..CovidVaccinations
Order by 3,4*/

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population 
From Covid19..CovidDeaths
Where continent is not Null
order by 1,2

--- Getting the death percent for the location
Select Location, date, total_cases, total_deaths, FORMAT((CAST(total_deaths AS numeric) / CAST(total_cases AS numeric)) * 100, 'N2') AS DeathPercentage
From Covid19..CovidDeaths
-- checking data for united states
where location like '%states%' and continent is not Null
order by 1,2

-- looking at total cases vs population
-- shows what % of population got covid
SELECT Location, date, population, total_cases, FORMAT((total_cases / population) * 100, 'N2') AS PercentPopulationInfected
FROM Covid19..CovidDeaths
-- checking data for United states
WHERE Location LIKE '%states%' AND continent IS NOT NULL
ORDER BY Location, date



-- ROUND(MAX(Cast((total_cases as Numeric/population*100)),2)

-- looking at countries with highest total_cases rate compared to population
Select Location, Population, MAX(Cast(total_cases as numeric)) as Highest_Infection_Count, ROUND(MAX((Cast(total_cases as numeric)/population)*100),2) as PercentPopulationInfected
From Covid19..CovidDeaths
Where continent is not Null
-- grouping by the population and location
Group by Location, Population
-- ordering by the percent of population that is infected: in a descending order so we see the highest at the top
Order by PercentPopulationInfected desc

-- Showing Countries with the highest death count per population
Select Location, MAX(Cast(total_deaths as Numeric)) as TotalDeathCount
From Covid19..CovidDeaths
Where continent is not Null
Group by Location
Order by TotalDeathCount desc



-- CONTINENT QUERIES --

-- showing continents with the highest death count per population
Select continent, MAX(Cast(total_deaths as numeric)) as TotalDeathCount
From Covid19..CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount desc



-- GLOBAL QUERIES --

-- Showing continents with highest death count per population
Select continent, MAX(cast(total_deaths as numeric)) as TotalDeathCount
From Covid19..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

-- Daily Global Deaths
SELECT date,
       SUM(cast(new_cases AS numeric)) AS total_new_cases,
       SUM(cast(new_deaths AS numeric)) AS total_new_deaths,
       CONCAT(FORMAT((SUM(cast(new_deaths AS numeric)) * 100.0) / NULLIF(SUM(cast(new_cases AS numeric)), 0), 'N2'), '%') AS DeathPercentage
FROM Covid19..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

-- Global Death Percentage
Select SUM(cast(new_deaths as numeric)) as total_deaths, SUM(new_cases) as total_cases, Sum(Cast(new_deaths as numeric))/SUM(new_cases)*100 as DeathPercentage
from Covid19..CovidDeaths
where continent is not null
order by 1,2


-- Covid Vaccination Table

-- Joining tables on Location and Date
Select *
From Covid19..CovidDeaths Deaths
Join Covid19..CovidVaccinations Vaccinations
	ON deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
order by 1,2,3

-- looking at total population vs vaccinations
Select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations
from Covid19..CovidDeaths deaths
join Covid19..CovidVaccinations vaccinations
	on deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
where deaths.continent is not null
order by 2,3

-- looking at total population vs vaccinations, rolling vaccinations
Select deaths.continent, 
		deaths.location,
		deaths.date, 
		deaths.population,
		vaccinations.new_vaccinations,
		SUM(CAST(vaccinations.new_vaccinations as numeric)) 
		OVER (Partition By deaths.location Order by deaths.location, deaths.date) as RollingPeopleVaccinated
from Covid19..CovidDeaths deaths
join Covid19..CovidVaccinations vaccinations
	on deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
where deaths.continent is not null
order by 2,3

-- checking global total vaccination of each continent
SELECT deaths.continent, SUM(CAST(ISNULL(vaccinations.total_vaccinations, 0) AS bigint)) AS total_vaccinations
FROM Covid19..CovidDeaths deaths
JOIN Covid19..CovidVaccinations vaccinations
    ON deaths.continent = vaccinations.continent
WHERE deaths.continent IS NOT NULL
GROUP BY deaths.continent
ORDER BY total_vaccinations DESC

-- checking global MAX vaccination of each continent
SELECT deaths.continent, MAX(CAST(ISNULL(vaccinations.total_vaccinations, 0) AS bigint)) AS max_vaccinations
FROM Covid19..CovidDeaths deaths
JOIN Covid19..CovidVaccinations vaccinations
    ON deaths.continent = vaccinations.continent
WHERE deaths.continent IS NOT NULL
GROUP BY deaths.continent
ORDER BY max_vaccinations DESC

-- checking % of people vaccinated -- [USING CTE] -- rolling number population vs rolling people vaccinated
With POPvsVAC (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select deaths.continent, 
		deaths.location,
		deaths.date, 
		deaths.population,
		vaccinations.new_vaccinations,
		SUM(CAST(vaccinations.new_vaccinations as numeric)) 
		OVER (Partition By deaths.location Order by deaths.location, deaths.date) as RollingPeopleVaccinated
		--(RollingPeopleVaccinated/population)*100
FROM Covid19..CovidDeaths deaths
Join Covid19..CovidVaccinations vaccinations
	on deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
where deaths.continent is not null
--order by 2,3
)

Select *, (RollingPeopleVaccinated/Population)*100
FROM POPvsVAC


-- TEMP TABLE --
-- If you update something for this table
-- remember to: DROP TABLE if exists #TEMP_TABLE_NAME
-- before you change something
Drop Table if exists #PercentPopulationVaccinated
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
Select deaths.continent, 
		deaths.location,
		deaths.date, 
		deaths.population,
		vaccinations.new_vaccinations,
		SUM(CAST(vaccinations.new_vaccinations as numeric)) 
		OVER (Partition By deaths.location Order by deaths.location, deaths.date) as RollingPeopleVaccinated
		--(RollingPeopleVaccinated/population)*100
FROM Covid19..CovidDeaths deaths
Join Covid19..CovidVaccinations vaccinations
	on deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
-- where deaths.continent is not null
-- order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating a view --

-- Views are generally used to focus, simplify
-- and customize the perception each user has of the database

-- View Starting From Continent --

-- Need to use this batch to make view work
USE Covid19
GO

-- batch to create / alter view 
Create or Alter View PercentPopulationVaccinated as
Select deaths.continent, 
		deaths.location,
		deaths.date, 
		deaths.population,
		vaccinations.new_vaccinations,
		SUM(CAST(vaccinations.new_vaccinations as numeric)) 
		OVER (Partition By deaths.location Order by deaths.location, deaths.date) as RollingPeopleVaccinated
		--(RollingPeopleVaccinated/population)*100
FROM Covid19..CovidDeaths deaths
Join Covid19..CovidVaccinations vaccinations
	on deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
where deaths.continent is not null

-- Select everything from the view we made
Select *
From PercentPopulationVaccinated