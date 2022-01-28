# PSAW Workshop Workflow
library(PAMpal)
db <- list.files('./Databases', pattern='sqlite', recursive = FALSE, full.names = TRUE)
bin <- './Binary/'

pps <- PAMpalSettings(db, bin,
                      filterfrom_khz=10, filterto_khz=NULL, winLen_sec=.0025, sr_hz='auto',
                      settings = 'XMLSettings.xml')
# pps <- addSettings(pps, 'XMLSettings.xml')
groups <- read.csv('TrainingEvents.csv', stringsAsFactors = FALSE)
data <- processPgDetections(pps, mode='time', grouping=groups, id='PSAWIII_Training')

saveRDS(data, file='TrainPSAW.rds')

db <- list.files('./Prediction/Databases/', pattern='sqlite', recursive=FALSE, full.names=TRUE)
bin <- './Prediction/Binary/'
pps <- PAMpalSettings(db, bin,
                      filterfrom_khz=10, filterto_khz=NULL, winLen_sec=.0025, sr_hz='auto',
                      settings='XMLSettings.xml')
groups <- read.csv('PredictionEvents.csv', stringsAsFactors = FALSE)
data <- processPgDetections(pps, mode='time', grouping=groups, id='PSAWIII_Prediction')
saveRDS(data, file='PredictionPSAW.rds')
