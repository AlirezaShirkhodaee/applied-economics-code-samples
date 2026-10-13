	/*--------------------------------------------------------------------------
									Define Required Macros
	--------------------------------------------------------------------------*/
	cd "${PROJECT_DIR}"
	use "${DATA_DIR}/sample_75_02.dta", clear
	merge 1:1 penr file using "${DATA_DIR}/work_history.dta"
	drop _merge

	/*--------------------------------------------------------------------------
									Define Macros
	--------------------------------------------------------------------------*/
	gl TENURE_LOW = 365			// Tenure lower bound equals 1 year.
	gl TENURE_HIGH = 5 * 365	// Tenure upper bound equals 5 years.
	gl PERIOD_START = 1981		// Start of job separations period
	gl PERIOD_END = 2001		// End of job separations period
	gl PERIOD_BENCH = 1994		// Benchmark year in Table I of the paper
	
	/*--------------------------------------------------------------------------
								Exclusion Criteria
	----------------------------------------------------------------------------

	The dataset is filtered based on the following exclusion criteria:

	- Age restriction: Individuals younger than 20 or older than 50 at the time 
	  of job termination are excluded to avoid special programs for older 
	  workers.

	- Construction workers: These individuals are excluded as they are covered 
	  by a different set of severance pay regulations.

	- Voluntary quitters: Individuals who voluntarily quit their jobs are 
	  eliminated since they are ineligible for severance pay.

	- Recalled workers: Those who were recalled to their prior firms are 
	  excluded to remove temporary layoffs, as they may not be actively 
	  searching for a new job.

	- Work history requirement: Only individuals who worked at their previous 
	  firms for strictly between 1 and 5 years, and who worked strictly between 
	  1 and 5 of the past 5 years, are included to focus on observations around 
	  the discontinuities of interest.

	- Job separation period: Only job separations that resulted in a UI claim 
	  between 1981 and 2001 are considered to maintain consistency in the study 
	  period.

	--------------------------------------------------------------------------*/

	* Step 1: Exclude individuals based on age criteria
	gen to_drop_age = (age < 20 | age > 50)
	count if to_drop_age == 1
	di "Percentage excluded due to age criteria: " %9.1f r(N) / _N * 100 "%"

	* Step 2: Exclude construction workers (iconstruction == 1)
	gen to_drop_construction = (iconstruction == 1)
	count if to_drop_construction == 1
	di "Percentage excluded due to being a construction worker: " %9.1f r(N) / _N * 100 "%"

	* Step 3: Exclude voluntary quitters
	gen to_drop_voluntary = (volquit == 1)
	count if to_drop_voluntary == 1
	di "Percentage excluded due to voluntary quitters ineligible for severance pay: " %9.1f r(N) / _N * 100 "%"

	* Step 4: Exclude individuals recalled to prior firms
	gen to_drop_recall = (recall == 1)
	count if to_drop_recall == 1
	di "Percentage excluded due to recall to prior firm: " %9.1f r(N) / _N * 100 "%"

	* Step 5: Exclude individuals outside the specified job separation period
	gen end_yr = year(end)
	gen to_drop_time = !inrange(end_yr, ${PERIOD_START}, ${PERIOD_END})
	count if to_drop_time == 1
	di "Percentage excluded due to job separation outside 1981-2001: " %9.1f r(N) / _N * 100 "%"
	
	* Step 6a: Exclude individuals with less than 1 year of tenure
	gen tenure = end - start + 1
	gen to_drop_tenure_low = (tenure < ${TENURE_LOW}) | (dempl5 < ${TENURE_LOW})
	count if to_drop_tenure_low == 1
	di "Percentage excluded due to tenure less than 1 year: " %9.1f (r(N) / _N * 100) "%"

	* Step 6b: Exclude individuals with more than 5 years of tenure
	gen to_drop_tenure_high = (tenure > ${TENURE_HIGH} - 1) | (dempl5 > ${TENURE_HIGH} - 1)
	count if to_drop_tenure_high == 1
	di "Percentage excluded due to tenure more than 5 years: " %9.1f (r(N) / _N * 100) "%"

	/*--------------------------------------------------------------------------
									Table I
	--------------------------------------------------------------------------*/
	
	* Define the three groups
	gen group1 = (!to_drop_age) & (end_yr == ${PERIOD_BENCH})
	gen group2 = !(to_drop_age | to_drop_time | to_drop_tenure_low | to_drop_voluntary)
	gen group3 = !(to_drop_age | to_drop_construction | to_drop_voluntary | ///
		to_drop_recall | to_drop_time | to_drop_tenure_low | to_drop_tenure_high)
		
	* Define variables
	local vars age female married austrian bluecollar tenure dempl5 ///
		wage0 firms noneduration indnempl

	* Open a .tex file for writing
	cap file close myfile
	file open myfile using "${TABLE_DIR}/Table_1.tex", write replace

	* Write LaTeX table structure
	file write myfile "\begin{table}[h]" _n
	file write myfile "\centering" _n
	file write myfile "\caption{Summary Statistics}" _n
	file write myfile "\begin{tabular}{lccc}" _n
	file write myfile "\hline\hline" _n
	file write myfile "Variable & All Workers (1994) & All & Estimation Sample" _n
	file write myfile "\hline" _n

	* Generate summary statistics
	foreach var in `vars' {
		quietly sum `var' if group1 == 1
		local col1 = r(mean)

		quietly sum `var' if group2 == 1
		local col2 = r(mean)

		quietly sum `var' if group3 == 1
		local col3 = r(mean)

		file write myfile "`var' & `col1' & `col2' & `col3'" _n
	}

	* Sample sizes
	count if group1 == 1
	local n1 = r(N)
	count if group2 == 1
	local n2 = r(N)
	count if group3 == 1
	local n3 = r(N)

	* Write LaTeX table structure
	file write myfile "\hline" _n
	file write myfile "Sample Size & `n1' & `n2' & `n3'" _n
	file write myfile "\hline\hline" _n
	file write myfile "\end{tabular}" _n
	file write myfile "\label{tab:summary}" _n
	file write myfile "\end{table}" _n

	* Close file
	file close myfile
	
	/*--------------------------------------------------------------------------
									Data Cleaning
	--------------------------------------------------------------------------*/

	* Apply all exclusion criteria
	drop if to_drop_age == 1
	drop if to_drop_construction == 1
	drop if to_drop_voluntary == 1
	drop if to_drop_recall == 1
	drop if to_drop_time == 1
	drop if to_drop_tenure_low == 1
	drop if to_drop_tenure_high == 1

	* Cleanup temporary variables
	drop end_yr to_drop_*

