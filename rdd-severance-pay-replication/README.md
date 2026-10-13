# Severance pay and job finding: an RD replication

*Originally a timed data task. The task is described in [instruction.md](instruction.md).*

## Question

Do severance payments and extended unemployment benefits delay re-employment, and do they improve the quality of the next job? This project replicates and extends Card, Chetty and Weber (2007) on Austrian administrative data.

## Method

- **Regression discontinuity.** Severance pay is due after 36 months of tenure, and extended benefits after 36 months of employment in the past five years. Both thresholds create discontinuities in eligibility.
- **Validity checks.** Frequency of layoffs around the threshold, and continuity of firm size, industry, education, and previous job and nonemployment spells.
- **Cox proportional hazard models** for the job-finding hazard, which handle right-censored spells.
- **Bandwidth selection** with `rdrobust` across polynomial orders, selection methods and kernels.

## Headline result

Severance-pay eligibility lowers the job-finding hazard by about 12.5% and extended benefits by about 9.3% (Cox coefficients of -0.125 and -0.093 without controls; -0.092 and -0.062 with full controls). Neither has a significant effect on wage growth or on the duration of the next job.

![Mean nonemployment duration by previous job tenure](output/figures/nonemployment_duration_rd.png)

## Layout

```
code/
  main.do                     master file: paths, packages, runs parts 1 to 3
  part1_data_cleaning.do      merge, sample restrictions, Table 1
  part2_main_results.do       RD figures, Cox models, Tables 2 and 3
  part3_additional_tests.do   covariate balance figures, bandwidth selection
data/                         not included (see data/README.md)
output/tables/                Table_1.tex, Table_2.tex, Table_3.tex
output/figures/               figures written by the do-files (PDF)
report/report.pdf             full write-up
```

## How to run

1. Place `sample_75_02.dta` and `work_history.dta` in `data/`.
2. Start Stata in this folder (or `cd` to it) and run:

   ```stata
   do code/main.do
   ```

`main.do` takes the project root from the working directory, so no path needs editing. It installs `estout` and `rdrobust` from SSC if they are missing, creates the output folders, and runs the three parts in order. Stata 17 or later is recommended.

## Data availability

The data are not publicly available and are not included here. See [data/README.md](data/README.md).

The figure above is taken from the report. The remaining figures are regenerated in `output/figures/` when the code is run.

## References

- Card, D., R. Chetty, and A. Weber (2007). "Cash-on-Hand and Competing Models of Intertemporal Behavior: New Evidence from the Labor Market." *Quarterly Journal of Economics*, 122(4): 1511-1560.
- Lee, D. S., and T. Lemieux (2010). "Regression Discontinuity Designs in Economics." *Journal of Economic Literature*, 48(2): 281-355.

## Contact

Alireza Shirkhodaee · ar.shirkhodaee@gmail.com
