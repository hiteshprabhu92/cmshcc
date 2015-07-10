icd9RiskAdjCMSHCC13 <- function(DIAG, PERSON, cmshcc_list, date = Sys.Date(), factor_list = factors) {
  PERSON$AGE <- as.numeric(round(difftime(date, as.Date(PERSON$DOB, "%Y-%m-%d", tz = "UTC"), units = "weeks")/52.25))
  PERSON$DISABL <- (PERSON$AGE < 65) & (PERSON$OREC != 0)
  PERSON$ORIGDS <- (PERSON$AGE >= 65) & (PERSON$OREC %in% c(1,3))
  breaks <- c(0, 35, 45, 55, 60, 65, 70, 75, 80, 85, 90, 95, 120)
  PERSON$AGE_BAND <- cut(x = PERSON$AGE, breaks = breaks, include.lowest = TRUE, right = FALSE)
  
  female_age_factors <- factor_list$female_age_factors
  male_age_factors <- factor_list$male_age_factors
  PERSON$AGEGENDER_SCORE <- (PERSON$SEX == 1) * male_age_factors[PERSON$AGE_BAND] + (PERSON$SEX == 2) * female_age_factors[PERSON$AGE_BAND]
  
  PERSON$MCAID_FEMALE_AGED <- (PERSON$MCAID == 1) & (PERSON$SEX == 2) & (PERSON$DISABL == 0)
  PERSON$MCAID_FEMALE_DISABL <- (PERSON$MCAID == 1) & (PERSON$SEX == 2) & (PERSON$DISABL == 1)
  PERSON$MCAID_MALE_AGED <- (PERSON$MCAID == 1) & (PERSON$SEX == 1) & (PERSON$DISABL == 0)
  PERSON$MCAID_MALE_DISABL <- (PERSON$MCAID == 1) & (PERSON$SEX == 2) & (PERSON$DISABL == 1)
  PERSON$ORIGDS_FEMALE <- (PERSON$ORIGDS == 1) & (PERSON$SEX == 2)
  PERSON$ORIGDS_MALE <- (PERSON$ORIGDS == 1) & (PERSON$SEX == 1)
  
  demointeraction_factors <- factor_list$demointeraction_factors
  PERSON$DEMOINTERACTION_SCORE <- as.matrix(PERSON[,c("MCAID_FEMALE_AGED", "MCAID_FEMALE_DISABL", "MCAID_MALE_AGED", "MCAID_MALE_DISABL", "ORIGDS_FEMALE", "ORIGDS_MALE")]) %*% demointeraction_factors
  
  #Evaluate using icd9 package by Jack Wasey
  PERSON <- cbind(PERSON, as.data.frame(icd9Comorbid(icd9df = DIAG, icd9Mapping = cmshcc_list, visitId = "HICNO")))
  
  #Apply Hierarchies
  PERSON$HCC112 <- PERSON$HCC112 & (!PERSON$HCC5)
  PERSON$HCC10 <- PERSON$HCC10 & (!PERSON$HCC9) & (!PERSON$HCC8) & (!PERSON$HCC7)
  PERSON$HCC9 <- PERSON$HCC9 & (!PERSON$HCC8) & (!PERSON$HCC7)
  PERSON$HCC8 <- PERSON$HCC8 & (!PERSON$HCC7)
  PERSON$HCC19 <- PERSON$HCC19 & (!PERSON$HCC18) & (!PERSON$HCC17) & (!PERSON$HCC16) & (!PERSON$HCC15)
  PERSON$HCC18 <- PERSON$HCC18 & (!PERSON$HCC17) & (!PERSON$HCC16) & (!PERSON$HCC15)
  PERSON$HCC17 <- PERSON$HCC17 & (!PERSON$HCC16) & (!PERSON$HCC15)
  PERSON$HCC16 <- PERSON$HCC16 & (!PERSON$HCC15)
  PERSON$HCC27 <- PERSON$HCC27 & (!PERSON$HCC26) & (!PERSON$HCC25)
  PERSON$HCC26 <- PERSON$HCC26 & (!PERSON$HCC25)
  PERSON$HCC52 <- PERSON$HCC52 & (!PERSON$HCC51)
  PERSON$HCC54 <- PERSON$HCC54 & (!PERSON$HCC55)
  PERSON$HCC157 <- PERSON$HCC157 & (!PERSON$HCC69) & (!PERSON$HCC68) & (!PERSON$HCC67)
  PERSON$HCC101 <- PERSON$HCC101 & (!PERSON$HCC100) & (!PERSON$HCC68) & (!PERSON$HCC67)
  PERSON$HCC69 <- PERSON$HCC69 & (!PERSON$HCC68) & (!PERSON$HCC67)
  PERSON$HCC100 <- PERSON$HCC100 & (!PERSON$HCC68) & (!PERSON$HCC67)
  PERSON$HCC68 <- PERSON$HCC68 & (!PERSON$HCC67)
  PERSON$HCC79 <- PERSON$HCC79 & (!PERSON$HCC78) & (!PERSON$HCC77)
  PERSON$HCC78 <- PERSON$HCC78 & (!PERSON$HCC77)
  PERSON$HCC83 <- PERSON$HCC83 & (!PERSON$HCC82) & (!PERSON$HCC81)
  PERSON$HCC82 <- PERSON$HCC82 & (!PERSON$HCC81)
  PERSON$HCC96 <- PERSON$HCC96 & (!PERSON$HCC95)
  PERSON$HCC105 <- PERSON$HCC105 & (!PERSON$HCC104)
  PERSON$HCC149 <- PERSON$HCC149 & (!PERSON$HCC148) & (!PERSON$HCC104)
  PERSON$HCC108 <- PERSON$HCC108 & (!PERSON$HCC107)  
  PERSON$HCC132 <- PERSON$HCC132 & (!PERSON$HCC131) & (!PERSON$HCC130)
  PERSON$HCC131 <- PERSON$HCC131 & (!PERSON$HCC130)
  PERSON$HCC75 <- PERSON$HCC75 & (!PERSON$HCC154)
  PERSON$HCC155 <- PERSON$HCC155 & (!PERSON$HCC154)
  PERSON$HCC177 <- PERSON$HCC177 & (!PERSON$HCC161)
  
  #Generate Disease Scores
  disease_factors <- factor_list$disease_factors
  PERSON$DISEASE_SCORE <- as.matrix(PERSON[, names(cmshcc_list)]) %*% disease_factors
  
  #Condition Category Groupings
  PERSON$DM <- PERSON$HCC15 | PERSON$HCC16 | PERSON$HCC17 | PERSON$HCC18 | PERSON$HCC19
  PERSON$CHF <- PERSON$HCC80
  PERSON$COPD <- PERSON$HCC108
  PERSON$CVD <- PERSON$HCC95 | PERSON$HCC96 | PERSON$HCC100 | PERSON$HCC101
  PERSON$CAD <- PERSON$HCC81 | PERSON$HCC82 | PERSON$HCC83
  PERSON$RF <- PERSON$HCC131
  
  #Disease x Disease Interaction Terms
  PERSON$DM_CHF <- PERSON$DM & PERSON$CHF
  PERSON$DM_CVD <- PERSON$DM & PERSON$CVD
  PERSON$CHF_COPD <- PERSON$CHF & PERSON$COPD
  PERSON$COPD_CVD_CAD <- PERSON$COPD & PERSON$CVD & PERSON$CAD
  PERSON$RF_CHF <- PERSON$RF & PERSON$CHF
  PERSON$RF_CHF_DM <- PERSON$RF & PERSON$CHF & PERSON$DM & (!PERSON$DM_CHF) & (!PERSON$RF_CHF)
  
  interaction_terms <- c("DM_CHF", "DM_CVD", "CHF_COPD", "COPD_CVD_CAD", "RF_CHF", "RF_CHF_DM")
  interaction_factors <- factor_list$interaction_factors
  PERSON$DISEASE_INTERACTION <- as.matrix(PERSON[, interaction_terms]) %*% interaction_factors
  
  #Disability x Disease Interaction Terms
  PERSON$DISABL_HCC5 <- PERSON$DISABL & PERSON$HCC5
  PERSON$DISABL_HCC44 <- PERSON$DISABL & PERSON$HCC44
  PERSON$DISABL_HCC51 <- PERSON$DISABL & PERSON$HCC51
  PERSON$DISABL_HCC52 <- PERSON$DISABL & PERSON$HCC52
  PERSON$DISABL_HCC107 <- PERSON$DISABL & PERSON$HCC107
  
  disabl_int_terms <- c("DISABL_HCC5", "DISABL_HCC44", "DISABL_HCC51", "DISABL_HCC52", "DISABL_HCC107")
  disabl_int_factors <- factor_list$disabl_int_factors
  PERSON$DISABL_INTERACTION <- as.matrix(PERSON[, disabl_int_terms]) %*% disabl_int_factors
  
  #Total Risk Adjustment Scores
  PERSON$TOTAL <- PERSON$AGEGENDER_SCORE + PERSON$DEMOINTERACTION_SCORE + PERSON$DISEASE_SCORE + PERSON$DISEASE_INTERACTION + PERSON$DISABL_INTERACTION
  return(PERSON$TOTAL)
}