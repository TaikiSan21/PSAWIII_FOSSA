# PSAW Process Prep Script
db <- list.files('./Databases', pattern='sqlite', recursive = FALSE, full.names = TRUE)
bin <- './Binary/'

pps <- PAMpalSettings(db, bin, filterfrom_khz=10, filterto_khz=NULL, winLen_sec=.0025, sr_hz='auto')
data <- processPgDetections(pps, mode='recording')

btrain <- readRDS('PSAW_Banter_Train.rds.rda')

library(PamBinaries)
library(dplyr)
getFolderTimes <- function(x) {
    bins <- list.files(x, pattern='pgdf$', full.names = TRUE, recursive = TRUE)
    utc <- bind_rows(lapply(bins, function(b) {
        data <- loadPamguardBinaryFile(b, skipLarge=TRUE, convertDate = FALSE)$data
        if(length(data) == 0) {
            return(NULL)
        }
        list(UTC=sapply(data, function(d) d$date))
    }))
    utc$UTC <- convertPgDate(utc$UTC)
    utc
}

binDirs <- list.dirs('./Binary/', recursive=FALSE, full.names = TRUE)
nms <- gsub('(AC[0-9]{2,3})_.*', '\\1', basename(binDirs))
folderTimes <- lapply(binDirs, getFolderTimes)
names(folderTimes) <- nms

evGroup <- bind_rows(lapply(folderTimes, function(x) {
    list(start=min(x$UTC)-1, end=max(x$UTC)+1)
}))
evGroup$id <- nms
evGroup$sr <- 192e3
evGroup$db <- db
evGroup$species <- NA
for(i in 1:nrow(evGroup)) {
    if(evGroup$id[i] == 'AC119') {
        evGroup$species[i] <- 'G_macrorhynchus'
    } else if(evGroup$id[i] == 'AC792') {
        evGroup$species[i] <- 'O_orca'
    } else {
        evGroup$species[i] <- btrain$events$species[btrain$events$event.id == evGroup$id[i]]
    }
}
write.csv(evGroup, file='TrainingEvents.csv', row.names = FALSE)

btest <- readRDS('PSAW_Banter_Test.rds.rda')
db <- list.files('./Prediction/Databases/', pattern='sqlite', recursive = FALSE, full.names = TRUE)
binDirs <- list.dirs('./Prediction/Binary/', recursive = FALSE, full.names = TRUE)
nms <- gsub('(AC[0-9]{2,3})_.*', '\\1', basename(binDirs))
folderTimes <- lapply(binDirs, getFolderTimes)
names(folderTimes) <- nms
evGroup <- bind_rows(lapply(folderTimes, function(x) {
    list(start=min(x$UTC)-1, end=max(x$UTC)+1)
}))
evGroup$id <- nms
evGroup$sr <- 192e3
evGroup$db <- db
evGroup$species <- NA
for(i in 1:nrow(evGroup)) {
    evGroup$species[i] <- btest$events$species[btest$events$event.id == evGroup$id[i]]
}
write.csv(evGroup, file='PredictionEvents.csv', row.names=FALSE)
