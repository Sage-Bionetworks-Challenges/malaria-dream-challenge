rm(list=ls())
library(synapser)
library("pROC")
library(plyr)

synLogin()
#change location to where ever this code it.
setwd("~/Desktop/SageCode/MalariaDREAMChallenge/")
sc1Subs    <- read.csv("sc1_SubIds.txt")
sc2Subs    <- read.csv("sc2_SubIds.txt")
mdcSC1gs   <- read.csv(synGet("syn20186307")$path); mdcSC1gs <- mdcSC1gs[order(mdcSC1gs$Isolate_Number),]
mdcSC2gs   <- read.csv(synGet("syn20186336")$path); mdcSC2gs <- mdcSC2gs[order(mdcSC2gs$Isolate_Number),] 

sc1Vals <- lapply(sc1Subs$objectId, function(x){temp <- read.csv(synGetSubmission(x)$filePath,sep="\t"); return(temp[order(temp$Isolate),"Predicted_IC50"])})
names(sc1Vals) <- sc1Subs$objectId
sc1Vals <- as.data.frame(sc1Vals); rownames(sc1Vals) <- mdcSC1gs$Isolate_Number
sc1Teams <- unlist(lapply(sc1Subs$objectId,function(x){
  temp <- synGetSubmission(x); 
  if(is.null(temp$teamId)){ ret <- synGetUserProfile(temp$userId)$userName }else{ ret <- synGetTeam(temp$teamId)$name; } 
  return(ret); }))

sc2Vals <- lapply(sc2Subs$objectId, function(x){temp <- data.table::fread(synGetSubmission(x)$filePath,data.table = F); return(temp[order(temp$Isolate),"Probability"])})
names(sc2Vals) <- sc2Subs$objectId
sc2Vals <- as.data.frame(sc2Vals); rownames(sc2Vals) <- mdcSC2gs$Isolate_Number
sc2Teams <- unlist(lapply(sc2Subs$objectId,function(x){
  temp <- synGetSubmission(x); 
  if(is.null(temp$teamId)){ ret <- synGetUserProfile(temp$userId)$userName }else{ ret <- synGetTeam(temp$teamId)$name; } 
  return(ret); }))

sc1Scores <- data.frame(submission=sc1Subs$objectId,Spearman=cor(sc1Vals, mdcSC1gs$DHA_IC50, method = "spearman"))
#sc1Scores <- sc1Scores[order(sc1Scores$Spearman, decreasing = T),]
sc2ScoresSpearman <- data.frame(submission=sc2Subs$objectId,Spearman=cor(sc2Vals, -mdcSC2gs$Clearance, method = "spearman"))
#sc2ScoresSpearman <- sc2ScoresSpearman[order(sc2ScoresSpearman$Spearman, decreasing = T),]
sc2ScoresAuc <- data.frame(submission=sc2Subs$objectId,Auc=apply(sc2Vals, 2, function(x){pROC::auc(response = mdcSC2gs$Clearance < 5,  predictor=x, direction ="<")}))
#sc2ScoresAuc <- sc2ScoresAuc[order(sc2ScoresAuc$Auc, decreasing = T),]
sc2ScoreSAveRank <- data.frame(submission=sc2Subs$objectId,aveRank = rank(rank(-sc2ScoresSpearman$Spearman, ties.method = "min")+rank(-sc2ScoresAuc$Auc, ties.method = "min"), ties.method = "min"))

#Bayes Factor calculations... M is the matrix of Bootstrapped scores used for computing the bayes factor and used for ploting score distributions
topSc1 <- "MD_DUTeam"
topSc2 <- "yuanfang.guan"
N      <- 1000

pdf("bootstrappedDistributions.pdf",height = 10,width = 7)
# SC1
set.seed(15)
inds1    <- matrix(1:nrow(mdcSC1gs), nrow(mdcSC1gs), N)
inds1    <- alply(inds1,.margins = 2, sample, size = nrow(inds1), replace=T)
M1       <- as.data.frame(llply(inds1, .fun = function(tInds){cor(sc1Vals[tInds,], mdcSC1gs$DHA_IC50[tInds], method = "spearman")}))
rownames(M1) <- sc1Teams
M1Sorted <- M1[order(sc1Scores$Spearman, decreasing = F),]
par(mar=c(5,9,2,2)+.1)
boxplot(t(M1Sorted), outline=F, horizontal =T, las=2, main="SC1 Bootstrapped Distributions", xlab="Spearman Correlation")
bf1      <- apply(M1,1, function(m){topM1 <- M1[which(rownames(M1) == topSc1),]; sum(m <= topM1)/sum(m > topM1)})
bf1[names(bf1) == topSc1] <- NA

# SC2  
inds2        <- matrix(1:nrow(mdcSC2gs), nrow(mdcSC2gs), N)
inds2        <- alply(inds2,.margins = 2, sample, size = nrow(inds2), replace=T)
M2spearman   <- as.data.frame(llply(inds2, .fun = function(tInds){cor(sc2Vals[tInds,], -mdcSC2gs$Clearance[tInds], method = "spearman")}))
rownames(M2spearman) <- sc2Teams
M2spearmanSorted <- M2spearman[order(sc2ScoresSpearman$Spearman, decreasing = F),]
boxplot(t(M2spearmanSorted), outline=F, horizontal =T, las=2,main="SC2 Bootstrapped Distributions", xlab="Spearman Correlation")
bf2Spearman  <- apply(M2spearman,1, function(m){topM2 <- M2spearman[which(rownames(M2spearman) == topSc2),]; sum(m <= topM2)/sum(m > topM2)})
bf2Spearman[names(bf2Spearman) == topSc2] <- NA

M2AUC   <- as.data.frame(llply(inds2, .fun = function(tInds){apply(sc2Vals[tInds,], 2, function(x){pROC::auc(response = mdcSC2gs$Clearance[tInds] < 5,  predictor=x, direction ="<")})}))
rownames(M2AUC) <- sc2Teams
M2AUCSorted <- M2AUC[order(sc2ScoresAuc$Auc, decreasing = F),]
boxplot(t(M2AUCSorted), outline=F, horizontal =T, las=2,main="SC2 Bootstrapped Distributions", xlab="ROC AUC")
bf2AUC  <- apply(M2AUC,1, function(m){topM2 <- M2AUC[which(rownames(M2AUC) == topSc2),]; sum(m <= topM2)/sum(m > topM2)})
bf2AUC[names(bf2AUC) == topSc2] <- NA

# rank based final metric for SC2 ()
M2aveRank <- (apply(-M2spearman,2,rank) + apply(-M2AUC,2,rank) )/2 # 
rownames(M2aveRank) <- sc2Teams
M2aveRankSorted <- M2aveRank[order(sc2ScoreSAveRank$aveRank, decreasing = T),]
boxplot(t(M2aveRankSorted), outline=F, horizontal=T, las=2,main="SC2 Bootstrapped Distributions", xlab="Averaged Rank")
bf2aveRank  <- apply(M2aveRank,1, function(m){topM2 <- M2aveRank[which(rownames(M2aveRank) == topSc2),]; sum(m >= topM2)/sum(m < topM2)})
bf2aveRank[names(bf2aveRank) == topSc2] <- NA
dev.off()

bf1out <- data.frame(Team = sc1Teams, Score = sc1Scores$Spearman,BayesFactor = bf1); rownames(bf1out) <- sc1Subs$objectId
bf1out <- bf1out[order(bf1out$Score,decreasing = T),]; 
bf2out <- data.frame(Team = sc2Teams, Score = sc2ScoreSAveRank$aveRank,AveRank_BF = bf2aveRank, Spearman = sc2ScoresSpearman$Spearman, Spearman_BF = bf2Spearman, AUC = sc2ScoresAuc$Auc, AUC_BF = bf2AUC )
rownames(bf2out) <- sc2Subs$objectId
bf2out <- bf2out[order(bf2out$Score),]; 

write.csv(bf1out,"Sc1ScoresAndBayesFactor.csv", quote = F,row.names = T)
write.csv(bf2out,"Sc2ScoresAndBayesFactor.csv", quote = F,row.names = T)


