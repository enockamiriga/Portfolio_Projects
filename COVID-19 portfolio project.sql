/*
Exploring COVID-19 data for a portfolio project in MYSQL workbench

The following techniques were employed;
Windows and Aggregate Functions, Joins, Common Table Expressions (CTE's), Temporary Tables, Creating Views

*/
USE portfolio_project1;

SELECT 
   *
FROM
   coviddeaths 
WHERE
   continent IS NOT NULL -- AND location IN ("India", "China")
ORDER BY
   continent,location
;


-- Selecting the data we're interested in


SELECT 
   location, 
   date, 
   total_cases, 
   new_cases, 
   total_deaths, 
   population
FROM
   coviddeaths
WHERE 
   continent IS NOT NULL 
ORDER BY 
   1,2
;


/* 
Finding out the total number of deaths from the number of total cases recorded
This somehow gives a rough estimate of the infection-fatality-ratio 
Which basically is the percentage of people infected with the disease that are expected to die

*/

SELECT 
   location, 
date, 
   total_cases,
   total_deaths, 
   (total_deaths/total_cases) * 100 AS DeathPercentage
FROM
   coviddeaths
WHERE
   -- location = 'Ghana' AND 
   continent IS NOT NULL 
ORDER BY
   1,2
;


-- Now finding out what percentage of the population is infected at any particular day


SELECT 
   location, date, 
   population, 
   total_cases,  
   (total_cases/population) * 100 AS PercentPopulationInfected
FROM
   coviddeaths
WHERE 
   continent IS NOT NULL -- AND location = 'Ghana'
ORDER BY
   1,2
;


-- Countries with the highest infection to population rate


SELECT 
   location,
   CAST(date AS DATE) AS date,
   population, 
   COALESCE(MAX(total_cases),0 ) AS HighestInfectionCount,  
   COALESCE(Max((total_cases/population)) * 100,0) AS PercentPopulationInfected
FROM
   coviddeaths
WHERE
   continent IS NOT NULL
GROUP BY 
   location, date, population
ORDER BY 
   1, 2, PercentPopulationInfected DESC
;


-- Countries with the highest death Count per population


SELECT 
   location, 
   MAX(Total_deaths) AS TotalDeathCount
FROM 
   coviddeaths
WHERE 
   continent IS NOT NULL
GROUP BY
   location
ORDER BY 
   TotalDeathCount DESC
;


/*
GROUPING BY CONTINENT

Contintents with the highest death count per population

*/

SELECT 
   continent, 
   MAX(Total_deaths) AS TotalDeathCount
FROM 
   coviddeaths
WHERE 
   continent IS NOT NULL
GROUP BY
   continent
ORDER BY 
   TotalDeathCount DESC
;


-- LOOKING AT THE NUMBERS ACROSS THE WORLD


SELECT
   SUM(new_cases) as total_cases, 
   SUM(new_deaths) as total_deaths, 
   (SUM(new_deaths)/SUM(New_Cases)) * 100 AS DeathPercentage
FROM
   coviddeaths
WHERE
   continent IS NOT NULL 
ORDER BY
   1,2
;


/*
JOINING the covidvaccination table to the coviddeaths table and making more queries

Showing the percentage of the population that has recieved at least a dose of the Covid Vaccine
*/

SELECT 
   cd.continent, 
   cd.location, 
   cd.date, 
   cd.population, 
   cv.new_vaccinations,
   SUM(cv.new_vaccinations) OVER (Partition by cd.location Order by cd.location, cd.date) AS RollingPeopleVaccinated
FROM
   coviddeaths cd
JOIN 
   covidvaccinations cv
ON
   cd.location = cv.location AND
   cd.date = cv.date
WHERE
   cd.continent IS NOT NULL 
ORDER BY
   2,3
;


-- Performing calculation using CTE'S on Partition By, in the previous query

WITH VaccinatedPopulation (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT 
   cd.continent, 
   cd.location, 
   cd.date, 
   cd.population, 
   cv.new_vaccinations,
   SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM
   coviddeaths cd
JOIN 
   covidvaccinations cv
ON
   cd.location = cv.location AND
   cd.date = cv.date
WHERE
   cd.continent IS NOT NULL 
ORDER BY
   2,3
)
SELECT 
   *, 
   (RollingPeopleVaccinated/Population) * 100 AS RollingPercentPopVaccinated
From 
   VaccinatedPopulation


-- Performing calculation using Temporary table on Partition By, in the previous query

DROP TEMPORARY TABLE IF EXISTS PercentPopultionVaccinated;
CREATE TEMPORARY TABLE PercentPopultionVaccinated
(
continent CHAR(255),
location CHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
RollingVaccinatedPeople NUMERIC
)

-- Populating the temporary table with data by an insert into statement

INSERT INTO PercentPopultionVaccinated
SELECT 
   cd.continent, 
   cd.location, 
   cd.date, 
   cd.population, 
   cv.new_vaccinations,
   SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM
   coviddeaths cd
JOIN 
   covidvaccinations cv
ON
   cd.location = cv.location AND
   cd.date = cv.date
WHERE
   cd.continent IS NOT NULL 
GROUP BY
   cd.location, cd.date
ORDER BY
   2,3
;


-- CREATING VIEWS TO STORE DATA FOR VISUALIZATION PURPOSES

-- View One; Shows the global case to death percentage

DROP VIEW IF EXISTS DeathPercentage;
CREATE VIEW DeathPercentage AS
SELECT
   SUM(new_cases) as total_cases, 
   SUM(new_deaths) as total_deaths, 
   (SUM(new_deaths)/SUM(New_Cases)) * 100 AS DeathPercentage
FROM
   coviddeaths
WHERE
   continent IS NOT NULL 
ORDER BY
   1,2
;
   
-- View Two; Shows the total death count across the globe broken down by continents

DROP VIEW IF EXISTS TotalDeathCount;
CREATE VIEW TotalDeathCount AS
SELECT 
   continent, 
   COALESCE(MAX(Total_deaths),0) AS TotalDeathCount
FROM 
   coviddeaths
WHERE 
   continent IS NOT NULL
GROUP BY
   continent
ORDER BY 
   TotalDeathCount DESC
;

-- View Three; Shows the percentage of each population (country) Infected--Map

DROP VIEW IF EXISTS PercentPopulationInfectedMap;
CREATE VIEW PercentPopulationInfectedMap AS
SELECT 
   location,
   population, 
   MAX(COALESCE(total_cases,0)) AS HighestInfectionCount,  
   MaX(COALESCE(total_cases/population * 100,0)) AS PercentPopulationInfected
FROM
   coviddeaths
WHERE
   continent IS NOT NULL
GROUP BY 
   location
ORDER BY 
   1, 2
;

-- View Four; Percentage of the Population Infected (Time series)

DROP VIEW IF EXISTS PercentPopulationInfectedLine;
CREATE VIEW PercentPopulationInfectedLine AS
SELECT 
   location,
   CAST(date AS DATE) AS date,
   population, 
   MAX(COALESCE(total_cases,0)) AS HighestInfectionCount,  
   MaX(COALESCE(total_cases/population * 100,0)) AS PercentPopulationInfected
FROM
   coviddeaths
WHERE
   continent IS NOT NULL
GROUP BY 
   location, date, population
ORDER BY 
   1, 2
;

-- View Five; Percent of the Population Vaccinated

DROP VIEW IF EXISTS PercentPopulationVaccinated;
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
   cd.location, 
   CAST(cd.date AS DATE) AS date, 
   cd.population, 
   COALESCE(cv.new_vaccinations,0),
   SUM(COALESCE(cv.new_vaccinations, 0)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM
   coviddeaths cd
JOIN 
   covidvaccinations cv
ON
   cd.location = cv.location AND
   cd.date = cv.date
WHERE
   cd.continent IS NOT NULL
GROUP BY
   cd.location, cd.date
ORDER BY 
   1, 2
   ;
