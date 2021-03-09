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
library(bayestestR)
library(logspline)
library(ggridges)
library(forcats)
library(tidyverse)
library(rlist)

rm(list = ls())
set.seed(20200604)

# Merged data, every 2 sessions, ratio 50, 1000 random graphs
# cds
cds.results = read.csv("cds_results_merge_1_random_verb_1000_edge_ratio_50.csv",header = TRUE, sep="\t")
cds.results$diff = cds.results$causative - 
  cds.results$random
cds.results$ratio = cds.results$causative /
  cds.results$random


model.cds = brm(diff~age+(1+age|name),
                 data = cds.results,
                 prior = prior(student_t(5, 0, 3)),
                 cores = 4,
                 seed = 1,
                 iter = 4000,
                 control = list(adapt_delta = 0.99999))
model.cds.non = brm(diff~1|name,
                data = cds.results,
                cores = 4,
                seed = 1,
                iter = 4000,
                control = list(adapt_delta = 0.99999))


# child
cs.results = read.csv("child_results_merge_1_random_verb_1000_edge_ratio_50.csv",header = TRUE, sep="\t")
cs.results$diff = cs.results$causative - cs.results$random
cs.results$ratio = cs.results$causative /
  cs.results$random

model.cs = brm(diff~age+(1+age|name),
                data = cs.results,
                prior = prior(student_t(5, 0, 3)),
                cores = 4,
                seed = 1,
                iter = 4000,
                control = list(adapt_delta = 0.99999))
model.cs.non = brm(diff~1|name,
               data = cs.results,
               cores = 4,
               seed = 1,
               iter = 4000,
               control = list(adapt_delta = 0.99999))

full.results = cbind(cds.results, cs.results$diff)
colnames(full.results)[6] = "cds_diff"
colnames(full.results)[8] = "cs_diff"
full.results$diff = full.results$cds_diff - 
  full.results$cs_diff
full.results$random = cds.results$random - 
  cs.results$random

# full
model.full = brm(diff~age+(1+age|name),
                data = full.results,
                prior = prior(student_t(5, 0, 3)),
                cores = 4,
                seed = 1,
                iter = 4000,
                control = list(adapt_delta = 0.99999))
model.full.non = brm(diff~1|name,
                 data = full.results,
                 cores = 4,
                 seed = 1,
                 iter = 4000,
                 control = list(adapt_delta = 0.99999))


# loo for all
loo.cds = loo(model.cds, reloo=TRUE)
loo.cs = loo(model.cs, reloo=TRUE)
loo.full = loo(model.full, reloo=TRUE)

loo.cds.non = loo(model.cds.non, reloo=TRUE)
loo.cs.non = loo(model.cs.non, reloo=TRUE)
loo.full.non = loo(model.full.non, reloo=TRUE)

bp1.results = readRDS("bp_revised_edge_merge_1_bp1_loo.rds")
bp2.results = readRDS("bp_revised_edge_merge_1_bp2_loo.rds")

cds.loos = Map(c,bp1.results[1],bp2.results[1])[[1]]
cds.loos$full = loo.cds
cds.loos$non = loo.cds.non
cs.loos = Map(c,bp1.results[2],bp2.results[2])[[1]]
cs.loos$full = loo.cs
cs.loos$non = loo.cs.non
full.loos = Map(c,bp1.results[3],bp2.results[3])[[1]]
full.loos$full = loo.full
full.loos$non = loo.full.non

# BMA weighting
comp.cds = loo_model_weights(cds.loos,method = "pseudobma")
comp.cs = loo_model_weights(cs.loos,method = "pseudobma")
comp.full = loo_model_weights(full.loos,method = "pseudobma")

results.comp.cds = data.frame(model = names(comp.cds),
                              weight = c(unname(comp.cds)))
results.comp.cs = data.frame(model = names(comp.cs),
                              weight = c(unname(comp.cs)))
results.comp.full = data.frame(model = names(comp.full),
                              weight = c(unname(comp.full)))

cds.x.breaks = c("25",rep("",each=35),"30.32",rep("",each=9),"full","non")
ggplot(results.comp.cds,aes(x=model, y=weight))+
  geom_bar(stat = "identity")+
  scale_x_discrete(breaks=cds.x.breaks,
                   guide = guide_axis(angle = -45))+
  theme_bw()+
  theme(text = element_text(size=18))
ggsave("Figure1B.pdf",width = 12, height = 5)

cs.x.breaks = c(rep("",each=24),"28.30",rep("",each=21),"full","non")
ggplot(results.comp.cs,aes(x=model, y=weight))+
  geom_bar(stat = "identity")+
  scale_x_discrete(breaks=cs.x.breaks,
                   guide = guide_axis(angle = -45))+
  theme_bw()+
  theme(text = element_text(size=18))
ggsave("Figure1A.pdf",width = 12, height = 5)

full.x.breaks = c(rep("",each=19),"27.30",rep("",each=5),
                  "28.30",rep("",each=10), "30.32",rep("",each=9),"full","non")
ggplot(results.comp.full,aes(x=model, y=weight))+
  geom_bar(stat = "identity")+
  scale_x_discrete(breaks=full.x.breaks,
                   guide = guide_axis(angle = -45))+
  theme_bw()+
  theme(text = element_text(size=18))
ggsave("Figure3A.pdf",width = 12, height = 5)


# models

b1 <- function(x, bp1) ifelse(x < bp1, x - 22, x - 22)  #redundant...
b2 <- function(x, bp1, bp2) ifelse(x < bp1, 0,  x - bp1)
b3 <- function(x, bp2) ifelse(x < bp2, 0, x - bp2)

model.cds.30.32 = brm( diff ~ b1(age, 30)+
                   b2(age, 30, 32) +
                   b3(age, 32) +
                   (1 + b1(age, 30) + b2(age, 30, 32)+
                      b3(age, 32)| name),
                 data = cds.results,
                 prior = prior(student_t(5, 0, 3)),
                 cores = 4,
                 seed = 1,
                 iter = 4000,
                 control = list(adapt_delta = 0.99999))

# plot coef

model.cds.30.32 %>%
  spread_draws(b_b1age30,b_b2age3032,b_b3age32) %>%
  mutate(age1 = b_b1age30,
         age2 = b_b1age30 + b_b2age3032,
         age3 = b_b1age30 + b_b2age3032 + b_b3age32) %>%
  gather(.variable, .value, age1:age3) %>%
  ggplot(aes(x=.value, y=.variable))+
  stat_intervalh(.width = c(.50, .80, .90, .95),point_interval = median_qi)+
  scale_color_brewer()+
  scale_y_discrete(labels=c("<30","30-32",">32"))+
  ylab("age\n")+
  xlab("\ncoefficient estimate")+
  geom_vline(xintercept = 0, linetype="dotted")+
  theme_bw()+
  theme(text = element_text(size=17),
        legend.title = element_blank())
ggsave("Figure2D.pdf",width = 7,height=4)

# for group level summary
print(summary(model.cds.30.32),digits=5)
summary.cds.30.32 = as.data.frame(model.cds.30.32)
plot(marginal_effects(model.cds.30.32,
                      probs = c(0.05,0.95),
                      method = "predict"),
     points = TRUE)[[1]]+
  theme_bw()+
  ylab("above-baseline causative complexity")+
  xlab("age in months")+
  scale_x_continuous(breaks = seq(22,36,1))+
  theme(text = element_text(size=17))
ggsave("Figure2B.pdf",width = 7, height = 5)

cds.30.32.b1 = summary.cds.30.32$b_b1age30
cds.30.32.b2 = summary.cds.30.32$b_b2age3032
cds.30.32.b3 = summary.cds.30.32$b_b3age32
mean(cds.30.32.b1>0)
mean(cds.30.32.b1 + cds.30.32.b2<0)
mean(cds.30.32.b1 + cds.30.32.b2 + cds.30.32.b3>0)

# individual level of a certain variable

model.cs.28.30 = brm( diff ~ b1(age, 28)+
                   b2(age, 28, 30) +
                   b3(age, 30) +
                   (1 + b1(age, 28) + b2(age, 28, 30)+
                      b3(age, 30)| name),
                 data = cs.results,
                 prior = prior(student_t(5, 0, 3)),
                 cores = 4,
                 seed = 1,
                 iter = 4000,
                 control = list(adapt_delta = 0.99999))
print(summary(model.cs.28.30,prob=0.9),digits=5)
plot(marginal_effects(model.cs.28.30,
                      probs = c(0.05,0.95),
                      method = "predict"),
     points = TRUE)[[1]]+
  theme_bw()+
  ylab("above-baseline causative complexity")+
  xlab("age in months")+
  scale_x_continuous(breaks = seq(22,36,1))+
  theme(text = element_text(size=17))
ggsave("Figure2A.pdf",width = 7, height = 5)

model.cs.28.30 %>%
  spread_draws(b_b1age28,b_b2age2830,b_b3age30) %>%
  mutate(age1 = b_b1age28,
         age2 = b_b1age28 + b_b2age2830,
         age3 = b_b1age28 + b_b2age2830 + b_b3age30) %>%
  gather(.variable, .value, age1:age3) %>%
  ggplot(aes(x=.value, y=.variable))+
  stat_intervalh(.width = c(.50, .80, .90, .95),point_interval = median_qi)+
  scale_color_brewer()+
  scale_y_discrete(labels=c("<28","28-30",">30"))+
  ylab("age\n")+
  xlab("\ncoefficient estimate")+
  geom_vline(xintercept = 0, linetype="dotted")+
  theme_bw()+
  theme(text = element_text(size=17),
        legend.title = element_blank())
ggsave("Figure2C.pdf",width = 7,height=4)


plot(marginal_effects(model.full.27.30,
                      probs = c(0.05,0.95),
                      method = "predict"),
     points = TRUE)[[1]]+
  theme_bw()+
  ylab("above-baseline causative complexity")+
  xlab("age in months")+
  scale_x_continuous(breaks = seq(22,36,1))+
  theme(text = element_text(size=17))
ggsave("Figure3B.pdf",width = 6, height = 5)

model.full.27.30 %>%
  spread_draws(b_b1age27,b_b2age2730,b_b3age30) %>%
  mutate(age1 = b_b1age27,
         age2 = b_b1age27 + b_b2age2730,
         age3 = b_b1age27 + b_b2age2730 + b_b3age30) %>%
  gather(.variable, .value, age1:age3) %>%
  ggplot(aes(x=.value, y=.variable))+
  stat_intervalh(.width = c(.50, .80, .90, .95),point_interval = median_qi)+
  scale_color_brewer()+
  scale_y_discrete(labels=c("<30","30-32",">32"))+
  ylab("age\n")+
  xlab("\ncoefficient estimate")+
  geom_vline(xintercept = 0, linetype="dotted")+
  theme_bw()+
  theme(text = element_text(size=17),
        legend.title = element_blank())
ggsave("Figure3C.pdf",width = 5,height=4)

