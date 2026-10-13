# Task: NYC commuting flows

*Originally a timed data task. The questions and data description are reproduced below.*

The data describe commuting flows between neighborhoods (census tracts) of New York City. The task is to describe and analyze the data.

## Data

- `nyc_commuting_tracts.csv` (689,551 lines, 6 columns), distributed as a 10 MB ZIP file.
- A row is identified by `home_tract` and `work_tract`, which are FIPS codes (11-digit numbers that uniquely identify each census tract in the United States).
- `commuters` is the number of commuters who reside in `home_tract` and work in `work_tract`.
- `physical_distance` is the number of kilometers (geodetic distance) between tracts.
- `traveltime_public` is travel time in minutes from `home_tract` to `work_tract` by public transport.
- `traveltime_car` is travel time in minutes from `home_tract` to `work_tract` by private vehicle.

## Outputs

1. A summary statistics table for tract-to-tract variables.
2. A county-to-county commuting dataset.
3. A table reporting estimates of three regressions.
4. Written answers to the questions below.

## Questions

### Summary statistics

Produce a table of summary statistics describing the data. For each of the four tract-to-tract variables, report the number of observations, mean, standard deviation, and 25th, 50th, and 75th percentiles. List each variable in a row and the six statistics in six columns.

The "15-minute city" is a concept in urban planning. Compute the fraction of NYC commuters whose commute from home to work is 15 minutes or less if they use the fastest available transportation mode.

### County-level commuting matrix

New York City is made up of five counties. The first 5 digits of the 11-digit FIPS code identify the county in which a tract is located. The first 2 digits identify the state (36 = New York) and the first 5 digits identify the county within the state (36001 = Albany, New York).

Aggregate the tract-level commuting counts to produce county-to-county commuting counts for the 25 pairs of counties. Save them in a CSV file named `nyc_commuting_counties.csv` with three columns:

- `home_county`
- `work_county`
- `commuters`

### Regressions

Analyze the tract-to-tract flows by relating the number of commuters to commuting costs such as travel time.

Produce a scatterplot with log distance on the horizontal axis and log commuters on the vertical axis. Construct a "binned scatterplot" that groups the observations into 100 bins. Create these 100 bins based on distance between the two tracts so that each bin has an (almost) equal number of observations. The binned scatterplot depicts the average log commuters and average log distance for the observations in each bin. Draw the line of best fit through the binned points.

Produce a table reporting the estimates of three gravity regressions:

1. Regress the log number of commuters on the log travel time by public transit between the tracts.
2. Regress the log number of commuters on the log travel time by public transit between the tracts, a fixed effect for the home tract, and a fixed effect for the work tract.
3. Regress the log number of commuters on the log travel time by public transit between the tracts, the log travel time by car between the tracts, a fixed effect for the home tract, and a fixed effect for the work tract.

In the regression table:

- Report each regression in a column.
- Report the independent variables in the rows.
- Report the number of observations.
- Do not report the values of the estimated fixed effects.

Answer the following questions about these regressions (roughly one paragraph each):

1. Describe the relationship documented by the first regression and discuss the economic mechanisms that might explain the finding.
2. Describe how the first regression relates to the data visualization in the binned scatterplot.
3. Discuss why the estimated coefficient on log travel time differs between the first and second regression specifications.
4. Describe how to interpret the two travel-time coefficients in the third regression specification.
5. Your friend suggests creating a same-tract dummy indicating that the home tract and work tract are the same tract and adding this to the regression. Explain why that is an infeasible suggestion in this context.
