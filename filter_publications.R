'@author: Christopher Sampah'

rm(list = ls())
gc()

library(data.table)
library(plyr)
library(stringr)

dir <- '//some_path/'

dt.jg <- fread(paste0(dir,'received from jason greer/publications with project leader.csv'))
dt.cc <- fread(paste0(dir,'received from chris connell/all_publications.csv'))
dt.mj <- fread(paste0(dir,'received from matt and julie/merged lists from matt and julie.csv'))

#standardize publication numbers; this will serve as the primary key
fix_pub_num <- function(data = dt,current_name) {
  d <- copy(data)
  d[, pub_num := get(current_name)]
  edit_these <- c(' ',
  'IDADocument',
  'IDAReport',
  'IDAPaper',
  'Revised',
  'REVISED',
  '-VOL-3',
  '-VOL-2',
  '-VOL-1',
  'Volume1',
  'Volume2',
  'APPENDIXC',
  'AppendixC',
  '-APP-1',
  '-APP',
  "\\(",
  "\\)",
  ' ')
  for(edit in edit_these) { d[, pub_num :=gsub(edit,'', pub_num)]}
  d}

dt.cc <- fix_pub_num(dt.cc, 'report_number' )
dt.mj <- fix_pub_num(dt.mj, 'ida_publication_number')
dt.jg <- fix_pub_num(dt.jg, 'revised_ida_pub_num')

#for the final combined table, I wanna know which source the original record came from
dt.cc[, origin := 'cc']
dt.mj[,origin := 'mj']
dt.jg[, origin := 'jg']

#pubs_status
setnames(dt.jg, 'material_type', 'orig.status')
setnames(dt.cc, 'document_status', 'orig.status')
setnames(dt.mj, 'status', 'orig.status')

#create master list; start with matt & julie's list, then stack relevant papers from chris c.
#change names of chris c.'s list to match the master list
dt <- merge(dt.mj, setnames(dt.cc,c('author','report_date'), c('authors', 'date')), by = 'pub_num', all = TRUE)

#merge fields that are duplicated after the merge
melt_cols <- function(c = c('date', 'authors', 'title','origin'), data = dt) {
  dt.temp <- copy(dt)
  for( col.name in c) {
    dt.temp[, eval(col.name) := get(paste0(col.name,'.x'))]
    dt.temp[is.na(get(col.name)), eval(col.name) := get(paste0(col.name,'.y'))]
    dt.temp[, eval(paste0(col.name,'.x')) := NULL]
    dt.temp[, eval(paste0(col.name,'.y')) := NULL]}
  dt.temp}

dt <- melt_cols(c('date', 'authors', 'title','origin', 'orig.status'))


#fill missing "abstract" field in master dataset using jason's dataset
dt[is.na(abstract), .N]
dt <-merge(dt, dt.jg[,c('pub_num', 'abstract')],by = 'pub_num', all.x = TRUE)
dt[, abstract := abstract.x]
dt[is.na(abstract), abstract := abstract.y]
dt[is.na(abstract), .N]

dt <- melt_cols(c('abstract'))


#merge jason's list into the master list, excluding rows with a pubs from either julie's or chris's list
dt <- merge(dt, dt.jg[!(pub_num %in% unique(dt$pub_num))], by = 'pub_num', all = TRUE)
sort(names(dt))
dt <- melt_cols(c('abstract', 'authors', 'date','lead_division', 'title','origin', 
                  'distribution_statement', 'ida_publication_number', 'orig.status'))

set.seed(8)
dt$sampah_id <- sample(seq(1000,9999), nrow(dt))

#fix and standardize fields
dt[, orig.abstract := abstract]
dt[, abstract := orig.abstract]
dt[nchar(orig.abstract) < 25 | is.na(orig.abstract), abstract:= 'NA']

dt[, orig.date := date]
dt[, date := as.Date(orig.date, '%m/%d/%Y')]
dt <- dt[order(date, decreasing = TRUE)]

dt[, poc := 'placeholder']
dt[str_count(authors,',') < 2, poc := authors]

#master file of all current employees at company HQ 
ce <- fread(paste0(dir,'received from hr/current_ida_hq_employees.csv'))
ce <- ce[,!c('status_code')]
setnames(ce, names(ce), c('name', 'div'))
ce <- ce[!(div %in% c('PURCHASING', 'ADMIN'))] # exclude non-researchers

ce$last <- as.character(lapply(strsplit(as.character(ce$name), split=","), "[", 1))
ce$temp.first <- as.character(lapply(strsplit(as.character(ce$name), split=","), "[", 2))
ce$first <- as.character(lapply(strsplit(as.character(ce$temp.first), split=" "), "[", 2))
ce$middle <- as.character(lapply(strsplit(as.character(ce$temp.first), split=" "), "[", 3))
ce$temp.first <- NULL

ce[, last := tolower(last)]
ce[, first := tolower(first)]
ce[, middle := tolower(middle)]
#remove any unnecessary spaces
ce$first <- ce[, gsub(' ','', first)]
ce$middle <- ce[, gsub(' ','', middle)]
ce <- ce[!is.na(last)]

#add current employee based on name match b/w master list of current employees and the authors field
#match on both first and last names
dt[, orig.authors := authors]
dt[, authors := tolower(orig.authors)]
for(i in 1:nrow(ce)) {dt[grepl(ce[i,last], authors) & grepl(ce[i, first],authors), poc := ce[i, name]]}

#if any non-matches remain, manual matches
dt[grepl('jamison', authors) & grepl('j.j.', authors), poc := 'Jamison, John Jona']

#convert title to all lowercase so I can match based on key words (doesn't work with lower/uppercase mix)
dt[,orig.title := title]
dt[,title := tolower(orig.title)]

#catalogue the obvious ones
dt[,category := 'placeholder']

retirement_words <- c('retirement system')
dt[title %in% grep(paste(retirement_words,collapse="|"), dt$title, value=TRUE), category := 'retirement']

health_words <- c('tricare', 'disability', 'illness', 'disease', 'addiction', 'alcohol', 'health care')
dt[title %in% grep(paste(health_words,collapse="|"), dt$title, value=TRUE), category := 'health']

recruitment_words <- c('recruitment', 'compensation', 'pay', 'hazard', 'workforce', 'employer', 'salary','tax')
dt[title %in% grep(paste(recruitment_words,collapse="|"), dt$title, value=TRUE), category := 'recruitment, retention, compensation']

readiness <- c('readiness', 'bully')
dt[title %in% grep(paste(readiness,collapse="|"), dt$title, value=TRUE), category := 'readiness']

training <- c('training', 'education', 'language', 'human capital', 'talent')
dt[title %in% grep(paste(training,collapse="|"), dt$title, value=TRUE), category := 'training']

force_strxr <- c('civilian', 'enlisted', 'force mixes', 'reserve', 'irregular warfare')
dt[title %in% grep(paste(force_strxr,collapse="|"), dt$title, value=TRUE), category := 'force structure']

veterans <- c('veteran')
dt[title %in% grep(paste(veterans,collapse="|"), dt$title, value=TRUE), category := 'veterans']

work_climate <- c('sex', 'suicide', 'personnel')
dt[title %in% grep(paste(work_climate,collapse="|"), dt$title, value=TRUE), category := 'leadership and workplace climate']


'count of tagged'
dt[category != 'placeholder',.N]

#exclude the obvious ones
'count of records before applied exlcusions'
dt[,.N]
exclusion_words <- c('infrastructure', 'airlift', 'nuclear', 'china', 'middle east', 'conference presentation', 'presentation',
                     'poster', 'nanotechnology','biow', 'biol', 'africa','biosurveill', 'technical reference','software',
                     'manufacturing sources and material shortages', 'foreign defense institutions', 'radiological',
                     tolower('Supply, Demand, and Base Case Shortfalls'), 'cost assessment activities', 'chemical warfare',
                     'threat emulation',tolower('Review on the Extension of the AMedP-8(C)'), 'biowatch', 'book review',
                     tolower('Requirements Report Downstream Supply Chain Weak Links'),'nerve agent', 'nato planning guide',
                     'border security', 'rare earth', 'bomb', 'armor', 'fixed-wing', 'publications','korea', 'iran',
                     'common risk model for dams', 'pow/mia', 'navy contractors', 'raytheon','sanctions', 'border', 'criminal',
                     'inflation indexes','internet-derived', 'database', 'afghan', 'terror', 'aircraft', 'energy storage', 
                     'extremist', 'satellite', 'stockpile', 'vapor', 'appendix','stability operations')

matches <- grep(paste(exclusion_words,collapse="|"), 
                dt$title, value=TRUE)

'count after exclusion'
dt[!(title %in% matches),.N]

'count what needs to be tagged'
dt[category == 'placeholder' & !(title %in% matches), .N ]

#read in d_burroughs' manual categorization, match to the overall dataset, write out the results
dawnn_cat <- fread(paste0(dir,'some_path/d_burroughs_manual_categorization.csv'))
dt.2 <- merge(dt, dawnn_cat[,c('sampah_id', 'category')], by = 'sampah_id', all.x = TRUE)
dt.2[!is.na(category.y), category.x := category.y]
dt.2[, category := category.x]
dt.2[, category.x := NULL]
dt.2[, category.y := NULL]
dt <- dt.2

dawnn_cat2 <- fread(paste0(dir,'/received from d_burroughs/manual_abstract_filling_in.csv'))
dt <- merge(dt, dawnn_cat2[, c('title', 'filled in abstract')], by = 'title', all.x = TRUE)
dt[is.na(abstract), abstract := `filled in abstract`]
dt <- dt.2

#formalize the final/draft final flag
dt[, status := tolower(orig.status)]
dt[grepl('draft', status), status := 'draft final']
dt[grepl('final', status) & !(grepl('draft', status)), status := 'final']
dt[!(grepl('final', status)) & !(grepl('draft', status)), status := 'final']

#manual fix
dt[grepl('staffing for cyberspace operations', title), category := 'recruitment, retention, compensation']
dt[grepl("army national guard's role in meeting the", title), category := 'force structure']
dt[grepl('force', title), category := 'force structure']
dt[grepl('interagency national security knowledge and skills in the department of defense', title), category := 'force structure']
dt[grepl('analysis and forecasts of army enlistment supply', title), category := 'force structure']

#save outputs
fwrite(dt, paste0(dir,'machine output/1-all publications received from julie, matt, jason, and chris.csv'))
fwrite(dt[!(title %in% matches) | origin == 'mj',c('category', 'title','orig.title','date', 'pub_num',
                                                   'abstract', 'authors','poc','origin', 'sampah_id', 'orig.status','status')], 
       paste0(dir,'machine output/2-publications with first exclusions applied.csv'))

dt.temp <- dt[category != 'placeholder' | origin == 'mj',
              c('category', 'title','orig.title','date', 'pub_num', 'abstract','orig.abstract',
                'orig.authors','poc','origin','sampah_id','orig.status','status')]

dt.temp <- dt.temp[!( title %in% grep(paste(c('appendix', 'stability operations'),collapse="|"),dt$title, value=TRUE))]

saveRDS(list(exclusion_words), paste0(dir,'machine output/key words excluded on.rds'))
fwrite(dt.temp, paste0(dir,'machine output/3-personnel publications by category/all personnel-related publications.csv'))
for (cat in unique(dt.temp$category)) { fwrite(dt.temp[category == cat,c('orig.title','date', 'pub_num', 
                                                                         'orig.abstract','abstract', 'orig.authors',
                                                                         'poc','sampah_id', 'orig.status','status')],
                                               paste0(dir,'machine output/3-personnel publications by category/',cat,'.csv'))}
save(dt, file = paste0(dir, 'machine output/all_publications.RData'))

dt.personnel <- dt.temp

save(dt.personnel, file = paste0(dir, 'machine output/personnel_publications.RData'))

#random insertion