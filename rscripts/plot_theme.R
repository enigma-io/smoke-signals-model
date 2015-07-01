require(ggplot2)

theme_enigma <- function(base_size = 14, base_family = "Avenir Light", ticks = FALSE) {
  ## TODO: start with theme_minimal
  ret <- theme_bw(
    base_family = base_family, 
    base_size = base_size) + 
    theme(
      legend.background = element_blank(), 
      legend.key = element_blank(), 
      panel.background = element_blank(), 
      panel.border = element_blank(), 
      strip.background = element_blank(), 
      plot.background = element_blank(), 
      axis.line = element_blank()
    )
  if (!ticks) {
    ret <- ret + theme(axis.ticks = element_blank())
  }
  ret
} 
## colors
BLUE <- '#288cd2'
RED <- '#eb3f25'
TEAL <- '#00b495'
