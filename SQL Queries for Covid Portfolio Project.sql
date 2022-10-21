--What percentage of people with covid died?  total cases vs total deaths 
SELECT
  location, 
  date, 
  (total_cases_per_million *(population/1000000))AS total_cases, 
  total_deaths, 
  (total_deaths/ (total_cases_per_million *(population/1000000)))*100 AS percentage_of_deaths
FROM
  `covidproject-363122.CovidData.CovidDeaths`
 ORDER BY
  1,2;

--likelihood of dying if you contract covid in the US
SELECT
  location, 
  date, 
  (total_cases_per_million *(population/1000000))AS total_cases, 
  total_deaths, 
  (total_deaths/ (total_cases_per_million *(population/1000000)))*100 AS percentage_of_deaths
FROM
  `covidproject-363122.CovidData.CovidDeaths`
WHERE
  location = 'United States'
ORDER BY
  1,2;

 --what percentage of the population has gotten covid 
SELECT
  location, 
  date, 
  (total_cases_per_million *(population/1000000))AS total_cases, 
  population,
 ((total_cases_per_million *(population/1000000))/population)*100 AS percentage_that_contracted_covid
FROM
  `covidproject-363122.CovidData.CovidDeaths`
WHERE
  location = 'United States'
ORDER BY
  1,2;

--countries with the highest infection rate per population 
SELECT
  location, population, MAX ((total_cases_per_million)*(population/1000000)) AS GreatestInfections, MAX(((total_cases_per_million * (population/1000000)/population)))*100 as percent_that_contracted_covid
FROM
  `covidproject-363122.CovidData.CovidDeaths`
GROUP BY
  location, population
ORDER BY
  percent_that_contracted_covid DESC;
  
--countries with the highest death count per population
SELECT
  location, MAX (total_deaths) AS total_death_count
FROM
  `covidproject-363122.CovidData.CovidDeaths`
WHERE 
  continent IS NOT null
GROUP BY
  location
ORDER BY
  total_death_count DESC;

--Max number of deaths by continent  
SELECT
  location, MAX (total_deaths) AS total_death_count
FROM
  `covidproject-363122.CovidData.CovidDeaths`
WHERE 
  continent IS null
GROUP BY
  location
ORDER BY
  total_death_count DESC;

--total cases and deaths across the entire world by location  
SELECT
  location, 
  date, 
  (total_cases_per_million *(population/1000000)) AS total_cases, 
  total_deaths, 
  (total_deaths/(total_cases_per_million *(population/1000000)))*100 as percentage_of_deaths
  FROM
  `covidproject-363122.CovidData.CovidDeaths`
WHERE 
  continent IS NOT null
ORDER BY
  1,2;

--on each day the absolute total cases across the world/daily worldwide cases
SELECT
  date, 
  SUM (new_cases) AS sum_of_cases, 
  FROM
  `covidproject-363122.CovidData.CovidDeaths`
WHERE 
  continent IS NOT null
GROUP BY
  date
ORDER BY
  1,2;

--adding in sum of new deaths to get a count of new death toll for each date/ daily worldwide cases and deaths
SELECT
  date, 
  SUM (new_cases) AS sum_of_cases, 
  SUM (new_deaths) AS sum_of_deaths 
FROM
  `covidproject-363122.CovidData.CovidDeaths`
WHERE 
  continent IS NOT null
GROUP BY
  date
ORDER BY
  1,2;

--Gives the worldwide number of cases, sum of deaths, percentage of deaths across each day 
SELECT
  date, 
  SUM (new_cases) AS sum_of_cases, 
  SUM (new_deaths) AS sum_of_deaths, 
  SUM (new_deaths)/SUM (new_cases)*100 AS death_percentage
 FROM
  `covidproject-363122.CovidData.CovidDeaths`
WHERE 
  continent IS NOT null
GROUP BY
  date
ORDER BY
  1,2;

--overall sum of cases, deaths, and percentage of deaths as of the end of this data-set (at the time of download Sept. 2022) 
SELECT
  SUM (new_cases) AS sum_of_cases, 
  SUM (new_deaths) AS sum_of_deaths, 
  SUM (new_deaths)/SUM (new_cases)*100 AS death_percentage
FROM
  `covidproject-363122.CovidData.CovidDeaths`
WHERE 
  continent IS NOT null
ORDER BY
  1,2;


--total number of people in the world that have been vaccinated 
SELECT 
	death.continent, 
	death.location, 
	death.date, 
	death.population, 
	vax.new_vaccinations
FROM `covidproject-363122.CovidData.CovidDeaths` AS death
JOIN `covidproject-363122.CovidData.CovidVaccinations` AS vax 
  ON death.location = vax.location and death.date = vax.date
WHERE 
 	death.continent IS NOT null
ORDER BY
	1,2,3;

--adding a rolling/summative count of vaccinations by day.  creates a new column to show rolling sum. Partition by location and date. Location will limit the sum to a specific location so that it doesn't run the sum from one country into the next.   
SELECT 
	death.continent, 
	death.location, 
	death.date, 
	death.population, 
	vax.new_vaccinations, 
	SUM (vax.new_vaccinations) OVER (PARTITION BY death.location ORDER BY 
	death.location, death.date) as running_vax_total 
FROM `covidproject-363122.CovidData.CovidDeaths` AS death
JOIN `covidproject-363122.CovidData.CovidVaccinations` AS vax 
  ON death.location = vax.location and death.date = vax.date
WHERE 
  death.continent IS NOT null
ORDER BY
  2,3;

--adds a new column for reference to look at the total population vs the number of vaccinations. Shows the percentage of vaccinations in respect to total population (note includes boosters)/running vax and vaccine percentage totals)
WITH population_vs_vaccination AS
(
  SELECT 
    death.continent, 
    death.location, 
    death.date, 
    death.population, 
    vax.new_vaccinations, 
    SUM (vax.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, 
    death.date) as running_vax_total 
  FROM `covidproject-363122.CovidData.CovidDeaths` AS death
  JOIN `covidproject-363122.CovidData.CovidVaccinations` AS vax 
    ON death.location = vax.location and death.date = vax.date
  WHERE 
    death.continent IS NOT null
  )
  SELECT *,
    (running_vax_total/population*100)as running_percent_of_vaccines
  FROM
    population_vs_vaccination;


--Adds running percent of vaccinations, total boosters, and percentage of fully vaccinated. Shows fully vaccinated alongside the running total of the percentage of vaccines received.  
WITH population_vs_vaccination AS 
  (
  SELECT 
    death.continent, 
    death.location, 
    death.date, 
    death.population, 
    vax.new_vaccinations, 
    vax.people_fully_vaccinated,
    vax.total_boosters,
    SUM (vax.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, 
    death.date) as running_vax_total
  FROM `covidproject-363122.CovidData.CovidDeaths` AS death
  JOIN `covidproject-363122.CovidData.CovidVaccinations` AS vax 
    ON death.location = vax.location and death.date = vax.date
  WHERE 
    death.continent IS NOT null
  )
  SELECT *,
    (running_vax_total/population*100)as running_percent_of_vaccines, (people_fully_vaccinated/population * 100) AS percent_fully_vaccinated
  FROM
    population_vs_vaccination;


--Important Dates: 
--Dec 11, 2020 first pfizer doses available for 16 & O
--May 10, 2021 first doses for 12-15
--Aug 12, 2021 3rd dose authorized for immunocompromised over 12 y.o.
--Sept 22, 2021 single booster dose for over 65 y.o., high risk 18-65 y.o.
--Nov 3/4, 2021 authorization for pfizer vaccine, children 5-11 y.o
-- Nov 19, 2021 single booster (pfizer or moderna) over 18 y.o. authorized
--March 29, 2022 second booster (pfizer or moderna) authorized for immunocompromised over 12 y.o. and adults over 50 y.o.
--June 17, 2022 moderna and pfizer auth for 6 mo to 6 y.o. children
--Sept 1, 2022 Updated booster (pfizer over 12 y.o. or moderna over 18 y.o.) 


