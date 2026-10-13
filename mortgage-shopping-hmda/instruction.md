# Task: Mortgage shopping behavior

*Originally a timed data task. The questions and data description are reproduced below.*

The purpose of this task is to analyze mortgage shopping behavior in the United States.

## Data

Home Mortgage Disclosure Act (HMDA) data from the Consumer Financial Protection Bureau (CFPB) for the year 2020:
<https://ffiec.cfpb.gov/data-publication/dynamic-national-loan-level-dataset/2020>

The data contain mortgage-level applications collected under HMDA, covering all United States mortgage applications in the year. They include demographic information on the borrowers, such as ethnicity, race, income, and gender, together with loan- and borrower-level information: lender identification, application outcome, loan type, loan purpose, loan size, and location at the census-tract level.

## Questions

1. Restrict the sample to: the top 20 metropolitan areas by mortgage origination; conventional, first-lien mortgages originated for purchases of owner-occupied single-family homes with closed-end credit. Generate a categorical variable to define a borrower's race. Restrict the sample to four groups: White non-Hispanic/non-Latino, Asian, Black, and Hispanic/Latino borrowers. Drop all other races. Hispanic/Latino borrowers should also include White borrowers who identify as Hispanic/Latino. Define a market as MSA × Race. For each race, provide overall summary statistics of rate spreads, loan-to-value ratio, and fee shares (defined as the ratio between total loan costs and loan amount). Plot distributions of rate spreads and fee shares by race. Comment on patterns.

2. For each market, compute the lenders' shares. Do you think that this measure soundly represents lenders' representativeness? If not, can you think of any reasons why? *Bonus:* propose a new variable.

3. Using this within-market share variable (or any other similar variable), show some analysis of the determinants of mortgage prices and the determinants of rejection. Describe carefully the chosen econometric methodologies. Interpret results.

4. Relationship between lenders' market shares and prices at a market level. Estimate a demand function for lenders' market shares. Show results. Why are the estimates biased?

5. *Bonus question.* Demand estimation of lenders. Can you think of ways to mitigate the bias in estimating the relationship between lenders' market shares and prices at a market level?
