'author: christopher matthew sampah'
'code birthdate:20190629 '

format.data.for.synth <- function(dataset, num_records = nrow(dataset), nms = NA) {
  
  dt <- as.data.table(copy(dataset))
  #read-in map that assigns rank (char) to ordinal integers
  library(data.table)
  pg.map <- as.data.table(fread('//Pii_baboon/f/csampah/temp task/pg_cd_ranking.csv'))
  pg_to_ord <- pg.map[,c('value', 'ordinal_ranking')]
  ord_to_pg <- pg.map[,c('ordinal_ranking', 'value')]
  ord_to_pg <- ord_to_pg[!(value %in% c('MO00','ME00'))]
  
   #map ranks to ordinal integers
  for(i in 1:nrow(pg_to_ord)) {dt[PG_CD ==pg_to_ord[[i,1]], PG_CD_num := pg_to_ord[[i,2]]]}
  
  #obtain the columns I care about to generate the synthetic data for
  if(is.na(nms)) {
    nms <- c('DIEUS_DT','PG_CD_num','PRI_DOD_OCC_CD','DTY_DOD_OCC_CD', 'SVC_CD', 'PG_CD')
    dt[, DIEUS_DT := as.Date(DIEUS_DT)]
    setnames(dt,'PG_CD', 'PG_CD.orig')
    nms <- c('DIEUS_DT','PG_CD_num','PRI_DOD_OCC_CD','DTY_DOD_OCC_CD', 'SVC_CD', 'PG_CD.orig')
    }

  dt <- dt[,..nms]
  dt <- dt[complete.cases(dt)] #can only generate synthetic data for rows with no NA's, thus subset the data accordingly
  }

#map ordinal back to job code
ord.to.pg.cd <- function(dt) {
  pg.map <- as.data.table(fread(paste0('//Pii_baboon/f/csampah/AVADNA task/pg_cd_ranking.csv')))
  ord_to_pg <- pg.map[,c('ordinal_ranking', 'value')]
  ord_to_pg <- ord_to_pg[!(value %in% c('MO00','ME00'))]
  for(i in 1:nrow(ord_to_pg)) {dt[PG_CD_num == ord_to_pg[[i,1]], PG_CD := ord_to_pg[[i,2]]]}
  dt}

#format the synthetic data before saving it
format.data.for.save <- function(syn.data,orig.data, col.names = NA) {
  syn.data <- ord.to.pg.cd(syn.data)
  syn.data$SSNSCR <- sample(orig.data$SSNSCR, nrow(syn.data))
  if(is.na(col.names)){ col.names <- c('SSNSCR','DIEUS_DT','PG_CD','PRI_DOD_OCC_CD','DTY_DOD_OCC_CD', 'SVC_CD') }
  syn.data[,..col.names]
  }

