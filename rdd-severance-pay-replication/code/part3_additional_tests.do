/*------------------------------------------------------------------------------
							Define Required Macros
------------------------------------------------------------------------------*/
global MONTH_THR 36
global SEV_DAY_XLINE "xline(${SEV_THR}, lwidth(0.3) lcolor(gs4) lp(dash))"
global GRAPH_C "sort mcolor(black) msize(small) m(O) lcolor(gs8) lp(solid)"
global GRAPH_COLOR "graphregion(fcolor(white))"
global GRAPH_SIZE "xsize(16) ysize(8)"


/*------------------------------------------------------------------------------
							Firm Size Graphs
------------------------------------------------------------------------------*/

local firm_sizes "5 15 50 200 500 1000"
local i = 1
foreach size of local firm_sizes {
    bys tenure_cat: egen firm_size_`size'_count = total(firms`i')
    bys tenure_cat: gen obs_num = _n
    
    #d;
    twoway (connected firm_size_`size'_count tenure_cat if obs_num == 1, ${GRAPH_C}),
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        legend(off)
        xtitle("Previous Job Tenure (Months)")
        ytitle("Number of Layoffs")
        subtitle("Firm Size `size'")
        name(Firm_Size_`size', replace);
    #d cr
    
    drop obs_num firm_size_`size'_count
    local out_name "Firm_size_`size'"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
	local i = `i' + 1
}


gr combine Firm_Size_5 Firm_Size_15 Firm_Size_50 Firm_Size_200 Firm_Size_500 ///
	Firm_Size_1000, col(3) ${GRAPH_COLOR} ${GRAPH_SIZE}

gr export "${GRAPH_DIR}/Firm_size.${OUTPUT_FORMAT}", replace

/*------------------------------------------------------------------------------
							Industry Graphs
------------------------------------------------------------------------------*/
local industries `" "Agriculture and Mining" "Manufacture" "Sales" "Hotel" "Transport" "Service" "'
tab industry, gen(industry)
local i = 1
foreach industry of local industries {
    bys tenure_cat: egen industry_`i'_count = total(industry`i')
    bys tenure_cat: gen obs_num = _n
    
    #d;
    twoway (connected industry_`i'_count tenure_cat if obs_num == 1, ${GRAPH_C}),
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        legend(off)
        xtitle("Previous Job Tenure (Months)")
        ytitle("Number of Layoffs")
        subtitle("`industry'")
        name(Industry_`i', replace);
    #d cr
    
    drop obs_num industry`i' industry_`i'_count
    local out_name "Industry_`industry'"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
    local i = `i' + 1
}


gr combine Industry_1 Industry_2 Industry_3 Industry_4 Industry_5 Industry_6, ///
    col(3) ${GRAPH_COLOR} ${GRAPH_SIZE}

gr export "${GRAPH_DIR}/Industry.${OUTPUT_FORMAT}", replace

/*------------------------------------------------------------------------------
							Education Level Graphs
------------------------------------------------------------------------------*/
tab education, gen(education)
local educ_levels `""Compulsory or Less" "Apprenticeship" "Middle School" "High School" "Vocational High School" "University" "'
local i = 1
foreach educ of local educ_levels {
    bys tenure_cat: egen education_`i'_count = total(education`i')
    bys tenure_cat: gen obs_num = _n
    
    #d;
    twoway (connected education_`i'_count tenure_cat if obs_num == 1, ${GRAPH_C}),
        ${SEV_MONTH_XLINE}
        ${GRAPH_STYLE}
        legend(off)
        xtitle("Previous Job Tenure (Months)")
        ytitle("Number of Layoffs")
        subtitle("`educ'")
        name(Education_`i', replace);
    #d cr
    
    drop obs_num education`i' education_`i'_count
    local out_name "Education_`educ'"
    gr export "${GRAPH_DIR}/`out_name'.${OUTPUT_FORMAT}", replace
    local i = `i' + 1
}

gr combine Education_1 Education_2 Education_3 Education_4 Education_5 Education_6, ///
    col(3) ${GRAPH_COLOR} ${GRAPH_SIZE}

gr export "${GRAPH_DIR}/Education.${OUTPUT_FORMAT}", replace

/*------------------------------------------------------------------------------
						Previous Nonemployment Duration Graphs
------------------------------------------------------------------------------*/
bys tenure_cat: egen last_noneduration_mean = mean(last_noneduration) if last_noneduration <= ${NONE_EMP_THR}
bys tenure_cat: gen obs_num = _n if last_noneduration <= ${NONE_EMP_THR}

#d;
twoway (scatter last_noneduration_mean tenure_cat if obs_num == 1, ${GRAPH_A})
       (qfit last_noneduration_mean tenure_cat if last_noneduration <= ${NONE_EMP_THR} & tenure > ${SEV_THR}, ${TWOWAY_OPT})
       (qfit last_noneduration_mean tenure_cat if last_noneduration <= ${NONE_EMP_THR} & tenure < ${SEV_THR}, ${TWOWAY_OPT}),
    ${SEV_MONTH_XLINE} 
    ${GRAPH_STYLE}
    legend(off)
    xtitle("Previous Job Tenure (Months)")
    ytitle("Mean of Last Nonemployment Duration (days)");
#d cr

drop obs_num last_noneduration_mean
gr export "${GRAPH_DIR}/Last_Nondur.${OUTPUT_FORMAT}", replace

/*------------------------------------------------------------------------------
						Previous Tenure Duration Graphs
------------------------------------------------------------------------------*/
bys tenure_cat: egen last_tenure_mean = mean(last_duration)
bys tenure_cat: gen obs_num = _n

#d;
twoway (scatter last_tenure_mean tenure_cat if obs_num == 1, ${GRAPH_A})
       (qfit last_tenure_mean tenure_cat if tenure > ${SEV_THR}, ${TWOWAY_OPT})
       (qfit last_tenure_mean tenure_cat if tenure < ${SEV_THR}, ${TWOWAY_OPT}),
    ${SEV_MONTH_XLINE} 
    ${GRAPH_STYLE}
    legend(off)
    xtitle("Previous Job Tenure (Months)")
    ytitle("Mean of Last Job Tenure (days)");
#d cr

drop obs_num last_tenure_mean
gr export "${GRAPH_DIR}/Last_Tenure.${OUTPUT_FORMAT}", replace


/*------------------------------------------------------------------------------
				Optimal Bandwidth for Local Linear Regressions
------------------------------------------------------------------------------*/
* Loop over polynomial orders, bandwidth selection methods, and kernels

local polynomials = "1 2 3"
* e.g., local linear (p=1), quadratic (p=2), cubic (p=3)

local methods     = "msetwo certwo"  
* msetwo:  Minimizes MSE using a bias-corrected approach
* certwo:  Minimizes coverage error rate

local kernels     = "uniform triangular"

capture file close mylog
file open mylog using "${TABLE_DIR}/bw_results.txt", write text replace

file write mylog "Bandwidth Selection Results (rdrobust)" _n
file write mylog "------------------------------------------------------------" _n
file write mylog "Polynomial | Method   | Kernel     |  h_left  |  h_right" _n
file write mylog "------------------------------------------------------------" _n

* For each polynomial order, method, and kernel, run rdrobust and record output
foreach p of local polynomials {
    foreach m of local methods {
        foreach k of local kernels {
            quietly rdrobust noneduration tenure_cat, c(36) p(`p') bwselect(`m') kernel(`k') masspoints("off")
            * The chosen bandwidth for the left of cutoff is stored in e(h_l)
            * The chosen bandwidth for the right of cutoff is stored in e(h_r)
            * Write a line to the results text file
            file write mylog "`p'          | `m'      | `k'         |  `e(h_l)'     |  `e(h_r)'" _n 
        }
    }
}

file close mylog
