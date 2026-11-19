# Alpha Manufacturing D3. Run after the approved alpha_data_connection.R.
# Read-only analysis; no employee records are written to disk.
library(dplyr)
stopifnot(nrow(employees)==14999, !anyDuplicated(employees$employee_id))
for (x in list(compensation_training, employee_surveys, exit_interviews)) {
  stopifnot(!anyDuplicated(x$employee_id), all(x$employee_id %in% employees$employee_id))
}
alpha <- employees %>% left_join(compensation_training, by='employee_id') %>%
  left_join(employee_surveys, by='employee_id') %>% left_join(exit_interviews, by='employee_id')
stopifnot(nrow(alpha)==14999, !anyDuplicated(alpha$employee_id), all(alpha$left %in% 0:1),
  all(as.Date(alpha$baseline_date)==as.Date('2024-12-31')),
  all(as.Date(alpha$reporting_end_date)==as.Date('2025-12-31')),
  all(!is.na(alpha$departure_date[alpha$left==1])),
  all(format(as.Date(alpha$departure_date[alpha$left==1]),'%Y')=='2025'))
print(table(alpha$left)); print(table(alpha$separation_type[alpha$left==1]))
for (g in c('department','plant','job_role','shift','salary_band')) {
  out <- alpha %>% group_by(.data[[g]]) %>% summarise(employees=n(), departed=sum(left==1), rate=100*mean(left==1), .groups='drop') %>% filter(employees>=10) %>% arrange(desc(rate))
  print(as.data.frame(out))
  tab <- table(alpha[[g]],alpha$left); tab <- tab[rowSums(tab)>=10,,drop=FALSE]
  test <- chisq.test(tab); print(test); print(min(test$expected))
}
monthly <- alpha %>% filter(left==1) %>% mutate(month=format(as.Date(departure_date),'%Y-%m'))
print(as.data.frame(count(monthly,month))); print(as.data.frame(count(monthly,month,separation_type)))
vars <- c('satisfaction_level','last_evaluation','number_project','average_monthly_hours','time_spend_company','annual_base_pay_usd','training_hours_2024')
for(v in vars){
  a <- alpha[[v]][alpha$left==1]; b <- alpha[[v]][alpha$left==0]
  print(v); print(c(leaver_n=sum(!is.na(a)),stayer_n=sum(!is.na(b)),leaver_mean=mean(a,na.rm=TRUE),stayer_mean=mean(b,na.rm=TRUE))); print(t.test(a,b))
}
for(v in c('promotion_last_5years','work_accident')){
  tab <- table(alpha[[v]],alpha$left); print(v); print(tab); print(100*prop.table(tab,2)); print(chisq.test(tab))
}
print(alpha %>% group_by(left) %>% summarise(employees=n(), respondents=sum(!is.na(survey_id)), response_rate=100*mean(!is.na(survey_id))))
scores <- c('supervisor_support_score','schedule_predictability_score','career_opportunity_score','work_life_balance_score')
for(v in scores){
  a <- alpha[[v]][alpha$left==1]; b <- alpha[[v]][alpha$left==0]
  print(v); print(c(leaver_n=sum(!is.na(a)),stayer_n=sum(!is.na(b)),leaver_mean=mean(a,na.rm=TRUE),stayer_mean=mean(b,na.rm=TRUE))); print(wilcox.test(a,b,exact=FALSE))
}
ex <- alpha %>% filter(left==1)
print(ex %>% group_by(separation_type) %>% summarise(leavers=n(), interviews=sum(!is.na(exit_interview_id)), rate=100*mean(!is.na(exit_interview_id))))
responded <- ex %>% filter(!is.na(exit_interview_id))
print(responded %>% count(primary_departure_reason) %>% mutate(pct=100*n/sum(n)) %>% filter(n>=10))
print(responded %>% count(separation_type,primary_departure_reason) %>% group_by(separation_type) %>% mutate(pct=100*n/sum(n)) %>% filter(n>=10))
matched <- responded %>% filter(separation_type=='voluntary',!is.na(survey_id),!is.na(primary_departure_reason),as.Date(survey_date)<as.Date(departure_date))
print(matched %>% group_by(primary_departure_reason) %>% summarise(respondents=n(),across(all_of(scores),~mean(.x,na.rm=TRUE)),.groups='drop') %>% filter(respondents>=10))
# Additional D2-required tests: pending execution and reporting.
reason_map <- c(career_growth='career_opportunity_score',supervision='supervisor_support_score',schedule='schedule_predictability_score',workload='work_life_balance_score')
for(r in names(reason_map)){
  v <- reason_map[[r]]; a <- matched[[v]][matched$primary_departure_reason==r]; b <- matched[[v]][matched$primary_departure_reason!=r]
  print(r); print(c(reason_n=sum(!is.na(a)),other_n=sum(!is.na(b)),reason_mean=mean(a,na.rm=TRUE),other_mean=mean(b,na.rm=TRUE))); print(wilcox.test(a,b,exact=FALSE))
}
