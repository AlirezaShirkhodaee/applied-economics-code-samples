# Task: Structural estimation of auction models (replication)

*Originally a timed data task. The questions and data description are reproduced below.*

The assignment replicates parts of Bajari and Hortaçsu (2005), a paper on experimental auctions: most of the computations in Sections II through IV of the paper, plus some further calculations.

> Bajari, Patrick, and Ali Hortaçsu (2005). "Are Structural Estimates of Auction Models Reasonable? Evidence from Experimental Data." *Journal of Political Economy*, 113(4): 703-741.

## Data

The data set `auctions.csv` comes from three auction experiments originally analyzed by Dyer, Kagel, and Levin (1989). The initial runs of the experiments are excluded, leaving the observations that Bajari and Hortaçsu use in the paper. The data section of the paper describes the structure of the data set.

Note: the number of observations reported in Table 1 of the paper (N = 414) does not match the number of observations in the data set (N = 408). The number reported in the table is the one that is wrong. The data set with 408 observations should replicate Table 1 with only a few differences of 0.01.

## Questions

### Section II

1. Reproduce the two plots in Figure 1 of the paper. Compute and store the difference between the observed bids and the Nash equilibrium bids. What are the main differences across the observed and Nash equilibrium bids?
2. Using the bids within each experiment, compute the empirical CDF for each type of bid (N = 3, N = 6). Use the evenly spaced grid {0.01, 0.02, 0.03, ..., 29.99, 30.00} to evaluate the empirical CDF. For each auction size, plot the empirical CDFs of the three experiments in the same panel. Is the distribution of bids much different across experiments?
3. Use the appropriate empirical CDF to compute the expected profit and the optimization error (defined in equations 3 and 4) for each bid.
4. Using the above calculations, reproduce Table 1. The differences from your calculations should match Table 1 to rounding error.

### Section III

1. Using Silverman's rule of thumb for the bandwidth (define this rule of thumb), compute an estimate of g(b) for each bid in the data set. For a visualization of the bid data, provide a plot for these bids for each bid type.
2. For each bid in the data set, estimate the CDF of bids G(b) using the empirical CDF, Ĝ(b). Do this separately for the N = 3 bids and the N = 6 bids. Compute these estimates two ways, as discussed in footnote 14:
   1. pool the bids across experiments and use this "full" data set to compute the density and CDF estimates;
   2. use the data within each experiment to compute the density and CDF estimates.

   In either case, use Silverman's rule of thumb for the density estimates.
3. Use equation (9) and the previous calculations to compute two estimates for each valuation: one based on the N = 3 bid data and one based on the N = 6 bid data. Summarize these estimates with two types of plots:
   1. For each auction size, a scatterplot of the estimated valuation versus the true valuation, with the true valuation on the horizontal axis and the 45-degree line.
   2. The histogram of the true valuations and the two estimates of the valuations (that is, reproduce Figure 2 in the paper).
4. For each way of estimating the CDF and pdf in (2), compute the L1 and L2 norm.

### Section IV (risk aversion)

Depending on the method used to compute percentiles, results may differ slightly from the ones presented in the paper.

1. Compute and store the 0 through 100 integer percentiles of the bid data. At each of these percentiles, compute CDF and pdf estimates. Use these percentiles to construct the term in brackets on the right-hand side of equation (15).
2. Estimate θ using equation (15) and ordinary least squares using (i) the full sample of percentiles, (ii) the trimmed sample containing percentiles 5 through 95, and (iii) the trimmed sample containing percentiles 25 through 75. Report point estimates and 95 percent confidence intervals for the estimate of risk aversion.
3. Perform the alternative verification of the risk-aversion hypothesis outlined on the bottom half of page 721.
4. Use the point estimate of risk aversion obtained from the trimmed sample of percentiles 25 through 75 to compute two estimates for each valuation (one for N = 3, one for N = 6).
   1. As for the risk-neutral case, provide a scatterplot of the estimated valuation versus the true valuation, with the true valuation on the horizontal axis and the 45-degree line.
   2. Plot the histogram of the true valuations and the two estimates of the valuations (that is, reproduce Figure 2 in the paper).
   3. Compute the L1 and L2 norm using these new estimates for the valuation.

### Final question

What did you learn from this replication exercise? Now that you have done this replication, what would you have done differently in the paper, or what alternative directions would you have tried?
