library(ggplot2)
library(ggjoy)
library(rstanarm)
library(dplyr)
library(tidybayes)
library(segmented)
library(lme4)
library(optimx)
library(mgcv)
library(brms)
library(schoenberg)
library(gamm4)

rm(list = ls())
set.seed(20200604)

# Merged data, 3 sessions, log[e] ratio
# cds
merged.3.cds.results = read.csv("cds_results.csv",header = TRUE, sep="\t")
merged.3.cds.results$diff = merged.3.cds.results$causative - 
  merged.3.cds.results$random
merged.3.cds.results$ratio = merged.3.cds.results$causative /
  merged.3.cds.results$random
# ggplot(merged.3.cds.results, aes(age, diff))+
#   geom_smooth()+
#   geom_point()


# child
merged.3.cs.results = read.csv("child_results.csv",header = TRUE, sep="\t")
merged.3.cs.results$diff = merged.3.cs.results$causative - merged.3.cs.results$random
merged.3.cs.results$ratio = merged.3.cs.results$causative /
  merged.3.cs.results$random
# ggplot(merged.3.cs.results, aes(age, diff))+
#   geom_smooth()+
#   geom_point()
# ggplot(merged.3.cds.results, aes(age, diff,color="cds"))+
#   theme_bw()+
#   geom_smooth(method = "loess")+
#   geom_smooth(data=merged.3.cs.results,
#               aes(age,diff,color="child"), method = "loess")+
#   facet_wrap(vars(name))

merged.3.full.results = cbind(merged.3.cds.results, merged.3.cs.results$diff)
colnames(merged.3.full.results)[6] = "cds_diff"
colnames(merged.3.full.results)[8] = "cs_diff"
merged.3.full.results$diff = merged.3.full.results$cds_diff - 
  merged.3.full.results$cs_diff
merged.3.full.results$random = merged.3.cds.results$random - 
  merged.3.cs.results$random
# ggplot(filter(merged.3.full.results,
#               age > 24 & age < 36),
#        aes(age, cds_diff-cs_diff))+
#   theme_bw()+
#   geom_smooth(method = "loess")+
#   geom_point()
# #facet_wrap(vars(name))


# brm to compare models with different breakpoints

age.range = 25:34
# b1 <- function(x, bp) ifelse(x < bp, bp - x, 0)# before slope
# b2 <- function(x, bp) ifelse(x < bp, 0, x - bp) # after slope
b1 <- function(x, bp) x-22
b2 <- function(x, bp) ifelse(x <= bp, 0, x - bp)

bp.analysis = function(age.range, dataset){
  # w/o "Ruth"
  #dataset = filter(dataset, name!="Ruth")
  #dataset = filter(dataset,
  #                 age>age.range[1]-2 & age<age.range[length(age.range)]+2)
  model.list = list()
  loo.list = list()
  # this is more than ridiculous but ultimately a solution to insert dynamic number into this formula, Jesus
  
  for (bp in age.range){
    # build model
    # model.temp = stan_lmer(diff~ b1(age, bp) +
    #                         b2(age, bp) +
    #                         (1 + b1(age,bp)+
    #                         b2(age,bp)|name),
    #                         data = dataset,
    #                         prior_intercept = student_t(df=5,location=0),
    #                         prior = student_t(df=5,location=0),
    #                         cores = 4,
    #                         seed = 1,
    #                         iter = 4000,
    #                         adapt_delta = 0.999999)
    # dependent variable: random or diff
    f = as.formula(paste("diff~ b1(age,", bp,
                         ") + b2(age, ", bp,
                         ") + (1 + b1(age," ,bp,
                         ")+ b2(age,",bp,
                         ")|name)"))
    model.temp = brm(f,
                     data = dataset,
                     prior = prior(student_t(5, 0, 3)),
                     cores = 4,
                     seed = 1,
                     iter = 4000,
                     control = list(adapt_delta = 0.99999))
    # store model
    model.list[[as.character(bp)]] = model.temp
    # loo
    loo.list[[as.character(bp)]] = loo(model.temp, reloo = TRUE) 
  }
  
  return(list("model" = model.list, "loo" = loo.list))
}


bp.results.cds = bp.analysis(age.range, merged.3.cds.results)
bp.results.cs = bp.analysis(age.range, merged.3.cs.results)
bp.results.full = bp.analysis(age.range, merged.3.full.results)

bp.comp.cds = loo_model_weights(bp.results.cds$loo,method = "pseudobma")
bp.comp.cs = loo_model_weights(bp.results.cs$loo,method = "pseudobma")
bp.comp.full = loo_model_weights(bp.results.full$loo,method = "pseudobma")


#save.image("~/Documents/UZH/papers/paper2/edge_merge_1_bp1_15062020.RData")
saveRDS(list(bp.results.cds$loo, 
             bp.results.cs$loo, 
             bp.results.full$loo), 
        "bp_revised_edge_merge_1_bp1_loo.rds")
