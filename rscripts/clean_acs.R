# required libs
require(data.table)
require(plyr)
require(bit64)

# read in the acs and convert nulls -> 0
acs <- as.data.frame(fread('data/acs.csv'))
acs[is.na(acs)] <- 0

# the acs tables have a full geoid, 
# but we need a simplified version to just 
# get the block-group summary level.
parse_id <- function(x) {
  strsplit(x, 'US')[[1]][2]
}
parse_sum_level <- function(x) { 
  strsplit(x, 'US')[[1]][1]
}

acs$bg_geoid <- as.character(unlist(llply(acs$geoid, parse_id)))
acs$sum_level <- as.character(unlist(llply(acs$geoid, parse_sum_level)))

# filter to just block groups
acs_bg <- acs[acs$sum_level == '15000', ]

# join 1980 smsas to 2010 blockgroups.
j <- as.data.frame(fread('data/msa80_bg.csv', colClasses = c('character', 'character', 'character')))
acs_bg <- merge(acs_bg, j, by='bg_geoid', all.x=T)
rm(acs, j)
    