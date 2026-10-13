# Task: Severance pay and job finding (replication)

*Originally a timed data task. The questions and data description are reproduced below.*

The assignment uses the data of Card, Chetty and Weber (2007) to replicate and discuss their results. The paper analyzes the effects of severance payments on the job-finding rate of unemployed individuals, using Austrian data and a regression discontinuity (RD) design based on tenure discontinuities in severance payments. The aims are to:

1. replicate the main results independently,
2. learn and assess the validity of the main empirical strategy used in the paper (RD), and
3. become acquainted with hazard models.

## Data

- `sample_75_02.dta`: the main sample. Variables have labeled names. The personal identifier is `penr`.
- `work_history.dta`: work-history data, to be merged with the main sample.

## Questions

1. Start with `sample_75_02.dta` and merge it with the work-history data (`work_history.dta`).
2. Research and describe precisely the institutional background to demonstrate the validity of the identification.
3. Replicate the main RD figures of the paper, and assess the quality of the RD design. What additional tests can you think of or perform that have not been shown in the paper? (Lee and Lemieux's roadmap for RD implementation is a useful reference.)
4. What are the pros and cons of using a proportional hazard model here? Try to replicate the results of the hazard model used in the paper.

## References

- Card, David, Raj Chetty, and Andrea Weber (2007). "Cash-on-Hand and Competing Models of Intertemporal Behavior: New Evidence from the Labor Market." *Quarterly Journal of Economics*, 122(4): 1511-1560.
- Lee, David S., and Thomas Lemieux (2010). "Regression Discontinuity Designs in Economics." *Journal of Economic Literature*, 48(2): 281-355.
