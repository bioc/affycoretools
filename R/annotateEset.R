##' @param columns For ChipDb method; what annotation data to add. Use the \code{\link[AnnotationDbi]{columns}}
##' function to see what choices you have. By default we get the ENTREZID, SYMBOL and GENENAME.
##' @param multivals For ChipDb method; this is passed to \code{\link[AnnotationDbi]{mapIds}} to control how 1:many
##' mappings are handled. The default is 'first', which takes just the first result. Other valid
##' values are 'list' and 'CharacterList', which return all mapped results.
##' @return An ExpressionSet that has annotation data added to the featureData slot.
##' @author James W. MacDonald <jmacdon@u.washington>
##' @describeIn annotateEset Annotate an ExpressionSet using a ChipDb package for annotation data.
##' @export
setMethod("annotateEset", c("ExpressionSet","ChipDb"),
          function(object, x, columns = c("PROBEID","ENTREZID","SYMBOL","GENENAME"), multivals = "first"){
    ## Doing mapIds(chipDb, featureNames(object), "PROBEID","PROBEID") fails for many packages, and wastes compute cycles
    ## so we just add that by hand.
    addcol <- FALSE
    if(any(columns == "PROBEID")) {
        addcol <- TRUE
        columns <- columns[-grep("PROBEID", columns)]
        collst <- list(PROBEID = featureNames(object))
    }
    multivals <- switch(multivals,
                        first = "first",
                        list = "CharacterList",
                        CharacterList = "CharacterList",
                        stop("The multivals argument should be 'first', 'list' or 'CharacterList'", call. = FALSE))
    annolst <- lapply(columns, function(y) mapIds(x, featureNames(object), y, "PROBEID", multiVals = multivals))
    if(addcol) annolst <- c(collst, annolst)
    anno <- switch(multivals,
                   first = as.data.frame(annolst),
                   DataFrame(annolst))
    names(anno) <- if(addcol) c("PROBEID", columns) else columns
    if(!isTRUE(all.equal(row.names(anno), featureNames(object))))
        stop(paste("There appears to be a mismatch between the ExpressionSet and",
                   "the annotation data.\nPlease ensure that the summarization level",
                   "for the ExpressionSet and the annotation package are the same.\n"),
             call. = FALSE)
    andf <- dfToAnnoDF(anno)
    featureData(object) <- andf
    stopifnot(validObject(object))
    object
})


##' @param type For pdInfoPackages; either 'core' or 'probeset', corresponding to the 'target' argument
##' used in the call to \code{\link[oligo]{rma}}.
##' @describeIn annotateEset Annotate an ExpressionSet using an AffyGenePDInfo package.
##' @export
setMethod("annotateEset", c("ExpressionSet","AffyGenePDInfo"),
          function(object, x, type = "core", ...){
    .dataFromNetaffx(object, x, type, ...)
})


##' @describeIn annotateEset Annotate an ExpressionSet using an AffyHTAPDInfo package.
##' @export
setMethod("annotateEset", c("ExpressionSet","AffyHTAPDInfo"),
          function(object, x, type = "core", ...){
    .dataFromNetaffx(object, x, type, ...)
})


##' @describeIn annotateEset Annotate an ExpressionSet using an AffyExonPDInfo package.
##' @export
setMethod("annotateEset", c("ExpressionSet","AffyExonPDInfo"),
          function(object, x, type = "core", ...){
    .dataFromNetaffx(object, x, type,...)
})

##' @describeIn annotateEset Annotate an ExpressionSet using an AffyExpressionPDInfo package.
##' @export
setMethod("annotateEset", c("ExpressionSet","AffyExpressionPDInfo"),
          function(object, x, type = "core", ...){
    if(type != "core") warning("Setting type to 'core', as that is the only summarization available.", call. = FALSE)
    if(!file.exists(system.file(paste0("/extdata/netaffxTranscript.rda"), package = annotation(x))))
        stop(paste("There is no annotation object provided with the", annotation(x), "package."), call. = FALSE)
    .dataFromNetaffx(object, x, type = "core",...)
})



.dataFromNetaffx <- function(object, x, type = "core", ...){
    typeToGet <- switch(type,
                        core = "netaffxTranscript.rda",
                        probeset = "netaffxProbeset.rda",
                        stop("Type must be either 'core' or 'probeset'", call. = FALSE))
    load(system.file(paste0("/extdata/", typeToGet), package = annotation(x)))
    annot <- pData(get(sub("\\.rda", "", typeToGet)))
    annotest <- switch(type,
                       probeset = sum(annot$probesetid %in% featureNames(object))/nrow(annot),
                       core = sum(annot$transcriptclusterid %in% featureNames(object))/nrow(annot))
    if(annotest < 0.95){
        invanno <- switch(type,
                       probeset = sum(featureNames(object) %in% annot$probesetid)/nrow(object),
                       core = sum(featureNames(object) %in% annot$transcriptclusterid)/nrow(object))
        warning(paste("There appears to be a mismatch between the ExpressionSet and",
                   "the annotation data.\nPlease ensure that the summarization level",
                   "for the ExpressionSet and the 'type' argument are the same.\n",
                   "See ?annotateEset for more information on the type argument.\n\n",
                   "There are", switch(type, probeset = length(annot$probesetid),
                                       core = length(annot$transcriptclusterid)),
                   "probesets in the annotation data and", nrow(object), "probesets in",
                   "the ExpressionSet;\nthe overlap between the annotation and ExpressionSet",
                   "is", paste0(floor(annotest * 100), "%"), "\nand the overlap between the ExpressionSet",
                   "and annotation is", paste0(floor(invanno * 100), "%."), "\nProceed with caution.\n"),
                call. = FALSE)
    }
    anno <- switch(type,
                   core = as.data.frame(do.call(rbind, lapply(strsplit(annot$geneassignment, " // "), "[", 1:3))),
                   probeset = as.data.frame(do.call(rbind, lapply(strsplit(annot$geneassignment, " /// "), function(x) unlist(strsplit(x[1], " // "))))))
    names(anno) <- c("ID", "SYMBOL","GENENAME","CHRLOC","ENTREZID")[seq_len(ncol(anno))]
    row.names(anno) <- switch(type,
                              probeset = as.character(annot$probesetid),
                              core = as.character(annot$transcriptclusterid))
    anno$PROBEID <- row.names(anno)
    anno <- anno[,c(ncol(anno),1:(ncol(anno)-1))]
    if(!all(featureNames(object) %in% row.names(anno)))  anno <- .makeFullDf(anno, featureNames(object))
    anno <- anno[featureNames(object),]
    andf <- dfToAnnoDF(anno)
    featureData(object) <- andf
    stopifnot(validObject(object))
    object
}

.makeFullDf <- function(d.f, rn){
    for(i in seq_len(ncol(d.f))) d.f[,i] <- as.character(d.f[,i])
    tmp <- data.frame(matrix(nrow = length(rn), ncol = ncol(d.f), dimnames = list(rn, names(d.f))))
    tmp[row.names(d.f),] <- d.f
    tmp
}

##' @describeIn annotateEset Method to capture character input.
##' @export
setMethod("annotateEset", c("ExpressionSet","character"),
          function(object, x, ...){
    do.call(require, list(x, character.only = TRUE, quietly = TRUE))
    x <- get(x)
    annotateEset(object, x, ...)
})

##' @describeIn annotateEset Annotate an ExpressionSet using a user-supplied data.frame.
##' @export
##' @param probecol Column of the data.frame that contains the probeset IDs. Can be either
##' numeric (the column number) or character (the column header).
##' @param annocols Column(x) of the data.frame to use for annotating. Can be a vector of numbers
##' (which column numbers to use) or a character vector (vector of column names).

setMethod("annotateEset", c("ExpressionSet","data.frame"),
          function(object, x, probecol = NULL, annocols = NULL, ...){
    if(is.null(probecol) || is.null(annocols))
        stop(paste("You must specify the column containing the probeset IDs (probecol argument)",
                   "and the column(s) containing the annotation data you wish to use (annocols argument).\n"),
             call. = FALSE)
    rn <- as.character(x[,probecol])
    anno <- x[,annocols]
    row.names(anno) <- rn
    anno <- anno[featureNames(object),]
    if(!isTRUE(all.equal(row.names(anno), featureNames(object))))
        stop(paste("There appears to be a mismatch between the ExpressionSet and the",
                   "data.frame that contains the annotation data. Please make sure that",
                   "the column containing the probeset IDs matches the featureNames from",
                   "your ExpressionSet. You may need to subset one or the other to make",
                   "them conform to each other.\n"), call. = FALSE)
    andf <- dfToAnnoDF(anno)
    featureData(object) <- andf
    stopifnot(validObject(object))
    object
})


setMethod("dfToAnnoDF", "data.frame",
          function(x) {
    adf <- AnnotatedDataFrame(data = x)
    return(adf)
})

setMethod("dfToAnnoDF", "DataFrame",
          function(x) {
    adf <- AnnotatedDataFrame(data = as(x, "data.frame"))
    return(adf)
})

## If we use 'list' or 'CharacterList' to annotate, we may get multiple values returned for a given ID
## in which case, we need to collapse to a single vector (separated by <BR>) so it will all fit into a single
## cell in the resulting table.
listToVector <- function(object, ...){
    if(any(apply(object, 2, class) == "list")){
        ind <- apply(object, 2, class) == "list"
        for(i in seq(along = ind)) object[,i] <- sapply(object[,i], function(x) paste(x, collapse = "<BR>"))
    }
    return(object)
}


                   
