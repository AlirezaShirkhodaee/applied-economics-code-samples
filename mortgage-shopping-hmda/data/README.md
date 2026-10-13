# Data

The raw data are public but too large to store here (the 2020 file is several gigabytes).

- Source: HMDA 2020 loan-level data, Consumer Financial Protection Bureau, <https://ffiec.cfpb.gov/data-publication/dynamic-national-loan-level-dataset/2020>
- `code/01_data_cleaning.ipynb` can download and unzip the file into `data/raw/`. Otherwise place `2020_lar.txt` there yourself.
- The cleaning notebook writes its intermediate files (`msa_data.csv`, `filtered_data.csv`, `cleaned_data.csv`) to `data/processed/`.
