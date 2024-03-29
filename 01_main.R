library(xlsx)
library(dplyr)
library(SciViews)
library(tidyverse) # Modern data science library 
library(plm)       # Panel data analysis library
library(car)       # Companion to applied regression 
library(gplots)    # Various programing tools for plotting data
library(tseries)   # For timeseries analysis
library(lmtest)
library(DataCombine)
library(sjPlot)
library("lmtest")
library("sandwich")
library(performance)
library(parameters)
library(readxl)
setwd("~/Rokas/EKONOMIKA VU/BSC THESIS")
dataset <- read_excel("dataset (17).xlsx") ## FOR FIXED EFFECTS
dataset <- read_excel("dataset (23).xlsx") ## FOR FIXED EFFECTS

dataset <- read_excel("dataset.xlsx")

colnames(dataset)[1]<-"Player"
colnames(dataset)[6]<-"Salary_inflation_adj"
colnames(dataset)[4]<-"Age_squared"
colnames(dataset)[9]<-"Pos"
colnames(dataset)[8]<-"Teams"
colnames(dataset)[43]<-"All.star"
colnames(dataset)[46]<-"WS"

dataset$PTS_36<-as.numeric(dataset$PTS_36)
dataset$BLK_36<-as.numeric(dataset$BLK_36)
dataset$AST_36<-as.numeric(dataset$AST_36)
dataset$Age<-as.numeric(dataset$Age)

dataset$STL_36<-as.numeric(dataset$STL_36)

dataset$TRB_36<-as.numeric(dataset$TRB_36)

dataset %>% distinct(Player, Age, .keep_all = TRUE)

dataset<- filter(dataset,Age>=20 & Age<=37)
dataset<- filter(dataset,Year!=2012)
dataset$Points_squared<-dataset$Avg_PTS^2
dataset$Experience_squared<-dataset$Experience^2

dataset$PER<-dataset$Avg_PTS+dataset$Avg_TRB+dataset$Avg_STL+dataset$Avg_AST+dataset$Avg_BLK-dataset$Avg_TOV-dataset$Avg_PF



#--------CORR-----------------------------------
library(corrplot)
colnames(dataset)[6]<-"Salary_inf"
colnames(dataset)[8]<-"Teams"

corrplot(dataset %>% dplyr:: select(Age,Salary_inf,Experience,WS,Pk, Forward, Center, Teams,All.star,Sum_G,Sum_GS,Avg_MP,Avg_TRB,Avg_AST,Avg_STL,Avg_BLK,Avg_PTS) %>% cor(use = "pairwise"), method = "number",addCoef.col = "black",  tl.col="black",)

corrplot(dataset %>% dplyr:: select(Age,Salary_inf,Experience,WS,Pk, Forward, Center,Teams,All.star,Sum_G,Sum_GS,Avg_MP,TRB_36,AST_36,STL_36,BLK_36,PTS_36) %>% cor(use = "pairwise"), method = "number",addCoef.col = "black",  tl.col="black",)
#------------------MODEL--------------------
colnames(dataset)[6]<-"Salary_inflation_adj"
colnames(dataset)[8]<-"Teams_played"
colnames(dataset)[46]<-"ws"

dataset_test<-dataset
dataset <- pdata.frame(dataset, index=c("Player"))
dataset_test <- pdata.frame(dataset_test, index=c("Player","Year"))
colnames(dataset_test)[43]<-"All.star"

table(index(dataset), useNA = "ifany")

plotmeans(Salary_inflation_adj ~ Experience , data = filter(dataset, Experience<16))
plotmeans(Salary_inflation_adj ~ Age , data = filter(dataset, Experience<16))

plotmeans(ws ~ Age , data = dataset)


plotmeans(Wage_in_thousands ~ Avg_PTS, data = dataset, conf_interval=FALSE)
plotmeans(PER ~ Age, data = dataset)
plotmeans(PER_36 ~ Age, data = dataset)

plotmeans(salar ~ Age, data = dataset)
plotmeans(Avg_PTS ~ Age, data = dataset)
plotmeans(Avg_STL ~ Age, data = dataset)

plotmeans(Avg_BLK ~ Age, data = dataset)
plotmeans(Avg_TRB ~ Age, data = dataset)
plotmeans(Avg_MP ~ Age, data = dataset)
plotmeans(Sum_G ~ Age, data = dataset)


plotmeans(AST_36 ~ Age, data = dataset)
plotmeans(PTS_36 ~ Age, data = dataset)
plotmeans(STL_36 ~ Age, data = dataset)

plotmeans(BLK_36 ~ Age, data = dataset)
plotmeans(TRB_36 ~ Age, data = dataset)
## tabs-----------------
summary(ols<- lm(Salary_inflation_adj ~ factor(Age)+factor(Year), data=dataset  ))
summary(ols1<- lm(Salary_inflation_adj ~ ws+Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star+factor(Age)+factor(Year), data=dataset  ))
summary(ols2<- lm(Salary_inflation_adj ~ ws+Teams_played+Sum_G+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center+All.star+factor(Age)+factor(Year), data=dataset  ))
tab_model(ols,ols1,ols2,p.style="stars",vcov.type = c("HC0"),vcov.fun = "vcovHC" ,show.obs=TRUE,show.se=TRUE,collapse.se=TRUE,title="OLS Age Profile",dv.labels = c("Raw estimates","Conditional on other variables (per 36)" ,"Conditional on other variables (per game)") )


summary(fixed<-plm(Salary_inflation_adj ~ factor(Age)+factor(Year), data=dataset, model="within",index = c("Player", "Year"), within=TRUE  ))
summary(fixed1<- plm(Salary_inflation_adj ~ ws+Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star+factor(Age)+factor(Year), data=dataset, model="within",index = c("Player", "Year"),   ))
summary(fixed2<- plm(Salary_inflation_adj ~ ws+Teams_played+Sum_G+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center+All.star+factor(Age)+factor(Year), data=dataset, model="within",index = c("Player", "Year")  ))
tab_model(fixed,fixed1,fixed2,p.style="stars",vcov.fun = "vcovHC" , vcov.type = "HC0",show.obs=TRUE,show.se=TRUE,collapse.se=TRUE,title="Fixed-Effect Age Profile" ,dv.labels = c("Raw estimates","Conditional on other variables (per 36)" ,"Conditional on other variables (per game)"))

write.csv(a,file="model.csv")
check_heteroscedasticity(fixed1)
test_model<- model_parameters(
  fixed1,
  robust = TRUE,
  vcov_estimation = "CL",
  vcov_type = "HC0",
  vcov_args = list(cluster = dataset$Player)
)
model_para
vcovNW(fixed1, type = "HC0")
coeftest(fixed11, vcov = vcovHC, type = "HC0", method="arellano")
coeftest(fixed2, vcov = vcovHC, type = "HC0", method="arellano")

coeftest(ols1, vcov = vcovHC, type = "HC0")

coeftest(ols2, vcov = vcovHC, type = "HC0", method="arellano")

summary(fixed3<-plm(Salary_inflation_adj ~  Age, data=dataset, model="within",index = c("Player", "Year"), within=TRUE  ))
summary(fixed4<- plm(Salary_inflation_adj ~ Age+ Age_squared, data=dataset, model="within",index = c("Player", "Year"),   ))
summary(fixed5<- plm(Salary_inflation_adj ~ Age+ Age_squared+Teams_played+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+factor(Year), data=dataset, model="within",index = c("Player", "Year"), within=TRUE  ))
summary(fixed6<- plm(Salary_inflation_adj ~ Age+ Age_squared+Teams_played+Sum_G+All.star+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center+factor(Year), data=dataset, model="within",index = c("Player", "Year"), within=TRUE  ))
tab_model(fixed3,fixed4,fixed5,fixed6,vcov.fun = "vcovHC" , vcov.type = "HC0",p.style="stars",show.obs=TRUE,show.se=TRUE,collapse.se=TRUE,rm.terms = "Year[2001,2020,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019]",title="Fixed-Effect model" ,dv.labels = c("Age linear","Age quadratic" ,"Conditional on other variables (per 36)","Conditional on other variables (per game)"))


summary(ols3<- lm(Salary_inflation_adj ~ Age, data=dataset  ))
summary(ols4<- lm(Salary_inflation_adj ~ Age+ Age_squared, data=dataset  ))
summary(ols5<- lm(Salary_inflation_adj ~ Age+ Age_squared+Teams_played+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center, data=dataset  ))
summary(ols6<- lm(Salary_inflation_adj ~ Age+ Age_squared+Teams_played+Sum_G+All.star+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center, data=dataset  ))
tab_model(ols3,ols4,ols5,ols6,p.style="stars",vcov.type = c("HC0"),vcov.fun = "vcovHC" ,show.obs=TRUE,show.se=TRUE,collapse.se=TRUE,title="OLS Age Profile",dv.labels = c("Age linear","Age quadratic" ,"Conditional on other variables (per 36)","Conditional on other variables (per game)") )







summary(fixed8<- plm(Salary_inflation_adj ~ factor(Experience)+Age_squared, data=dataset, model="within",index = c("Player", "Year"),   ))
summary(fixed9<- plm(Salary_inflation_adj ~ factor(Experience)+ Age+Age_squared+Teams_played+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+factor(Year), data=dataset, model="within",index = c("Player", "Year"), within=TRUE  ))
summary(fixed10<- plm(Salary_inflation_adj ~ factor(Experience)+Age+ Age_squared+Teams_played+Sum_G+All.star+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center+factor(Year), data=dataset, model="within",index = c("Player", "Year"), within=TRUE  ))
tab_model(fixed8,fixed9,fixed10,vcov.fun = "vcovHC" , vcov.type = "HC0",p.style="stars",show.obs=TRUE,show.se=TRUE,collapse.se=TRUE,rm.terms = "Year[2001,2020,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019]",title="Fixed-Effect model" ,dv.labels = c("Age linear","Age quadratic" ,"Conditional on other variables (per 36)","Conditional on other variables (per game)"))


summary(ols6<- lm(Salary_inflation_adj ~ Age+ Age_squared+Experience+Experience_squared+ws+Teams_played+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+factor(Year), data=dataset  ))
summary(ols5<- lm(Salary_inflation_adj ~ Age+ Age_squared+ws+Teams_played+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+factor(Year), data=dataset  ))

summary(ols7<- lm(Salary_inflation_adj ~ Experience+Experience_squared+ws+Teams_played+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+factor(Year), data=dataset  ))

tab_model(ols6,ols5,ols7,p.style="stars",vcov.type = "HC0",vcov.fun = "vcovHC" ,show.obs=TRUE,show.se=TRUE,show.ci = FALSE,title="OLS Age Profile",rm.terms = c("factor(Year)2002","factor(Year)2003","factor(Year)2004","factor(Year)2005","factor(Year)2007","factor(Year)2006","factor(Year)2008","factor(Year)2009","factor(Year)2010","factor(Year)2011","factor(Year)2012","factor(Year)2013","factor(Year)2014","factor(Year)2015","factor(Year)2016","factor(Year)2017","factor(Year)2018","factor(Year)2019","factor(Year)2020") ,dv.labels = c("Benchmark","Age" ,"Experience"))


summary(fixed8<- plm(Salary_inflation_adj ~ factor(Year)+Age_squared, data=dataset, model="within",index = c("Player", "Year"),   ))
summary(fixed9<- plm(Salary_inflation_adj ~ factor(Year)+ Age+Age_squared+Teams_played+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+factor(Year), data=dataset, model="within",index = c("Player", "Year"), within=TRUE  ))
summary(fixed10<- plm(Salary_inflation_adj ~ factor(Year)+Age+ Age_squared+Teams_played+Sum_G+All.star+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center+factor(Year), data=dataset, model="within",index = c("Player", "Year"), within=TRUE  ))
tab_model(fixed8,fixed9,fixed10,vcov.fun = "vcovHC" , vcov.type = "HC0",p.style="stars",show.obs=TRUE,show.se=TRUE,collapse.se=TRUE,rm.terms = "Year[2001,2020,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019]",title="Fixed-Effect model" ,dv.labels = c("Age linear","Age quadratic" ,"Conditional on other variables (per 36)","Conditional on other variables (per game)"))


summary(ols4<- lm(Salary_inflation_adj ~ factor(Age)+factor(Year)+Experience, data=dataset  ))
summary(ols5<- lm(Salary_inflation_adj ~ factor(Age) +factor(Year)+Experience+Experience_squared+ws+Teams_played+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center, data=dataset  ))
summary(ols6<- lm(Salary_inflation_adj ~  Experience+Experience_squared+Age+Age_squared+factor(Year)+Teams_played+Sum_G+All.star+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center, data=dataset  ))
tab_model(ols4,ols5,ols6,p.style="stars",vcov.type = c("HC0"),vcov.fun = "vcovHC" ,show.obs=TRUE,show.se=TRUE,collapse.se=TRUE,title="OLS Age Profile",dv.labels = c("Age linear","Age quadratic" ,"Conditional on other variables (per 36)","Conditional on other variables (per game)") )


summary(ols4<- lm(Salary_inflation_adj ~ factor(Age)+factor(Year)+ws+Teams_played+Sum_G+All.star+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center, data=filter(dataset, Year > 2005  ) ))
summary(ols4<- lm(Salary_inflation_adj ~ factor(Experience)+factor(Age)+factor(Year)+ws+Teams_played+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center, data=filter(dataset, Year > 2001  )))
coeftest(ols5, vcov = vcovHC, type = "HC0")

summary(ols5<- lm(Salary_inflation_adj ~ factor(Experience)+Age_squared+Age+factor(Year)+ws+Teams_played+Sum_G+All.star+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center, data=dataset  ))
summary(ols6<- lm(Salary_inflation_adj ~ factor(Experience)+Age_squared+factor(Year)+ws+Teams_played+Sum_G+All.star+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center, data=filter(dataset,Year>2005) , model="within",index = c("Player", "Year"), vcov=vcovHC(fixed11, method = "arellano") ))
summary(fixed13<- plm(Salary_inflation_adj ~Age+ Age_squared+Experience+Experience_squared+ws+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Forward+Center+factor(Year), data=filter(dataset, Year > 2005  ), model="within",index = c("Player", "Year"), within=TRUE, vcov=vcovHC(fixed11, method = "arellano")  ))

summary(fixed10<- plm(Salary_inflation_adj ~Age+ Age_squared+ws+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Forward+Center+factor(Year), data=filter(dataset, Year > 2005  ), model="within",index = c("Player", "Year"), within=TRUE, vcov=vcovHC(fixed11, method = "arellano")  ))
summary(fixed12<- plm(Salary_inflation_adj ~Experience+Experience_squared+ws+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Forward+Center+factor(Year), data=filter(dataset, Year > 2005  ), model="within",index = c("Player", "Year"), within=TRUE , vcov=vcovHC(fixed11, method = "arellano") ))

tab_model(fixed13,fixed10,fixed12,vcov.fun = "vcovHC" , vcov.type = "HC0",show.ci = FALSE,p.style="stars",show.obs=TRUE,show.se=TRUE,rm.terms = c("factor(Year)2007","factor(Year)2006","factor(Year)2008","factor(Year)2009","factor(Year)2010","factor(Year)2011","factor(Year)2012","factor(Year)2013","factor(Year)2014","factor(Year)2015","factor(Year)2016","factor(Year)2017","factor(Year)2018","factor(Year)2019","factor(Year)2020"),title="Fixed-Effect model" ,dv.labels = c("Benchmark","Age" ,"Experience"))
summary(test<- plm(Salary_inflation_adj ~Age+Experience+Experience_squared+ws+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Forward+Center+factor(Year), data=filter(dataset, Year > 2005  ), model="within",index = c("Player", "Year"), within=TRUE, vcov=vcovHC(fixed11, method = "arellano")  ))

summary(fixed11<- plm(Salary_inflation_adj ~ factor(Age)+ws+Teams_played+Sum_G+All.star+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center+factor(Year), data=dataset, model="within",index = c("Player", "Year"), within=TRUE  ))

summary(fixed11<- plm(Salary_inflation_adj ~ factor(Age)+ws+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Forward+Center+factor(Year), data=filter(dataset, Year > 2005  ), model="within",index = c("Player", "Year"), vcov=vcovHC(fixed11, method = "arellano") ))
tab_model(fixed11,vcov.fun = "vcovHC" , vcov.type = "HC0",show.ci = FALSE,p.style="stars",show.obs=TRUE,show.se=TRUE,rm.terms = c("factor(Year)2007","factor(Year)2006","factor(Year)2008","factor(Year)2009","factor(Year)2010","factor(Year)2011","factor(Year)2012","factor(Year)2013","factor(Year)2014","factor(Year)2015","factor(Year)2016","factor(Year)2017","factor(Year)2018","factor(Year)2019","factor(Year)2020"),title="Fixed-Effect model" ,dv.labels = c("Age profile, not controlled for experience"))

## run with 17
summary(fixed11<- plm(Salary_inflation_adj ~ factor(Experience)+factor(Age)+ws+Teams_played+Sum_G+All.star+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+factor(Year), data=filter(dataset, Year > 2006  ), model="within",index = c("Player", "Year"), vcov=vcovHC(fixed11, method = "arellano") ))
summary(fixed11<- plm(Salary_inflation_adj ~ factor(Experience)+factor(Age)+ws+Teams_played+Sum_G+All.star+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center+factor(Year), data=filter(dataset,Year>2005), model="within",index = c("Player", "Year"), within=TRUE  ))
summary(fixed11, vcov = function(Player) vcovHC(Player, method = "arellano"))

summary(fixed11<- plm(Salary_inflation_adj ~ Experience+Experience_squared+Age+Age_squared+ws+Teams_played+Sum_G+All.star+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center+factor(Year), data=filter(dataset,Year>2005), model="within",index = c("Player", "Year"), within=TRUE  ))

ols4$coefficients

coeftest(fixed11, vcov = vcovHC, type = "HC0")

coeftest(ols4, vcov = vcovHC, type = "HC0")

coeftest(ols5, vcov = vcovHC, type = "HC0")
coeftest(ols6, vcov = vcovHC, type = "HC0")
tab_model(ols5,ols6,vcov.fun = "vcovHC" , vcov.type = "HC0",p.style="stars",show.obs=TRUE,show.se=TRUE,collapse.se=TRUE)
tab_model(ols4,vcov.fun = "vcovHC" , vcov.type = "HC0",p.style="stars",show.obs=TRUE,show.se=TRUE,collapse.se=TRUE)


##-------Robust t test--------
coeftest(ols, vcov = vcovHC(ols, type = "HC0"))

nrow(dataset$Teams_played)


summary(ols1<- lm(Salary_inflation_adj ~ Teams_played+Sum_G+Sum_GS+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+all_star+ factor(Age), data=filter(dataset_test, Year == 2001)  ))



##-----Different years------
summary(ols2001<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2001)  ))
summary(ols2002<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2002)  ))
summary(ols2003<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2003)  ))
summary(ols2004<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2004)  ))
summary(ols2005<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2005)  ))
summary(ols2006<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2006)  ))
summary(ols2007<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2007)  ))
summary(ols2008<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2008)  ))
summary(ols2009<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2009)  ))
summary(ols2010<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2010)  ))
summary(ols2011<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2011)  ))
summary(ols2012<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2012)  ))
summary(ols2013<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2013)  ))
summary(ols2014<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2014)  ))
summary(ols2015<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2015)  ))
summary(ols2016<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2016)  ))
summary(ols2017<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2017)  ))
summary(ols2018<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2018)  ))
summary(ols2019<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2019)  ))
summary(ols2020<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset_test, Year == 2020)  ))
 
summary(ols2001<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2001)  ))
summary(ols2002<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2002)  ))
summary(ols2003<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2003)  ))
summary(ols2004<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2004)  ))
summary(ols2005<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2005)  ))
summary(ols2006<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2006)  ))
summary(ols2007<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2007)  ))
summary(ols2008<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2008)  ))
summary(ols2009<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2009)  ))
summary(ols2010<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2010)  ))
summary(ols2011<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2011)  ))
summary(ols2013<- lm(Salary_inflation_adj ~ factor(Age)+ factor(Experience)+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2013)  ))
summary(ols2014<- lm(Salary_inflation_adj ~ factor(Age)+ factor(Experience)+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2014)  ))
summary(ols2015<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2015)  ))
summary(ols2016<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2016)  ))
summary(ols2017<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2017)  ))
summary(ols2018<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2018)  ))
summary(ols2019<- lm(Salary_inflation_adj ~ factor(Age)+factor(Experience)+  Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2019)  ))
summary(ols2020<- lm(Salary_inflation_adj ~ factor(Age)+ factor(Experience)+ Teams_played+Sum_G+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+All.star, data=filter(dataset, Year == 2020)  ))
tab_model(ols2001,ols2002,ols2003,ols2004,ols2005,ols2006,ols2007,ols2008,ols2009,ols2010,p.style = "stars",show.ci=FALSE, vcov.type = c("HC0"),vcov.fun = "vcovHC" ,show.obs=TRUE,show.se=TRUE,collapse.se=TRUE,title="OLS Age Profile by every season (year) 2000-2010",dv.labels = c("2000-2001" ,"2001-2002","2002-2003","2003-2004","2004-2005" ,"2005-2006","2006-2007","2007-2008" ,"2008-2009","2009-2010"))
tab_model(ols2011,ols2013,ols2014,ols2015,ols2016,ols2017,ols2018,ols2019,ols2020,p.style = "stars",show.ci=FALSE,vcov.type = c("HC0"),vcov.fun = "vcovHC" ,show.obs=TRUE,show.se=TRUE,collapse.se=TRUE,title="OLS Age Profile by every season (year) 2010-2020",dv.labels = c("2010-2011" ,"2012-2013","2013-2014" ,"2014-2015","2015-2016","2016-2017","2017-2018" ,"2018-2019","2019-2020"))
tab_model(ols2016,ols2017,ols2018,ols2019,ols2020,p.style = "stars",show.ci=FALSE,vcov.type = c("HC0"),vcov.fun = "vcovHC" ,show.obs=TRUE,show.se=TRUE,collapse.se=TRUE,title="OLS Age Profile by every season (year) 2010-2020",dv.labels = c("2010-2011" ,"2012-2013","2013-2014" ,"2014-2015","2015-2016","2016-2017","2017-2018" ,"2018-2019","2019-2020"))

##-----U shape curve-----------

summary(ols_linear<- lm(Salary_inflation_adj ~ Age,data=dataset_test  ))
summary(ols_squared<- lm(Salary_inflation_adj ~ Age+ Age_squared, data=dataset_test  ))
tab_model(ols_squared,ols_linear)

ols_linear#-------------------------Calculations--------------------
data_2015<-filter(dataset_test, Year == 2015)
summary(ols1<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Sum_GS+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+all_star, data=data_2015  ))
summary(ols_3<- lm(Salary_inflation_adj ~ Age+ Age_squared+ Teams_played+Sum_G+Sum_GS+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+all_star, data=filter(dataset_test, Year == 2014)  ))

summary(ols2<- lm(Salary_inflation_adj ~ Age+ Age_squared+Teams_played+Sum_G+Sum_GS+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center+all_star, data=data_2015   ))

general<- plm(Salary_inflation_adj ~  Age+ Age_squared + Teams_played+Sum_G+Sum_GS+Avg_MP+TRB_36+AST_36+STL_36+BLK_36+PTS_36+Pk+Forward+Center+factor(Year)-1, data=dataset_test, model="within",index = c("Player"))
summary(general)
tab_model(general)
summary(general2<- plm(Salary_inflation_adj ~  Age+ Age_squared+Teams_played+Sum_G+Sum_GS+Avg_MP+Avg_TRB+Avg_AST+Avg_STL+Avg_BLK+Avg_PTS+Pk+Forward+Center+factor(Year), data=dataset_test, model="within",index = c("Player"),   ))
#-----------------
library(jtools)
ols4<-coeftest(ols4, vcov = vcovHC, type = "HC0")
## DATASET 12
jtools::plot_summs(ols4,ci_level = 0.95,robust = TRUE,coefs = c("Age 21"="factor(Age)21","Age 22"="factor(Age)22","Age 23"="factor(Age)23" ,"Age 24"="factor(Age)24",
                                                                "Age 25"="factor(Age)25","Age 26"="factor(Age)26","Age 27"="factor(Age)27",
                                                                "Age 28"="factor(Age)28","Age 29"="factor(Age)29","Age 30"="factor(Age)30",
                                                                "Age 31"="factor(Age)31","Age 32"="factor(Age)32","Age 33"="factor(Age)33",
                                                                "Age 34"="factor(Age)34","Age 35"="factor(Age)35","Age 36"="factor(Age)36",
                                                                "Age 37"="factor(Age)37","Experience 1"="factor(Experience)1","Experience 2"="factor(Experience)22",
                                                                "Experience 3"="factor(Experience)3" ,"Experience 4"="factor(Experience)4",
                                                                "Experience 5"="factor(Experience)5","Experience 6"="factor(Experience)6","Experience 7"="factor(Experience)7",
                                                                "Experience 8"="factor(Experience)8","Experience 9"="factor(Experience)9","Experience 10"="factor(Experience)10",
                                                                "Experience 11"="factor(Experience)11","Experience 12"="factor(Experience)12","Experience 13"="factor(Experience)13",
                                                                "Experience 14"="factor(Experience)14","Experience 15"="factor(Experience)15","Experience 16"="factor(Experience)16",
                                                                "Experience 17"="factor(Experience)17","Experience 18"="factor(Experience)18"))


## DATASET 17 ,legend.title = "Fixed-effect Age and Experience Profiles"
jtools::plot_summs(fixed11,ols4,ci_level = 0.95,robust = TRUE, coefs = c("Age 21"="factor(Age)21","Age 22"="factor(Age)22","Age 23"="factor(Age)23" ,"Age 24"="factor(Age)24",
                "Age 25"="factor(Age)25","Age 26"="factor(Age)26","Age 27"="factor(Age)27",
                         "Age 28"="factor(Age)28","Age 29"="factor(Age)29","Age 30"="factor(Age)30",
                                              "Age 31"="factor(Age)31","Age 32"="factor(Age)32","Age 33"="factor(Age)33",
               "Age 34"="factor(Age)34","Age 35"="factor(Age)35","Age 36"="factor(Age)36",
                                   "Age 37"="factor(Age)37","Experience 1"="factor(Experience)1","Experience 2"="factor(Experience)22",
               "Experience 3"="factor(Experience)3" ,"Experience 4"="factor(Experience)4",
                           "Experience 5"="factor(Experience)5","Experience 6"="factor(Experience)6","Experience 7"="factor(Experience)7",
                                "Experience 8"="factor(Experience)8","Experience 9"="factor(Experience)9","Experience 10"="factor(Experience)10",
                "Experience 11"="factor(Experience)11","Experience 12"="factor(Experience)12","Experience 13"="factor(Experience)13",
                        "Experience 14"="factor(Experience)14","Experience 15"="factor(Experience)15","Experience 16"="factor(Experience)16",
                               "Experience 17"="factor(Experience)17","Experience 18"="factor(Experience)18"))















d = as.dist(matrix(c(0, 0.2, 0.6, 0.4,0.8, 
                     0.2, 0, 0.17, 0.5,0.22,
                     0.6, 0.17, 0, 0.65,0.7,
                     0.4, 0.5, 0.65, 0,0.9,
                     0.8,0.22,0.7,0.9,0), nrow = 5))

plot(hclust(d, method = "complete"))
plot(hclust(d, method = "single"))


plot(hclust(d, method = "complete"), labels = c(4,3,2,1,5))

d = as.dist(matrix(data.frame(Knyga1)),nrow=18)
d=as.dist(d,nrow=18)
exp<-c(2^0,2^1,2^2,2^3,2^4,2^5,2^6,2^7,2^8,2^9,2^10,2^11,2^12,2^13,2^14,2^15,2^16,2^17)
a<- dist(exp, method = "euclidean")
hc1 <- hclust(a, method = "complete" )
plot(hc1)
hc2 <- hclust(a, method = "single" )
plot(hc2)
hc3 <- hclust(a, method = "average" )
plot(hc3)


Knyga1 <- read_excel("C:/Users/Euronics/Desktop/Knyga1.xlsx")
View(Knyga1)
colnames(Knyga1)<-c("1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18")
dd <- as.dist(Knyga1)
round(1000 * dd) 
plot(hclust(dd)) 
hclust(dd)
plot(hclust(dd, method = "complete" ))
plot(hclust(dd, method = "single" ))
plot(hclust(dd, method = "average" ))
