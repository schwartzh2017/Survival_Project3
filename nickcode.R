library(survival)
library(tidyverse)
library(autoplotly)
library(survminer)

setwd('/Users/nick/Documents/Willamette/Spring23/Survival/GroupProject3/githubSurvival/data')

meta_r_ds = read_csv('metadata-r.csv')
meta_wp_ds = read_csv('metadata-wp.csv')
meta_npm_ds = read_csv('metadata-npm.csv')
meta_laravel_ds = read_csv('metadata-laravel.csv')

oracle_r_ds = read_csv('oracle-r.csv')
oracle_wp_ds = read_csv('oracle-wp.csv')
oracle_npm_ds = read_csv('oracle-npm.csv')
oracle_laravel_ds = read_csv('oracle-laravel.csv')

evolutionPaths_r_ds = read_csv('evolutionPaths-r.csv')
evolutionPaths_wp_ds = read_csv('evolutionPaths-wp.csv')
evolutionPaths_npm_ds = read_csv('evolutionPaths-npm.csv')
evolutionPaths_laravel_ds = read_csv('evolutionPaths-laravel.csv')

allData_r_ds = read_csv('AllData-r.csv')
allData_wp_ds = read_csv('AllData-wp.csv')
allData_npm_ds = read_csv('AllData-npm.csv')
allData_laravel_ds = read_csv('AllData-laravel.csv')

allDataMonth_r_ds = read_csv('AllData-Month-r.csv')
allDataMonth_wp_ds = read_csv('AllData-Month-wp.csv')
allDataMonth_npm_ds = read_csv('AllData-Month-npm.csv')
allDataMonth_laravel_ds = read_csv('AllData-Month-laravel.csv')

meta_ds = meta_r_ds %>%
  rbind(meta_wp_ds) %>%
  rbind(meta_npm_ds) %>%
  rbind(meta_laravel_ds)

oracle_ds = oracle_laravel_ds %>%
  rbind(oracle_npm_ds) %>%
  rbind(oracle_r_ds) %>%
  rbind(oracle_wp_ds)

evolutionPaths_ds = evolutionPaths_laravel_ds %>%
  rbind(evolutionPaths_npm_ds) %>%
  rbind(evolutionPaths_r_ds) %>%
  rbind(evolutionPaths_wp_ds)

allData_ds = allData_laravel_ds %>%
  rbind(allData_npm_ds) %>%
  rbind(allData_r_ds) %>%
  rbind(allData_wp_ds)

allDataMonth_ds = allDataMonth_laravel_ds %>%
  rbind(allDataMonth_npm_ds) %>%
  rbind(allDataMonth_r_ds) %>%
  rbind(allDataMonth_wp_ds)

# descriptive plots; number of repos per status by repo type, repo size

ggplot(data = meta_ds, aes(x = status, fill = repoType)) +
  geom_bar(position = 'dodge') +
  labs(x = 'Current Status of Repo', y = 'Number of Repos',
       title = 'Current Status of Repository by Type of Repository',
       fill = "Type of Repository") +
  theme_minimal()

ggplot(data = meta_ds, aes(x = status, fill = factor(sizeUsers))) +
  geom_bar(position = 'dodge') +
  labs(x = 'Current Status of Repo', y = 'Number of Repos',
       title = 'Current Status of Repository by Size of Userbase',
       fill = "Size of Repository Userbase") +
  theme_minimal()

# number of commits, organization vs user
km.commits_org_v_user = survfit(Surv(commits)~type, data = oracle_ds)

ggsurvplot(data = oracle_ds, fit = km.commits_org_v_user, xlim = c(0, 1000),
           break.x.by = 250) +
  labs(x = 'Number of Commits', title = "Number of Commits by Repository Type")

oraclemodel = survreg(Surv(commits)~type,data=oracle_ds, dist = "lognormal")

pred.oracle = predict(oraclemodel,
                  data.frame(type=unique(oracle_ds$type)),
                  type="quantile",
                  p=seq(0.01,0.99,0.01),
                  se.fit = T)
predFit=tibble(quantile=seq(0.01,0.99,0.01), as.data.frame(t(pred.oracle$fit)) )
names(predFit) = c('p', unique(oracle_ds$type))
km.oracle_tib=tibble(type=rep(names(km.commits_org_v_user$strata),times=km.commits_org_v_user$strata),
                           commits=km.commits_org_v_user$time,surv=km.commits_org_v_user$surv) %>%
  mutate(type = ifelse(type == 'type=Organization', 'Organization', 'User'))

predFit %>%
  pivot_longer('Organization':'User', names_to = "type", values_to = "commits") %>%
  ggplot(aes(x=commits,y=rev(p),color=type)) +
  geom_line(linewidth=1.1) +
  geom_line(data=km.oracle_tib,aes(x=commits,y=surv)) +
  theme_minimal() +
  xlim(0,1000)+
  labs(x = "Number of Commits", y = "Survival Probability",
       title = "Lognormal Distribution vs KM Curve: Number of Commits by Repository Type",
       color = "Type of Repository")

AIC(survreg(Surv(commits)~type,data=oracle_ds, dist = "lognormal"))
AIC(survreg(Surv(commits)~type,data=oracle_ds, dist = "weibull"))
AIC(survreg(Surv(commits)~type,data=oracle_ds, dist = "exp"))

# degradation path: number of status changes over lifetime
try = evolutionPaths_ds %>%
  mutate(path_list = str_split(path, '-'))

try = try %>%
  unnest(path_list)

try %>%
  mutate(months = as.numeric(gsub("\\D", "", path_list)))

try2 = evolutionPaths_ds %>%
  inner_join(meta_ds, by = 'repo_name')

try2 = try2 %>%
  mutate(path = paste(path, months, sep = '_'))

try2 = try2 %>%
  mutate(path_list = str_split(path, '-'))

try2 = try2 %>%
  unnest(path_list)

try2 = try2 %>%
  mutate(months = as.numeric(gsub("\\D", "", path_list)))

fullpath_dead_ds = try2 %>%
  mutate(path_status = case_when(str_detect(path_list, 'Dead')~'Dead',
                                 str_detect(path_list, 'Alive')~'Alive',
                                 str_detect(path_list, 'Zombie')~'Zombie')) %>%
  select(-path, -sizeUsers, -path_list) %>%
  filter(status == 'Dead')

fullpath_dead_ds = fullpath_dead_ds %>%
  group_by(repo_name) %>%
  mutate(months_cumulative = cumsum(months)) %>%
  mutate(events_total = row_number())

end_ds = fullpath_dead_ds %>%
  group_by(repo_name) %>%
  filter(months == max(months))


times = unique(fullpath_dead_ds$months_cumulative)

mcf_ds=tibble(time=NULL,avgEvents=NULL,totalEvents=NULL,riskSet=NULL)

for (i in times){
  reposInRiskSet = end_ds %>%
    filter(months_cumulative >= i) %>%
    pull(repo_name)
  
  event_i = fullpath_dead_ds %>%
    group_by(repo_name) %>%
    summarise(totalEvents = sum(months_cumulative <= i))
  
  mcf_ds = bind_rows(mcf_ds, 
                     tibble(time = i,
                            avgEvents = mean(event_i$totalEvents),
                            totalEvents = sum(event_i$totalEvents),
                            riskSet = length(reposInRiskSet)))
}

mcf_ds %>%
  ggplot(aes(x = time, y = avgEvents)) +
  geom_step(color = 'purple3', linewidth = 1.5) +
  labs(x = 'Months', y = 'Average Number of Status Changes',
       title = 'MCF Plot for Average Number of Status Changes of Github Repositories') +
  theme_minimal() +
  xlim(0,150)


AIC(survreg(Surv(avgEvents)~time, data = mcf_ds, dist = 'weibull'))

mcf_ds %>%
  ggplot(aes(x = time, y = avgEvents)) +
  geom_step(color = 'purple3', linewidth = 1.25) +
  labs(x = 'Months', y = 'Average Number of Status Changes',
       title = 'MCF Plot for Average Number of Status Changes of Github Repositories') +
  theme_minimal() +
  xlim(0,150) +
  geom_smooth(color = 'gold')





