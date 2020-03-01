'author: Christopher Matthew Sampah'
'date: 20190628'

rm(list = ls())
gc()

library(data.table)
library(plyr)
library(nnet)
library(ggplot2)
library(MASS)
library(lattice)
library(synthpop)
library(tictoc)

dir <- '//Pii_baboon/f/csampah/temp task'

set.seed(8)
tic('Read-in datasets to be synthesized and necessary functions:')
adm <- as.data.table(fread(paste0(dir,'/data_files/ADM1812.csv')))
rsm <- as.data.table( fread(paste0(dir,'/data_files/RSM1812.csv')))
source(paste0(dir,'/generation_fxns.R'))
toc()

temp <- format.data.for.synth(adm[sample(1000)])
tic('Format the data for synthesis')
adm.pre.syn <- format.data.for.synth(adm)
rsm.pre.syn <- format.data.for.synth(rsm)
toc()

#generate the synthetic data
load('//path/var_mtx.Rdata') # var.mtx specifies to the algorithm what other vars to use to make synthetic values for a var
syn.cols <- c('DIEUS_DT','PG_CD_num','PRI_DOD_OCC_CD','DTY_DOD_OCC_CD', 'SVC_CD')

tic(paste('Generate synthetic dataset for original dataset of',nrow(temp),'rows') )
temp.s <- syn(temp[,..syn.cols],predictor.matrix = var.mtx)
toc()

tic(paste('Generate synthetic dataset for original dataset of',nrow(adm.pre.syn),'rows') )
adm.s <- syn(adm.pre.syn[,..syn.cols],predictor.matrix = var.mtx)
toc()

tic(paste('Generate synthetic dataset for original dataset of',nrow(rsm.pre.syn),'rows') )
rsm.s <- syn(rsm.pre.syn[,..syn.cols],predictor.matrix = var.mtx)
toc()


#format and save synthetic data
temp.syn <- format.data.for.save(as.data.table(temp.s$syn), adm)
adm.syn <- format.data.for.save(as.data.table(adm.s$syn), adm)
rsm.syn <- format.data.for.save(as.data.table(rsm.s$syn), rsm)

#PRI/DTY_DOD_OCC_CD's generated synthetically MUST be among real possible values, not random large ints
#for(datum in c(adm.syn, rsm.syn))
all.codes <- unique(c(adm$PRI_DOD_OCC_CD, adm$DTY_DOD_OCC_CD,rsm$PRI_DOD_OCC_CD, rsm$DTY_DOD_OCC_CD))
stopifnot(temp.syn[!(PRI_DOD_OCC_CD %in% all.codes) | !(DTY_DOD_OCC_CD %in% all.codes),.N]==0)
stopifnot(adm.syn[!(PRI_DOD_OCC_CD %in% all.codes) | !(DTY_DOD_OCC_CD %in% all.codes),.N]==0)
stopifnot(rsm.syn[!(PRI_DOD_OCC_CD %in% all.codes) | !(DTY_DOD_OCC_CD %in% all.codes),.N]==0)


#save R objects for faster load in
save(adm.syn, file = paste0(dir,'/synthetic_data/r_data_objects/adm_synthetic.RData'))
save(rsm.syn, file = paste0(dir,'/synthetic_data/r_data_objects/rsm_synthetic.RData'))
save(adm.s, file = paste0(dir,'/synthetic_data/r_data_objects/adm_synthetic_object.RData'))
save(rsm.s, file = paste0(dir,'/synthetic_data/r_data_objects/rsm_synthetic_object.RData'))


