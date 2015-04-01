##Read in nsidc data
library(checkpoint)
checkpoint("2015-04-01")
library(dplyr)
library(httr)

#Download file directly from source if it is not present 
if(!file.exists('data/liag_freeze_thaw_table.csv')){
	library(httr)
	file_url = 'ftp://sidads.colorado.edu/pub/DATASETS/NOAA/G01377/liag_freeze_thaw_table.csv'
	data = GET(file_url)
	writeBin(content(data, 'raw'), 'data/liag_freeze_thaw_table.csv')
}

#read in file and pull out the data used based on rules by Magnuson et al. 
# rules in document: 'Documents/updateLog rules for ARAI1.docx'

nsidc = read.csv("data/liag_freeze_thaw_table.csv", as.is=TRUE)

#Filter out all LAKE SUWA Data
nsidc_suwa = filter(nsidc, grepl("LAKE SUWA",lakename))

#All rules are applied to the first year of
# "season". Do not use iceon_year as this varies
# with iceon_month
nsidc_suwa$rule_year = as.numeric(substr(nsidc_suwa$season, 0, 4))


#Create empty corrected_data variable
corrected_data = data.frame()


#First rule, "Use YATSU1 from 1994-2004"
yatsu1 = filter(nsidc_suwa, 
							 rule_year >= 1994, 
							 rule_year <= 2004, 
							 lakecode=="YATSU1")

corrected_data = rbind(corrected_data, yatsu1)


#Second rule, "Use ARAI1 from 1443-1993 (Arai uses Arakawa from 1953 on)"
# Include correction:
#   	1. 1952 use WSTA1 and Arakawa, not ARAI1; final = Jan 5
arai1 = filter(nsidc_suwa, 
								rule_year >= 1443, 
								rule_year <= 1993, 
							  rule_year != 1952,
								lakecode=="ARAI1")

corrected_data = rbind(corrected_data, arai1)


#Rule/correction "1952 use WSTA1 and Arakawa, not ARAI1; final = Jan 5"
wsta1 = filter(nsidc_suwa, 
							 	rule_year == 1952,
							  lakecode == "WSTA1")

corrected_data = rbind(corrected_data, wsta1)

#order by year
corrected_data = arrange(corrected_data, rule_year)

# Two corrections are already included in the NSIDC Data
## 1.  1976 WSTA = -1 (We do not use these data anyway)
## 2.  Subtract 30 days up through 1871 for calendar correction


# save the data
write.csv(corrected_data, 'data/suwa_prepared_analysis_data.csv', row.names=FALSE)

