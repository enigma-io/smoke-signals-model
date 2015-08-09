# required libs
require(data.table)
require(plyr)
require(bit64)

# initially read in data to get number of columns
d <- fread('data/ahs.csv', nrows=1)
ncols <- ncol(d)

# internal colClasses are charachters
classes = c("character", "character", "character", "factor")
n_numeric_cols = ncols - length(classes)
classes = c(classes, rep('numeric', n_numeric_cols))

# now name these classes
names(classes) <- names(d)

# now read in full dataset
d <- as.data.frame(fread('data/ahs.csv', colClasses=classes))

## Variable Lookups

var_to_group <- sapply(names(d), function(x) strsplit(x, '_')[[1]][1])
groups <- unique(var_to_group)

# group : vars
group_vars <- function(g) {
  group <- c()
  for (i in 1:length(var_to_group))
    if (var_to_group[i] == g)
      group <- c(group, names(var_to_group)[i])
  group
}
group_to_vars <- sapply(groups, group_vars)

group_idx <- function(g) {
  group <- c()
  for (i in 1:length(var_to_group))
    if (var_to_group[i] == g)
      group <- c(group, i)
  group
}
group_to_idx <- sapply(groups, group_idx)

# groups with multiple vars
multi_groups <- c()
for (g in groups) {
  if (length(group_to_vars[g][[1]]) > 1)
    multi_groups <- c(multi_groups, g)
}

# groups with > 2 vars
triple_groups <- c()
for (g in groups) {
  if (length(group_to_vars[g][[1]]) > 2)
    triple_groups <- c(triple_groups, g)
}

## Handle Nulls

# values less than 0 are nulls
set_nas <- function(x) {
  if (is.numeric(x)) {
    x[which(x < 0)] <- NA
  }
  x
}

d <- as.data.frame(lapply(d, set_nas))

# check for groups of variables that have all zeros and set
# these rows as NA

for (g in multi_groups) {
  vars <- group_to_vars[g][[1]]
  x <- subset(d, select=vars)
  all_nulls <- which(rowSums(x) == 0)
  d[all_nulls, vars] <- NA
}

# if more than 90% of columns in a row are missing, drop it.
should_keep_row <- function(x) {
  per_na = length(which(is.na(x))) / ncols
  return(per_na <= .9)
}
keep_rows <- apply(d, 1, should_keep_row)
per_drop <- (length(which(!keep_rows)) / nrow(d)) * 100
cat("Dropping", round(per_drop, 2), "% of rows")
d <- d[keep_rows,]

# fix smoke + battery
d$smoke = d$smoke - 1
d$battery = d$battery - 1
