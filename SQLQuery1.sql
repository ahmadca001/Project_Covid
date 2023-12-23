-- Checking updated tables
Select *
From Project_Covid..deaths 

Select *
From Project_Covid..vaccinations 


-- Total Cases vs Total Deaths 
Select 
--top 10 
Location, sum(convert(float, total_cases_per_million)) as TotalCases , sum(convert(float, total_deaths_per_million)) as TotalDeaths,
   max(convert(float, total_deaths_per_million) / (convert(float, total_cases_per_million)))*100 as DeathPercentage
From Project_Covid..deaths
Where continent is not null
group by location 
--order by 1,2
order by DeathPercentage desc
--offset 0 rows fetch next 10 rows only; 

SELECT 
    Location,
    continent, 
    SUM(CONVERT(float, total_cases_per_million)) AS TotalCases,
    SUM(CONVERT(float, total_deaths_per_million)) AS TotalDeaths,
    MAX(CONVERT(float, total_deaths_per_million) / NULLIF(CONVERT(float, total_cases_per_million), 0)) * 100 AS DeathPercentage
FROM 
    Project_Covid..deaths
WHERE 
    continent IS NULL
GROUP BY 
    Location, continent
ORDER BY 
    Location, continent;

-- Exploring deaths in canada 

Select Location, date, total_cases_per_million, new_cases, total_deaths_per_million, population
From Project_Covid..deaths
order by 1,2

Select Location, date, total_cases_per_million, new_cases, total_deaths_per_million, population
From Project_Covid..deaths
where location like 'Canada'
order by 1,2

Select Location, date, total_cases_per_million,total_deaths_per_million, 
(convert(float, total_deaths_per_million) / (convert(float, total_cases_per_million)))*100 as DeathPercentage
From Project_Covid..deaths
Where location like 'Canada'
and continent is not null 
order by 1,2

Select Location, date, Max(convert(float, total_cases_per_million)) , max(convert(float, total_deaths_per_million)), 
  Max(convert(float, total_deaths_per_million) / (convert(float, total_cases_per_million)))*100 as DeathPercentage
From Project_Covid..deaths
Where location like 'Canada'
and continent is not null 
group by location,date
order by 1,2

Select Location, date, sum(convert(float, total_cases_per_million)) as TotalCases , sum(convert(float, total_deaths_per_million)) as TotalDeaths, 
  sum(convert(float, total_deaths_per_million) / (convert(float, total_cases_per_million)))*100 as DeathPercentage
From Project_Covid..deaths
Where (location like 'Canada'
and continent is not null) 
group by location,date
order by DeathPercentage desc

Select Location, sum(convert(float, total_cases_per_million)) as TotalCases , sum(convert(float, total_deaths_per_million)) as TotalDeaths,
  max(convert(float, total_deaths_per_million) / (convert(float, total_cases_per_million)))*100 as DeathPercentage
From Project_Covid..deaths
Where (location like 'Canada'
and continent is not null) 
group by location


-- Total Cases vs Population

Select Location, Population, MAX(total_cases_per_million) as HighestInfectionCount,  
Max((total_cases_per_million/population))*100 as PercentPopulationInfected
From Project_Covid..deaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

Select Location, MAX(convert(float, Total_deaths)) as TotalDeathCount
From Project_Covid..deaths
--Where location like 'canada'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

Select Location, date, Population, total_cases_per_million,  
(total_cases_per_million/population)*100 as PercentPopulationInfected
From Project_Covid..deaths
Where location like 'canada'
order by 1,2

-- BREAKING THINGS DOWN BY CONTINENT

Select continent, MAX(convert(float, Total_deaths )) as TotalDeathCount
From Project_Covid..deaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Project_Covid..deaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(nullif(CONVERT(int,vac.new_vaccinations),0)) 
OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project_Covid..deaths dea
Join Project_Covid..vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With RollingPeopleVaccinated (continent, location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(nullif(CONVERT(int,vac.new_vaccinations),0)) 
OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project_Covid..deaths dea
Join Project_Covid..vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select continent, location,(RollingPeopleVaccinated/Population)*100 as RPVvsPOP
From RollingPeopleVaccinated



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
, SUM(nullif(CONVERT(float,vac.new_vaccinations),0)) 
OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project_Covid..deaths dea
Join Project_Covid..vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(nullif(CONVERT(float,vac.new_vaccinations),0)) 
OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project_Covid..deaths dea
Join Project_Covid..vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

