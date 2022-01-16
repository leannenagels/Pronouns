
# Set SP WD if necessary 
# e.g., setwd('C:/Users/leann/Pronouns/SubPro/')
setwd('C:/Users/leann/Downloads/SubPro Pilot/')

# Read txt file Results SubPro
dat<-read.table('SP_results.txt',header=TRUE)

dat$acc <- 0
dat$acc <- ifelse(dat$key==dat$biasKey, 1, 0)