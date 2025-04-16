-- loading Nigeria COVID death data 
SELECT *
From Portfolio_Project_SQL..Covid_Deaths
where continent is not null and location = 'Nigeria'
order by 1, 2


--select the data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
From Portfolio_Project_SQL..Covid_Deaths
where continent is not null and location like '%nigeria%'
order by 1, 2

-- looking at total death vs total cases

SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_perecent
From Portfolio_Project_SQL..Covid_Deaths
where continent is not null and location like '%nigeria%'
order by date

-- looking at the total cases vs population (showing what percentage of population that got covid)

SELECT location, date, total_cases, new_cases, total_deaths, population, (total_cases/population)*100 AS population_perecent
From Portfolio_Project_SQL..Covid_Deaths
where continent is not null and location like '%nigeria%'
order by date

-- looking at countries with highest infection_rate compared to population

SELECT location, MAX(total_cases) as highest_infection_count, MAX(total_cases/population)*100 AS Death_perecent
From Portfolio_Project_SQL..Covid_Deaths
group by location
order by Death_perecent DESC

-- showing the country with the highest death count per population

SELECT location, MAX(cast(total_deaths as int)) as total_deat_count
From Portfolio_Project_SQL..Covid_Deaths
where continent is null
group by location
order by total_deat_count desc


--lets break it down by continent
--showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
From Portfolio_Project_SQL..Covid_Deaths
where continent is not null
group by continent
order by total_death_count desc


--GLOBAL NUMBERS

SELECT
    --date,
	continent,
    SUM(new_cases) as sum_new_cases,
    SUM(CAST(new_deaths as int)) as sum_new_deaths,
	ROUND(
			CASE 
				WHEN SUM(new_cases) = 0 THEN NULL
				ELSE (SUM(CAST(new_deaths as int)) * 100.0) / SUM(new_cases)
			END, 2 
		  ) as death_percent
FROM Portfolio_Project_SQL..Covid_Deaths
WHERE continent is not null 
GROUP BY continent

SELECT 
	SUM(new_cases), 
	SUM(cast(new_deaths as int)), 
	SUM(cast(new_deaths as int))/NULLIF(SUM(new_cases), 0)*100 as death_percentage
From Portfolio_Project_SQL..Covid_Deaths
where continent is not null


---loading desired data from a new table

select *
Join Portfolio_Project_SQL.dbo.Covid_Vaccination as vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


-- looking at the total population vaccinated over time

SELECT 
    dea.continent, 
    dea.location, 
    dea.date,
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS INT)) 
		OVER (
			PARTITION BY dea.location 
			ORDER BY dea.date
			  ) AS rolling_vaccinations
FROM Portfolio_Project_SQL.dbo.Covid_Deaths AS dea
JOIN Portfolio_Project_SQL.dbo.Covid_Vaccination AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- looking at total population vs sum of daily vaccination

--Using a CTE to calculate the rolling_vacccination percentage

with PopvsVac as (
					SELECT 
    dea.continent, 
    dea.location, 
    dea.date,
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS INT)) 
		OVER (
			PARTITION BY dea.location 
			ORDER BY dea.date
			  ) AS rolling_vaccinations
FROM Portfolio_Project_SQL.dbo.Covid_Deaths AS dea
JOIN Portfolio_Project_SQL.dbo.Covid_Vaccination AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
				  )
SELECT continent, location, population, rolling_vaccinations, round(((rolling_vaccinations/population)*100), 3) as vaccination_percentage
FROM PopvsVac
where continent is not null and location = 'Nigeria'


--Fnding vaccination_perecent using TEMP TABLE

Drop table if exists #PerecentPopulationVaccinated 
Create table #PerecentPopulationVaccinated 
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccination numeric,
	rolling_vaccinations numeric,
)


Insert into #PerecentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date,
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS INT)) 
		OVER (
			PARTITION BY dea.location 
			ORDER BY dea.date
			  ) AS rolling_vaccinations
FROM Portfolio_Project_SQL.dbo.Covid_Deaths AS dea
JOIN Portfolio_Project_SQL.dbo.Covid_Vaccination AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

select *, ((rolling_vaccinations/population)*100)
FROM #PerecentPopulationVaccinated

-- trying out different ideas (ignore)

select*
From #PerecentPopulationVaccinated as temp
join Portfolio_Project_SQL..Covid_Vaccination as vacci
on temp.continent = vacci.continent
	and temp.location = vacci.location

-- creating views to store and to keep together

Create View PercentPopulation_Vaccinated as
SELECT 
    dea.continent, 
    dea.location, 
    dea.date,
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS INT)) 
		OVER (
			PARTITION BY dea.location 
			ORDER BY dea.date
			  ) AS rolling_vaccinations
FROM Portfolio_Project_SQL.dbo.Covid_Deaths AS dea
JOIN Portfolio_Project_SQL.dbo.Covid_Vaccination AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT * FROM sys.views
WHERE name = 'PercentPopulation_Vaccinated'