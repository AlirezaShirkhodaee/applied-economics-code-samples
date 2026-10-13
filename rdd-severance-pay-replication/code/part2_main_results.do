/*------------------------------------------------------------------------------
							Define Required Macros
------------------------------------------------------------------------------*/
gl MONTH_THR = 36	
gl SEV_THR = 3 * 365
gl MONTH_LENGTH = 31
gl NONE_EMP_THR = 2 * 365
gl NONE_EMP = 20 * 7
gl SEV_XLINE = 35.5
gl SEV_MONTH_XLINE "xline(${SEV_XLINE}, lwidth(0.3) lcolor(gs4) lp(dash))"
gl GRAPH_A "sort mcolor(black) msize(medsmall)  m(O)  lcolor(black) lp(solid)"
gl GRAPH_B "sort mcolor(gs8)   msize(medsmall)  m(D)  lcolor(gs8) lp(dash)"
gl GRAPH_STYLE "xlabel(12(6)60) graphregion(color(white))" 
gl TWOWAY_OPT "sort color(gs7) lwidth(0.2)"
gl OUTPUT_FORMAT "pdf"
gl LEGEND_POSITION "position(6)"   
gl TABLE_FMT "cells(b(star fmt(%6.3f)) se(par fmt(%6.3f))) star(* 0.1 ** 0.05 *** 0.01)"
gl MGROUP "prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})"


/*------------------------------------------------------------------------------
                     Generate Variables for Cox and RD Regressions
------------------------------------------------------------------------------*/
* Categorize tenure
gen tenure_cat = ${MONTH_THR} + int((tenure - ${SEV_THR}) / ${MONTH_LENGTH}) if tenure >= ${SEV_THR}
replace tenure_cat = ${MONTH_THR} - 1 + int((tenure - ${SEV_THR} + 1) / ${MONTH_LENGTH}) if tenure < ${SEV_THR}
replace tenure_cat = . if tenure_cat < 13 | tenure_cat > 58

* Categorize employment months
gen emp_cat = ${MONTH_THR} + int((dempl5 - ${SEV_THR}) / ${MONTH_LENGTH}) if dempl5 >= ${SEV_THR}
replace emp_cat = ${MONTH_THR} - 1 + int((dempl5 - ${SEV_THR} + 1) / ${MONTH_LENGTH}) if dempl5 < ${SEV_THR}
replace emp_cat = . if emp_cat < 13 | emp_cat > 58

* Main regression variables
gen sp = (tenure >= ${SEV_THR})
gen eb = (dempl5 >= ${SEV_THR})

gen mw  = (dempl5 / 365) * 12
forvalues i = 2/4 {
    gen mw`i' = mw^`i'
}

gen jt  = (tenure / 365) * 12
forvalues i = 2/4 {
    gen jt`i' = jt^`i'
}

* Interaction terms
gen sp_jt_diff  = sp * (jt - ${MONTH_THR})
forvalues i = 2/4 {
    gen sp_jt_diff`i' = sp * (jt - ${MONTH_THR})^`i'
}

gen eb_mw_diff  = eb * (mw - ${MONTH_THR})
forvalues i = 2/4 {
    gen eb_mw_diff`i' = eb * (mw - ${MONTH_THR})^`i'
}

* Control covariates
gen age2 = age^2
gen log_wage0 = log(wage0)
gen log_wage02 = log_wage0^2

gen end_month = month(end)
gen end_year  = year(end)

gen tot_exper  = (experience + tenure) / 365
gen tot_exper2 = tot_exper^2

gen last_blue = (last_etyp == 2)
gen last_nonedur_dumm = (last_noneduration != 0)

* Weekly hazard-related variables
gen week_nondur = ceil(noneduration / 7)
gen censored_1 = (ne_start == 15887)
gen censored_2 = (ne_start + ne_duration >= 15887)
gen censored_yrs_2 = inrange(noneduration, ${NONE_EMP}, .)
gen censored_yrs_5 = inrange(ne_duration, 5*365, .)

* Count number of fires in each month-year for each firm
bysort benr end_year end_month: gen fired_num = _N

/*------------------------------------------------------------------------------
                            TABLE II: SURVIVAL ANALYSIS
------------------------------------------------------------------------------*/
gl main_specification sp eb jt jt2 jt3 mw mw2 mw3 sp_jt_diff sp_jt_diff2 ///
						sp_jt_diff3 eb_mw_diff eb_mw_diff2 eb_mw_diff3	

gl indep_vars_1 i.female i.married i.austrian i.bluecollar age  age2 ///
				log_wage0 log_wage02 i.end_year i.end_month  
					   
gl indep_vars_2 i.last_recall i.region i.industry i.last_job last_duration ///
				dg_size last_breaks i.education tot_exper tot_exper2 ///
				last_noneduration i.last_nonedur_dumm

{
    * Define failure event: individuals not censored
    gen failure = censored_1 != 1 & censored_yrs_2 != 1
    stset noneduration, failure(failure == 1)

    * Cox regression models
    stcox ${main_specification}, nohr
    eststo tab2_col1
    stcox ${main_specification} ${indep_vars_1}, nohr
    eststo tab2_col2
    stcox ${main_specification} ${indep_vars_1} ${indep_vars_2}, nohr
    eststo tab2_col3
    stcox ${main_specification} ${indep_vars_1} if fired_num >= 4, nohr
    eststo tab2_col4    

    * Export results to LaTeX
    local out_name = "Table_2"
    #d;
    esttab tab2_col1 tab2_col2 tab2_col3 tab2_col4 using "${TABLE_DIR}/`out_name'.tex", style(tex)     
        ${TABLE_FMT} nodep nonumbers label
        coeflabels(sp "Severance Pay" eb "Extended Benefits") 
        mtitles("\shortstack{\\No Controls\\(1)}" "\shortstack{\\Basic Controls\\(2)}" 
                "\shortstack{\\Full Controls\\(3)}" "\shortstack{$ \geq 4$ Layoffs\\by Firm\\(4)}") 
        keep(sp eb) collabels(none)
        stats(n, fmt(%20.0g) labels("Sample Size"))
        replace;
    #d cr 

    * Cleanup
    drop failure
    estimates drop _all
}

/*------------------------------------------------------------------------------
                            TABLE III: WAGE CHANGES
------------------------------------------------------------------------------*/
{
    * Define sample for wage growth regression
    gen in_sample = ne_start < 15887
    gen wage_g = log(ne_wage0) - log(wage0) if in_sample == 1
    
    * Wage growth regressions
    reg wage_g ${main_specification}, cluster(penr)
    eststo tab3_col1
    reg wage_g ${main_specification} ${indep_vars_1} ${indep_vars_2}, cluster(penr)
    eststo tab3_col2
    
    * Survival analysis for job duration
    gen failure_3 = censored_yrs_5 != 1 & censored_2 != 1
    gen next_dur = ne_duration
    replace next_dur = 5 * 365 if ne_duration > 5 * 365
    stset next_dur, failure(failure_3 == 1)

    * Cox models for job duration
    stcox ${main_specification}, nohr
    eststo tab3_col3
    stcox ${main_specification} ${indep_vars_1} ${indep_vars_2}, nohr
    eststo tab3_col4

    * Export results to LaTeX
    local out_name = "Table_3"
    #d;
    esttab tab3_col1 tab3_col2 tab3_col3 tab3_col4 using "${TABLE_DIR}/`out_name'.tex", style(tex)      
        cells(b(star fmt(%6.3f)) se(par fmt(%6.3f)))        
        stats(n, fmt(%20.0g) labels("Sample Size"))
        coeflabels(sp "Severance Pay" eb "Extended Benefits") 
        mgroups("\shortstack{\\ Dep. Variable: Change in Log Wage}" 
                "\shortstack{\\ Dep. Variable: Duration of Next Job}", 
                pattern(1 0 1 0) ${MGROUP})
        mtitles("\shortstack{No Controls\\(1)}" "\shortstack{Full Controls\\(2)}" 
                "\shortstack{No Controls\\(3)}" "\shortstack{Full Controls\\(4)}") 
        keep(sp eb) collabels(none)
        nodep nonumbers label 
        replace;
    #d cr

    * Cleanup
    drop wage_g in_sample failure_3 next_dur
    estimates drop _all
}

/*------------------------------------------------------------------------------
							FIGURE II: LAYOFF DISTRIBUTION
------------------------------------------------------------------------------*/

{
    * Count number of layoffs per tenure category
    bys tenure_cat: gen layoff_count = _N
    bys tenure_cat: gen obs_num = _n

    * Generate graph
    #d;
    twoway (connected layoff_count tenure_cat if obs_num == 1, ${GRAPH_A}),
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        ylabel(0(10000)40000)
        xtitle("Previous Job Tenure (Months)") 
        ytitle("Number of Layoffs");
    #d cr

    * Cleanup
    drop obs_num layoff_count 
    local out_name = "Fig_II"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
}

/*------------------------------------------------------------------------------
                      FIGURE IIIa: AVERAGE NUMBER OF JOBS
------------------------------------------------------------------------------*/

{
    * Compute the number of continuous employment spells
    gen emp_num = last_breaks
    bys tenure_cat: egen jobs_num_mean = mean(emp_num)
    bys tenure_cat: gen obs_num = _n 

    * Generate graph
    #d;
    twoway (scatter jobs_num_mean tenure_cat if obs_num == 1, ${GRAPH_A})
           (lfit jobs_num_mean tenure_cat if obs_num == 1 & tenure >= ${SEV_THR}, ${TWOWAY_OPT})
           (lfit jobs_num_mean tenure_cat if obs_num == 1 & tenure < ${SEV_THR},  ${TWOWAY_OPT}),
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        legend(off)
        xtitle("Previous Job Tenure (Months)") 
        ytitle("Mean Number of Jobs");
    #d cr

    * Cleanup
    drop obs_num jobs_num_mean emp_num
    local out_name = "Fig_IIIa"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
}

/*------------------------------------------------------------------------------
                      FIGURE IIIb: MEAN ANNUAL WAGE
------------------------------------------------------------------------------*/

{
    * Compute annual wage (monthly wage × 12) in 1000s of Euros
    gen annual_wage = (wage0 * 12) / 1000
    bys tenure_cat: egen annual_wage_mean = mean(annual_wage)
    bys tenure_cat: gen obs_num = _n if wage0 != .

    * Generate graph
    #d;
    twoway (scatter annual_wage_mean tenure_cat if obs_num == 1, ${GRAPH_A})
           (lfit annual_wage_mean tenure_cat if obs_num == 1 & tenure >= ${SEV_THR}, ${TWOWAY_OPT})
           (lfit annual_wage_mean tenure_cat if obs_num == 1 & tenure < ${SEV_THR}, ${TWOWAY_OPT}),
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        legend(off)
        xtitle("Previous Job Tenure (Months)") 
        ytitle("Mean Annual Wage (Euro × 1000)");
    #d cr

    * Cleanup
    drop obs_num annual_wage annual_wage_mean
    local out_name = "Fig_IIIb"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
}

/*------------------------------------------------------------------------------
					FIGURE V: MEAN NONEMPLOYMENT DURATION
------------------------------------------------------------------------------*/

{
    * Identify observations to include in the graph
    gen in_graph = noneduration <= ${NONE_EMP_THR}
    bys tenure_cat: egen nonduration_mean = mean(noneduration) if in_graph == 1
    bys tenure_cat in_graph: gen obs_num = _n 
    gen show = in_graph == 1 & obs_num == 1

    * Generate graph
    #d;
    twoway (scatter nonduration_mean tenure_cat if show == 1, ${GRAPH_A})
           (qfit nonduration_mean tenure_cat if show == 1 & tenure >= ${SEV_THR}, ${TWOWAY_OPT})
           (qfit nonduration_mean tenure_cat if show == 1 & tenure < ${SEV_THR}, ${TWOWAY_OPT}),
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        legend(off)
        xtitle("Previous Job Tenure (Months)") 
        ytitle("Mean Nonemployment Duration (days)");
    #d cr

    * Cleanup
    drop in_graph obs_num show nonduration_mean
    local out_name = "Fig_V"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
}
/*------------------------------------------------------------------------------
                            FIGURE VI: JOB FINDING HAZARD
------------------------------------------------------------------------------*/

{
    * Define failure event and censor duration
    gen failure = censored_yrs_2 != 1 & censored_1 != 1
    gen n_d_censored = noneduration
    replace n_d_censored = 140 if noneduration >= 140

    * Set survival analysis
    stset n_d_censored, failure(failure == 1)
    stcox ib35.tenure_cat eb mw mw2 mw3 eb_mw_diff eb_mw_diff2 eb_mw_diff3

    * Predict hazard coefficients
    gen jt_coeffs = .
    forvalues i = 13(1)58 {
        replace jt_coeffs = e(b)[1,"`i'.tenure_cat"] if tenure_cat == `i'
    }

    * Generate graph
    bys tenure_cat: gen obs_num = _n
    #d;
    twoway (scatter jt_coeffs tenure_cat if obs_num == 1, ${GRAPH_A})
           (qfit jt_coeffs tenure_cat if obs_num == 1 & tenure >= ${SEV_THR}, ${TWOWAY_OPT}) 
           (qfit jt_coeffs tenure_cat if obs_num == 1 & tenure < ${SEV_THR},  ${TWOWAY_OPT}), 
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        legend(off)
        xtitle("Previous Job Tenure (Months)") 
        ytitle("Average Daily Job Finding Hazard in First 20 Weeks"); 
    #d cr

    * Cleanup
    drop obs_num jt_coeffs failure n_d_censored
    local out_name = "Fig_VI"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
}

/*------------------------------------------------------------------------------
				  FIGURE VII: JOB FINDING HAZARD BY SEVERANCE
------------------------------------------------------------------------------*/

{
    * Define restricted sample and severance pay eligibility
    gen restr_sample = dempl5 - tenure >= ${MONTH_LENGTH}
    gen sev_receiver = 1 if inrange(tenure_cat, 33, 35) & restr_sample == 1
    replace sev_receiver = 0 if inrange(tenure_cat, 36, 38) & restr_sample == 1

    * Define failure event for survival analysis
    gen failure = censored_1 != 1
    stset week_nondur if restr_sample == 1, failure(failure == 1)

    * Generate hazard estimates
    sts gen haz_sev_1 = h if sev_receiver == 1
    sts gen haz_sev_0 = h if sev_receiver == 0

    * Generate graph
    bys week_nondur sev_receiver: gen obs_num = _n if restr_sample != 0
    gen show = restr_sample == 1 & obs_num == 1
    #d;
    twoway (connected haz_sev_1 week_nondur if show == 1 & week_nondur <= 30, ${GRAPH_A})
           (connected haz_sev_0 week_nondur if show == 1 & week_nondur <= 30, ${GRAPH_B}),
        xline(20.5)
        ${GRAPH_STYLE}
        xlabel(0(10)30)
        legend(on order(2 "No Severance" 1 "Severance") col(2) ${LEGEND_POSITION})
        xtitle("Weeks Elapsed since Job Loss") 
        ytitle("Weekly Job Finding Hazard");
    #d cr

    * Cleanup
    drop obs_num haz_sev_1 haz_sev_0 restr_sample sev_receiver failure show
    local out_name = "Fig_VII"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
}

/*------------------------------------------------------------------------------
                   FIGURE VIIIa: MEAN NONEMPLOYMENT DURATION
------------------------------------------------------------------------------*/

{
    * Identify observations for the graph
    gen in_graph = noneduration <= ${NONE_EMP_THR}
    bys emp_cat: egen nonduration_mean = mean(noneduration) if in_graph == 1
    bys emp_cat in_graph: gen obs_num = _n 
    gen show = in_graph == 1 & obs_num == 1

    * Generate graph
    #d;
    twoway (scatter nonduration_mean emp_cat if show == 1, ${GRAPH_A})
           (qfit nonduration_mean emp_cat if show == 1 & dempl5 >= ${SEV_THR}, ${TWOWAY_OPT})
           (qfit nonduration_mean emp_cat if show == 1 & dempl5 < ${SEV_THR}, ${TWOWAY_OPT}),
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        legend(off)
        xtitle("Months Employed in Past Five Years") 
        ytitle("Mean Nonemployment Duration (days)"); 
    #d cr

    * Cleanup
    drop in_graph obs_num show nonduration_mean
    local out_name = "Fig_VIIIa"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
}

/*------------------------------------------------------------------------------
			  FIGURE VIIIb: JOB FINDING HAZARD BY EMPLOYMENT CATEGORY
------------------------------------------------------------------------------*/

{
    * Define failure event for survival analysis
    gen failure = censored_1 != 1 & censored_yrs_2 != 1
    stset noneduration, failure(failure == 1)

    * Cox proportional hazards model
    stcox sp ib35.emp_cat jt jt2 jt3 sp_jt_diff sp_jt_diff2 sp_jt_diff3

    * Predict hazard coefficients
    gen mw_coeffs = .
    forvalues i = 15(1)57 {
        replace mw_coeffs = e(b)[1,"`i'.emp_cat"] if emp_cat == `i'
    }

    * Generate graph
    bys emp_cat: gen obs_num = _n
    #d;
    twoway (scatter mw_coeffs emp_cat if obs_num == 1, ${GRAPH_A})
           (qfit mw_coeffs emp_cat if obs_num == 1 & dempl5 >= ${SEV_THR}, ${TWOWAY_OPT})
           (qfit mw_coeffs emp_cat if obs_num == 1 & dempl5 < ${SEV_THR}, ${TWOWAY_OPT}),
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        legend(off)
        xtitle("Months Employed in Past Five Years") 
        ytitle("Average Daily Job Finding Hazard in First 20 Weeks"); 
    #d cr

    * Cleanup
    drop obs_num mw_coeffs failure
    local out_name = "Fig_VIIIb"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
}

/*------------------------------------------------------------------------------
			  FIGURE IX: WEEKLY JOB FINDING HAZARD BY UI DURATION
------------------------------------------------------------------------------*/

{
    * Define restricted sample and UI benefit eligibility
    gen restr_sample = dempl5 - tenure >= ${MONTH_LENGTH}
    gen ui_receiver = 1 if inrange(emp_cat, 33, 35) & restr_sample == 1
    replace ui_receiver = 0 if inrange(emp_cat, 36, 38) & restr_sample == 1

    * Define failure event for survival analysis
    gen failure = censored_1 != 1
    stset week_nondur, failure(failure == 1)

    * Generate hazard estimates
    sts gen haz_sev_1 = h if ui_receiver == 1
    sts gen haz_sev_0 = h if ui_receiver == 0

    * Generate graph
    bys week_nondur ui_receiver restr_sample: gen obs_num = _n
    gen show = restr_sample == 1 & obs_num == 1
    #d;
    twoway (connected haz_sev_1 week_nondur if show == 1 & week_nondur <= 30, ${GRAPH_A})
           (connected haz_sev_0 week_nondur if show == 1 & week_nondur <= 30, ${GRAPH_B}),
        xline(20.5)
        xlabel(0(10)30)
        legend(on order(2 "20 Weeks of UI" 1 "30 Weeks of UI") col(2) ${LEGEND_POSITION})
        xtitle("Weeks Elapsed since Job Loss")  
        ytitle("Weekly Job Finding Hazard");
    #d cr

    * Cleanup
    drop obs_num haz_sev_1 haz_sev_0 restr_sample ui_receiver show failure
    local out_name = "Fig_IX"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
}

/*------------------------------------------------------------------------------
						FIGURE Xa: WAGE GROWTH BY TENURE
------------------------------------------------------------------------------*/

{
    * Identify employed individuals
    gen in_graph = indnempl == 1

    * Compute average wage growth by tenure category
    bys tenure_cat: egen wage_g = mean(log(ne_wage0) - log(wage0)) if in_graph == 1
    bys tenure_cat in_graph: gen obs_num = _n 
    gen show = in_graph == 1 & obs_num == 1

    * Generate graph
    #d;
    twoway (scatter wage_g tenure_cat if show == 1, ${GRAPH_A})
           (lfit wage_g tenure_cat if show == 1 & tenure >= ${SEV_THR}, ${TWOWAY_OPT})
           (lfit wage_g tenure_cat if show == 1 & tenure < ${SEV_THR}, ${TWOWAY_OPT}),
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        legend(off)
        xtitle("Previous Job Tenure (Months") 
        ytitle("Wage Growth"); 
    #d cr

    * Cleanup
    drop in_graph show obs_num wage_g
    local out_name = "Fig_Xa"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
}

/*------------------------------------------------------------------------------
					FIGURE Xb: JOB FINDING HAZARD BY TENURE
------------------------------------------------------------------------------*/

{
    * Identify employed individuals and categorize duration
    gen in_graph = indnempl == 1
    gen ne_dur_cat = int(ne_duration / ${MONTH_LENGTH})

    * Define failure event for survival analysis
    gen failure = censored_2 != 1
    stset ne_duration if (in_graph == 1), failure(failure == 1)

    * Cox proportional hazards model
    stcox ib35.tenure_cat

    * Predict hazard coefficients
    gen jt_coeffs = .
    forvalues i = 13(1)58 {
        replace jt_coeffs = e(b)[1,"`i'.tenure_cat"] if tenure_cat == `i'
    }

    * Generate graph
    bys tenure_cat: gen obs_num = _n
    #d;
    twoway (scatter jt_coeffs tenure_cat if obs_num == 1, ${GRAPH_A})
           (qfit jt_coeffs tenure_cat if obs_num == 1 & tenure >= ${SEV_THR}, ${TWOWAY_OPT})
           (qfit jt_coeffs tenure_cat if obs_num == 1 & tenure < ${SEV_THR}, ${TWOWAY_OPT}),
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        legend(off)
        xtitle("Months Employed in Past Five Years") 
        ytitle("Average Daily Job Finding Hazard in First 20 Weeks"); 
    #d cr

    * Cleanup
    drop obs_num jt_coeffs in_graph ne_dur_cat failure
	local out_name = "Fig_Xb"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
}




