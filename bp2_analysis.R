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
#facet_wrap(vars(name))


# brm to compare models with different breakpoints

age.range = 25:32
# b1 <- function(x, bp1) ifelse(x < bp1, x - 22, bp1 - 22) # 1st slope
# b2 <- function(x, bp1, bp2) ifelse(x < bp1, 0, ifelse(x < bp2, x - bp1, bp2 - bp1)) # 2nd slope
# b3 <- function(x, bp2) ifelse(x > bp2, x - bp2, 0)
b1 <- function(x, bp1) x-22
b2 <- function(x, bp1, bp2) ifelse(x <= bp1, 0,  x - bp1)
b3 <- function(x, bp2) ifelse(x <= bp2, 0, x - bp2)


bp.analysis = function(age.range, dataset){
  #dataset = filter(dataset,
  #                 age>age.range[1]-2 & age<age.range[length(age.range)]+2)
  # w/o Ruth
  #dataset = filter(dataset, name!="Ruth")
  model.list = list()
  loo.list = list()
  # this is more than ridiculous but ultimately a solution to insert dynamic number into this formula, Jesus
  
  for (bp1 in age.range){
    for (bp2 in (bp1+2):(age.range[length(age.range)]+2)){
      f = as.formula(paste("diff~ b1(age,", bp1,
                           ") + b2(age,", bp1, ",", bp2,
                           ") + b3(age,", bp2,
                           ") + (1 + b1(age," ,bp1,
                           ") + b2(age,", bp1, ",",bp2,
                           ") + b3(age,", bp2,
                           ")|name)"))
      model.temp = brm(f,
                       data = dataset,
                       prior = prior(student_t(5, 0, 3)),
                       cores = 4,
                       seed = 1,
                       iter = 4000,
                       control = list(adapt_delta = 0.99999))
      # store model
      model.list[[paste(as.character(bp1),as.character(bp2),sep = ".")]] = model.temp
      # loo
      loo.list[[paste(as.character(bp1),as.character(bp2),sep = ".")]] = loo(model.temp, reloo = TRUE) 
      #loo.list[[paste(as.character(bp1),as.character(bp2),sep = ".")]] = loo(model.temp)
      #save(model.list,loo.list,file="~/Documents/UZH/papers/paper2/model_temp.RData")
    }
  }
  
  return(list("model" = model.list, "loo" = loo.list))
}


bp.results.cds = bp.analysis(age.range, merged.3.cds.results)
#save.image("~/Documents/UZH/papers/paper2/merge_1_bp2_13062020.RData")
bp.results.cs = bp.analysis(age.range, merged.3.cs.results)
#save.image("~/Documents/UZH/papers/paper2/merge_1_bp2_13062020.RData")
bp.results.full = bp.analysis(age.range, merged.3.full.results)
#save.image("~/Documents/UZH/papers/paper2/merge_1_bp2_13062020.RData")

bp.comp.cds = loo_model_weights(bp.results.cds$loo,method = "pseudobma")
bp.comp.cs = loo_model_weights(bp.results.cs$loo,method = "pseudobma")
bp.comp.full = loo_model_weights(bp.results.full$loo,method = "pseudobma")


#save.image("~/Documents/UZH/papers/paper2/edge_merge_1_bp2_15062020.RData")
saveRDS(list(bp.results.cds$loo, 
             bp.results.cs$loo, 
             bp.results.full$loo), 
        "bp_revised_edge_merge_1_bp2_loo.rds")
# 
# for (n in names(bp.results.cds$model)){
#   loo.temp = loo(bp.results.cds$model[[n]], reloo = TRUE, reloo_args = list(seed = 1)) 
#   bp.results.cds$loo[[n]] = loo.temp
# }
# for (n in names(bp.results.cs$model)){
#   loo.temp = loo(bp.results.cs$model[[n]], reloo = TRUE, reloo_args = list(seed = 1)) 
#   bp.results.cs$loo[[n]] = loo.temp
# }
# for (n in names(bp.results.full$model)){
#   loo.temp = loo(bp.results.full$model[[n]], reloo = TRUE, reloo_args = list(seed = 1)) 
#   bp.results.full$loo[[n]] = loo.temp
# }

