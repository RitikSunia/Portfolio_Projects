/*
COVID-19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


--Checking if the data is properly imported

select * from portfolio..coviddeaths
select * from portfolio..covidvaccines


-- seleceting the data from which we are going to commence

select location, date, total_cases, new_cases, total_deaths, population
from portfolio..coviddeaths
where continent is not null
-- the above query is used to avoid double counting
order by 1,2

-- calculating the percentage of death if a person is infected with Covid-19, i.e., total deaths/ total cases

select location, date, total_cases, total_deaths, (total_deaths/cast(total_cases as float))*100 as Death_Percentage
from portfolio..coviddeaths
where location like '%India%'
-- the above query is used to just extract the data for India
and continent is not null
order by 1,2


-- Now, calculating the percentage of population infected by Covid-19
select location, date, population, total_cases,(cast(total_cases as float)/population)*100 as Death_Percentage
from portfolio..coviddeaths
--where location like '%India%'
-- the above query is used to just extract the data for India

order by 1,2


-- Countries with highest infection rate compared to population
 select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
 from portfolio..coviddeaths
 Group by location, population
 order by PercentPopulationInfected desc

 -- Countries with highest death count
 Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From portfolio..coviddeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- Now getting more into exploration

-- showing continents with highest number of deaths per population
 Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From portfolio..coviddeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc

--Global Number

select sum(cast(new_cases as float)) as TotalCases, sum(cast(new_deaths as float)) as TotalDeaths, 
(sum(cast(new_deaths as float))/sum(cast(new_cases as float)))*100 as DeathPercentage
from portfolio..coviddeaths
where continent is not null
order by 1,2


-- Joining both datasets
select * 
from portfolio..coviddeaths as dea
join portfolio..covidvaccines as vac
	on dea.location = vac.location
	and dea.date = vac.date



-- Exploring total number of people vaccinated as compared to total population
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From portfolio..coviddeaths dea
Join portfolio..covidvaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE (Common Table Expression) to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From portfolio..coviddeaths dea
Join portfolio..covidvaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
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
From portfolio..coviddeaths dea
Join portfolio..covidvaccines vac
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
From portfolio..coviddeaths dea
Join portfolio..covidvaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

