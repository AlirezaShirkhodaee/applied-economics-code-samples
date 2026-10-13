/*------------------------------------------------------------------------------
						Define Required Paths
------------------------------------------------------------------------------*/
	clear
	cls
	
	* All paths are relative to the project root, i.e. the folder that contains
	* code/, data/ and output/. Start Stata in that folder (or cd to it) and run:
	*     do code/main.do
	gl PROJECT_DIR	"`c(pwd)'"
	
	cap confirm file "${PROJECT_DIR}/code/main.do"
	if _rc {
		di as error "Run main.do from the project root (the folder that contains code/): do code/main.do"
		exit 601
	}
	
	* Define paths
	gl DATA_DIR		"${PROJECT_DIR}/data"
	gl OUTPUT_DIR	"${PROJECT_DIR}/output"
	gl GRAPH_DIR	"${PROJECT_DIR}/output/figures"
	gl TABLE_DIR	"${PROJECT_DIR}/output/tables"
	gl SRC_DIR		"${PROJECT_DIR}/code"
	
		
	* make directions for outputs
	cap mkdir "${OUTPUT_DIR}"
	cap mkdir "${GRAPH_DIR}"
	cap mkdir "${TABLE_DIR}"
	
	
/*------------------------------------------------------------------------------
						Install Required Libraries
------------------------------------------------------------------------------*/
	
	* estout provides eststo/esttab (Tables 2 and 3); rdrobust is used for the
	* bandwidth selection in part 3. A package is installed only if it is missing,
	* and a failed installation stops the run instead of being silently ignored.
	foreach pkg in estout rdrobust {
		cap which `pkg'
		if _rc ssc install `pkg', replace
	}
	
	
/*------------------------------------------------------------------------------
							Run do files
------------------------------------------------------------------------------*/
	
	* Part 1) Data Cleaning
	do "${SRC_DIR}/part1_data_cleaning.do"
	
	* Part 2) The Main Results
	do "${SRC_DIR}/part2_main_results.do"
	
	* Part 3: Additional Tests for Regression Discontinuity
	do "${SRC_DIR}/part3_additional_tests.do"

