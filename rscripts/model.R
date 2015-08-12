require(bigrf)
require(ggplot2)
require(reshape2)
require(scales)
require(pROC)


# randomly impute missing data.
# A function for imputing missing data by sampling from a column's distribution
na_roughfix_sample <- function (object) {
  
  res <- lapply(object, roughfix_sample)
  structure(res, class = "data.frame", row.names = seq_len(nrow(object)))
}

roughfix_sample <- function(x) {
  
  missing <- is.na(x)
  if (!any(missing)) return(x)
  x[missing] <- suppressWarnings(sample(x[!missing], length(missing), replace=T))
  return(x)
}

# a function to split a dataset
split <- function(d, split_per=0.6) {
  
  samp <- sample(1:nrow(d), nrow(d)*split_per)
  list(test=d[-(samp),], train=d[samp, ])
}

# normalize a numeric vector to 0/1 scale
normscore <- function(x, to=c(0,1)) {
  v <- (x - min(na.omit(x))) / (max(na.omit(x)) - min(na.omit(x)))
  rescale(v, to=to)
}

# estimate a random forest model
rf_estimate <- function(d, classwts=c(1, 19), ntree=100, importance=F, 
                        trace=1, impute=T, varselect=3:ncol(d)) {
  if (impute) {
    d <- na_roughfix_sample(d)
  }
  # train model
  d$smoke <- as.factor(d$smoke)
  m <- bigrfc(d, d$smoke, 
              ntree=ntree, varselect=varselect, 
              trace=trace,
              yclasswts = classwts)

  # compute variable importance
  if (importance) {
    
    cat("\ncalculating var. importance ...\n")
    imp <- varimp(m, reuse.cache=T)
    imp <- data.frame(significance=as.numeric(imp$significance),
                      importance=as.numeric(imp$importance),
                      zscore=as.numeric(imp$zscore),
                      term=as.character((names(imp$importance))))
    
  } else {
    imp <- NULL
  }
  
  conf_matrix <- m@trainconfusion
  # error rates
  train_err <- data.frame(
    train_err = as.numeric((conf_matrix[1,2] + conf_matrix[2,1]) / sum(conf_matrix)),
    train_has_alarm_err = as.numeric(conf_matrix[1,2] / sum(conf_matrix[1,])),
    train_lacks_alarm_err = as.numeric(conf_matrix[2,1] / sum(conf_matrix[2,]))
  )

  # output
  list(imp=imp, m=m, train_err=train_err)
}

# plot var. importance for rf
rf_imp_plot <- function(imp, title='Variable importance for Random Forest model') {
  
  ggplot(imp, aes(x=reorder(term, importance), y=importance, fill=abs(zscore))) + 
    geom_bar(stat='identity') +
    coord_flip() + 
    xlab('Variable') + 
    ylab('Importance') + 
    labs(title=title) +
    scale_fill_continuous(low=BLUE, high=RED) +
    theme_enigma()
}


# predict new data
rf_predict <- function(m, d, trace=0, impute=T) {
  
  if (impute) {
    d <- na_roughfix_sample(d)
  }
  
  # predict newdata
  predictions <- predict(m, d, trace=trace)
  
  # compute probabilities
  probs <- predictions@testvotes[,2] / rowSums(predictions@testvotes)
  
  # confustion matrix
  p <- as.factor(as.numeric(predictions) - 1)
  
  if (!is.null(d$smoke) & !all(is.na(d$smoke))) {
    actual <- d$smoke
    conf_matrix <- table(actual, p, dnn=c('Actual', 'Predicted'))
    # error rates
    test_err <- data.frame(
      test_err = as.numeric((conf_matrix[1,2] + conf_matrix[2,1]) / sum(conf_matrix)),
      test_has_alarm_err = as.numeric(conf_matrix[1,2] / sum(conf_matrix[1,])),
      test_lacks_alarm_err = as.numeric(conf_matrix[2,1] / sum(conf_matrix[2,])))

  } else {
    test_err <- NULL
    conf_matrix <- NULL
    actual <- NULL
  }

  list(test_err=test_err, m=m,
       predictions=p, 
       probs=probs,
       actual=actual,
       conf_matrix=conf_matrix
  )
}

# cross validate 
rf_cross_validate <- function(d, split_per=0.6, ntree=100, 
                              trace=0, wt=20, classwts=c(1,19), 
                              impute=T, varselect=3:ncol(d)) {
  
  # split
  dat <- split(d, split_per)
  
  # train
  train <- rf_estimate(dat$train, classwts=classwts, 
                       ntree, trace=trace, impute=impute, 
                       varselect=varselect)
  
  # test 
  o <- rf_predict(train$m, dat$test, impute=impute)
  
  # format output
  o$train_err <- train$train_err
  o$m <- train$m 
  return(o)
}

# explore effect of class weights 
rf_classwts <- function(d, zero=1, weights=seq(1, 30, 2), 
                        sampsize=50000, ntree=30, optimal=19, trace=0) {
  
  o <- data.frame()
  samp <- sample(1:nrow(d), sampsize)
  for (wt in weights) {
    cat("testing weight", wt, "\n")
    cv <- rf_cross_validate(d[samp,], classwts=c(zero, wt), ntree=ntree, trace=trace)
    i <- data.frame(cv$train_err, cv$test_err) 
    i$wt <- wt
    o <- rbind(o, i)
  }
 return(o)
}

# plot effect of class weight
rf_classwts_plot <- function(o, optimal) {
  
  wtdf <- melt(o, id=c("wt"))
  ggplot(wtdf, aes(x=wt, y=value, color=variable)) +
    geom_vline(x=optimal, color="#aaaaaa") +
    geom_line(size=1) + 
    xlab("Weighting factor") + 
    ylab('Classification error') +
    labs(title='Error rates by weighting factor') +
    theme_enigma()
}

# plot a roc curve.
roc_curve <- function(actual, predicted, title='ROC Curve') {
  
  g <- roc(as.numeric(actual)  ~ as.numeric(predicted))
  g_d <- data.frame(specificities=g$specificities, sensitivities=g$sensitivities)
  ggplot(g_d, aes(x=specificities, y=sensitivities)) + 
    geom_line(color=BLUE, size=1.25) + 
    xlim(1, 0) + 
    geom_abline(intercept = 1, slope=1) + 
    theme_enigma() + 
    labs(title=title) + 
    xlab('Specificities') + 
    ylab('Sensitivities')
}