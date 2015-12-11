

computer <- 'CS'

if (computer == 'CS') {
  README <- '/cluster/project8/vyp/vincent/Software/pipeline/filter_rare_variants/README'
  biomart.gene.description <- '/cluster/project8/vyp/vincent/data/biomart/support/biomart_geneNames_hsapiens_gene_ensembl.tab'
}

test.case.control <- function(data, my.cases, type = 'lof', extra.gene.annotations.file = NULL, known.genes = c()) {

  message('Running the case control tests')
  if (! type %in% c('lof', 'functional')) stop('Type must be either lof or functional')
  
  data$ncalls.cases <- 0
  data$nonRefcalls.cases <- 0
  data$nonRefHomCalls.cases <- 0

  ##### a bit of work on the gene names
  data <- subset(data, !is.na(ensemblID))
  data$clean.HUGO <- gsub(pattern = '\\(.*', replacement = '', data$HUGO)
  conversion.table <- tapply(data$clean.HUGO, IND = data$ensemblID, FUN = function(x) {x[1]})
  conversion.table <- data.frame(ensemblID = names(conversion.table), HUGO = as.character(conversion.table))

  #### Now we work with a smaller data frame
  if (type == 'lof') candidates <- subset(data, rare & lof & FILTER == 'PASS' & !remove.bad.transcripts)
  if (type == 'functional') candidates <- subset(data, rare & (non.syn | lof | splicing)  & FILTER == 'PASS' & !remove.bad.transcripts)

    
  for (id in my.cases) {
    message('Case id ', id)
    #depth <- as.numeric(gsub(pattern = '.*:', replacement = '', candidates[, id]))
    
    hets <- as.numeric( grepl(pattern = '^0\\|1|^1\\|0', candidates[, id]))
    homs <- as.numeric( grepl(pattern = '^1\\|1', candidates[, id]))
    ref <- as.numeric( grepl(pattern = '^0\\|0', candidates[, id]))
    
    candidates$ncalls.cases <- candidates$ncalls.cases + as.numeric(hets | homs | ref )
    candidates$nonRefcalls.cases <- candidates$nonRefcalls.cases + 2*homs + hets
    candidates$nonRefHomCalls.cases <- candidates$nonRefHomCalls.cases + homs
  }

  candidates$ensemblID <- factor(candidates$ensemblID, levels = unique(data$ensemblID))
  message('Preparing the counts for gene based association testing')
  controls.nonref <- tapply(X = candidates$non.ref.calls.controls, INDEX = candidates$ensemblID, FUN = sum)
  cases.nonref <- tapply(X = candidates$nonRefcalls.cases, INDEX = candidates$ensemblID, FUN = sum)
  cases.nmut <- tapply(X = candidates$nonRefcalls.cases, INDEX = candidates$ensemblID, FUN = function(x) {sum (x != 0)})
  cases.hom.calls <- tapply(X = candidates$nonRefHomCalls.cases, INDEX = candidates$ensemblID, FUN = sum)
  total.controls <- tapply(X = candidates$total.calls.controls, INDEX = candidates$ensemblID, FUN = mean)
  total.cases <- tapply(X = candidates$ncalls.cases, INDEX = candidates$ensemblID, FUN = mean)

  my.res <- data.frame(ensemblID = names(controls.nonref),
                       p.value = NA,
                       ncalls.cases = as.numeric(cases.nonref),
                       n.hom.calls.cases = as.numeric(cases.hom.calls),
                       ncalls.controls = as.numeric(controls.nonref),
                       nsamples.cases = as.numeric(total.cases),
                       nsamples.controls = as.numeric(total.controls),
                       nmut.cases = as.numeric(cases.nmut),
                       stringsAsFactors = FALSE)

  my.res$nsamples.cases <- replace( x = my.res$nsamples.cases, list = which (is.na(my.res$nsamples.cases)), values = 0)
  my.res$nsamples.controls <- replace( x = my.res$nsamples.controls, list = which (is.na(my.res$nsamples.controls)), values = 0)
  
  ### Add proper gene names
  my.res$HUGO <- conversion.table$HUGO [ match(my.res$ensemblID, table = conversion.table$ensemblID) ]  ## add proper gene names
  if (length(known.genes) > 0) {my.res$known.gene <- my.res$HUGO %in% known.genes}

  
  if (!is.null(extra.gene.annotations.file)) {
    message('Now adding annotations to the gene table ', extra.gene.annotations.file)
    annotations <- read.csv(extra.gene.annotations.file)
    my.res <- merge(my.res, annotations, by = 'ensemblID', all.x = TRUE)
  }
  
  message('Done with preparing the counts, example below')
  print(subset(my.res, HUGO == 'ARL3'))
  

  message('Now parsing all the genes to compute P-values')
  ngenes <- nrow(my.res)
  for (i in 1:ngenes) {
    tot.mut <- my.res$nsamples.cases[ i ] + my.res$nsamples.controls[ i ]
    if (tot.mut > 0) {
      prob.cases <- my.res$nsamples.cases[i]/tot.mut
      my.res$p.value[ i ] <- pbinom(p = prob.cases, size = my.res$ncalls.cases[ i ] + my.res$ncalls.controls[ i ], q = my.res$ncalls.cases[ i ] - 1, lower.tail = FALSE)
    } else {
      my.res$p.value[ i ] <- 1
    }
  }
  
  my.res$p.value <- signif(my.res$p.value, 3)
  my.res <- my.res[order(my.res$p.value),
                   c('HUGO', subset(names(my.res), !(names(my.res) %in% 'HUGO')))]

  
  
  return (list(data = data, results = my.res))
}





annotate.standard.annovar.output <- function(data,   ##this function does NOT include the control data to define the rare/somewhat.rare flags
                                             threshold.rare = 0.002,
                                             threshold.somewhat.rare = 0.005,
                                             bad.genes = c(),
                                             freq.fields = c( 'X1000g2012apr_ALL', 'ESP6500si_ALL'),
                                             choice.transcripts = NULL,
                                             biomart.gene.description = '/cluster/project8/vyp/vincent/data/biomart/support/biomart_geneNames_hsapiens_gene_ensembl.tab') {

  data$Chr <- gsub(pattern = '^chr', replacement = '', data$Chr)
  data$signature <- paste(data$Chr, data$Start, data$Ref, data$Obs, sep = '_')
  data$is.indel <- nchar(as.character(data$Ref)) > 1 | nchar(as.character(data$Obs)) > 1 | data$Ref == '-' | data$Obs == '-'
  data$indel.length <- ifelse (data$is.indel, pmax(1, nchar(as.character(data$Ref)), nchar(as.character(data$Obs))), 0)
  
  if (sum(grepl(pattern = '^ENS', data$Gene)) > 0) {
    message('Replacing the Ensembl gene names with usual HUGO names')
    geneMapping <- read.csv(file = biomart.gene.description, stringsAsFactors = FALSE, na.string = c('', 'NA'))
    splicing.info <- ifelse( grepl(data$Gene, pattern = '\\(.*\\)$'), gsub(pattern = '.*\\(', replacement = '\\(', x = data$Gene), '') 
    data$Description <- geneMapping$Description[ match(gsub(pattern = '\\(.*', replacement = '', x = data$Gene), table = geneMapping$ensemblID) ]

    gene.only <- gsub(pattern = '\\(.*', replacement = '', x = data$Gene)
    gene.only <- gsub(pattern = ';.*', replacement = '', gene.only)
    data$ensemblID <- gsub(pattern = ',.*', replacement = '', gene.only)
    data$ensemblID.bis <- ifelse (data$ensemblID != gene.only, gsub(pattern = '.*,', replacement = '', gene.only), NA)
    HUGO1 <- geneMapping$HUGO[ match(data$ensemblID, table = geneMapping$ensemblID) ]
    HUGO2 <- geneMapping$HUGO[ match(data$ensemblID.bis, table = geneMapping$ensemblID) ]
    HUGO <- ifelse (!is.na(HUGO2), paste(HUGO1, HUGO2, sep = ','), HUGO1)
    data$HUGO.no.splice.info <- HUGO
    data$HUGO <- paste(HUGO, splicing.info, sep = '')
    
    message('Done replacing gene names and adding description')
  }

  ###########
  message('Defining the main rare/somewhat rare and functional flags')
  data$dup.region <- !is.na(data$SegDup) & data$SegDup >= 0.96 & ! data$Gene %in% c('GBA')
  data$somewhat.rare <- !data$dup.region & ! data$Gene %in% bad.genes & (data$cg69 < 0.1 | is.na(data$cg69)) 
  data$rare <- data$somewhat.rare 
  data$novel <- data$rare & is.na(data$cg69) 

    
  for (field in freq.fields) {
    message('Field ', field)
    data$somewhat.rare <- data$somewhat.rare & (data[, field] <= threshold.somewhat.rare | is.na(data[, field]) )
    data$rare <- data$rare & (data[, field] <= threshold.rare | is.na(data[, field]) )
    data$novel <- data$novel &  (data[, field] == 0 | is.na(data[, field]) )
  }

  ######## now the functional flags
  message('Adding functional flags')
  lof <- c('frameshift deletion', 'frameshift insertion', 'frameshift substitution', 'stopgain SNV', 'stoploss SNV')
  non.syn <-   c('nonsynonymous SNV', 'nonframeshift substitution', 'nonframeshift deletion', 'nonframeshift insertion')
  data$lof <- data$ExonicFunc %in% lof
  data$non.syn <- data$ExonicFunc %in% non.syn
  data$exonic.splicing <- grepl(pattern = 'splicing', data$Func) & grepl(pattern = 'exonic', data$Func)
  data$splicing <- grepl(pattern = 'splicing', data$Func) &  (! grepl(pattern = 'exonic', data$Func))

  ##################
  message('Now working on excluding the bad transcripts')
  data$remove.bad.transcripts <- FALSE
  if (!is.null(choice.transcripts)) {

    my.genes <- unique(as.character(choice.transcripts$EnsemblID))
    for (gene in my.genes) {

      transcripts <- as.character(subset(choice.transcripts, EnsemblID == gene, 'Transcript', drop = TRUE))
      bad <- (data$ensemblID == gene)  ## we can only be bad with the bad gene
      for (transcript in transcripts) {bad <- bad & ! grepl(pattern = transcript, data$AAChange) & ! grepl(pattern = transcript, data$Gene)}
      data$remove.bad.transcripts <- data$remove.bad.transcripts | bad
    }
  }
  print(table(data$remove.bad.transcripts))
  ####################
  message("Done with annotations")
  return(data)
}


process.multiVCF <- function(data,
                             my.cases,
                             my.controls = c(),
                             bad.genes.files = c(),
                             known.genes = c(),
                             threshold.somewhat.rare = 0.005,
                             threshold.rare =  0.001,
                             hom.mapping = TRUE,
                             freq.fields = c('ESP6500si_ALL'),
                             biomart.gene.description = '/cluster/project8/vyp/vincent/data/biomart/support/biomart_geneNames_hsapiens_gene_ensembl.tab',
                             oFolder = 'processed',
                             run.case.control.both = FALSE,
                             run.case.control.variant = run.case.control.both,
                             run.case.control.gene = run.case.control.both,
                             explained.cases = NULL,
                             depth.threshold.conf.homs = 6,
                             print.individual.files = TRUE,
                             nb.IDs.to.show = 5,
                             choice.transcripts = NULL, ##data frame, need columns "EnsemblID" and "Transcript"
                             extra.gene.annotations.file = NULL,
                             PCA.pop.structure = '/cluster/project8/vyp/exome_sequencing_multisamples/mainset/mainset_January2014/mainset_January2014_PCA.RData') {

  require(VPlib)
#### some checks
  if (sum(! freq.fields %in% names(data)) > 0) {
    print(subset(freq.fields, ! freq.fields %in% names(data)))
    stop('Some of the required frequency fields are not in the data frame')
  }


######################
  all.variants.folder <- paste(oFolder, '/all_variants', sep= '')
  hom.variants.folder <- paste(oFolder, '/homozygous_variants', sep= '')
  chrX.folder <- paste(oFolder, '/chrX', sep= '')
  hom.mapping.folder <- paste(oFolder, '/hom_mapping', sep= '')
  het.variants.folder <- paste(oFolder, '/heterozygous_variants', sep= '')
  known.genes.folder <- paste(oFolder, '/known_genes', sep= '')
  compound.hets.folder <- paste(oFolder, '/compound_hets', sep= '')
  supportFolder <- paste(oFolder, '/support', sep= '')
  
  for (folder in c(oFolder, chrX.folder, all.variants.folder, hom.variants.folder, het.variants.folder, known.genes.folder, hom.mapping.folder, compound.hets.folder, supportFolder)) {
    if (!file.exists(folder)) dir.create(folder) else {
      old.files <- list.files(folder, full.names = TRUE, include.dir = FALSE)
      message('Will remove old files')
      print(old.files)
      print(file.remove( old.files) )
    }
  }
  
  
################### define the basic output folders, check what IDs are present
  if (is.null(explained.cases)) explained.cases <- rep(FALSE, length(my.cases))
  good.ids <- my.cases %in% names(data)
  correct.ids <- subset(my.cases, good.ids)
  explained.cases <- subset(explained.cases, good.ids)
  
  nsamples <- length(correct.ids)
  message(nsamples, ' present out of ', length(my.cases), ' specified')
  print(my.cases)
  
  support.list <- data.frame(samples = correct.ids, explained = explained.cases)
  write.csv(x = support.list, row.names = FALSE, file = paste(supportFolder, '/list_cases.csv', sep = ''))


################ Now plot the PCA matrix to see where the samples come from
  if (!is.null(PCA.pop.structure)) {
    if (file.exists(PCA.pop.structure)) {
      load(PCA.pop.structure)

      output.pdf <- paste(supportFolder, '/PCA_plot.pdf', sep = '')
      output.tab <- paste(supportFolder, '/PCA_data.csv', sep = '')

#### Now in cases some individuals are missing from the table
      in.PCA.table <- subset(correct.ids, correct.ids %in% row.names(pcs))
      
      message('Output PCA plot in ', output.pdf)
      pdf(output.pdf)
      plot (x = pcs[,1],
            y = pcs[,2],
            xlab = 'PC1',
            ylab = 'PC2',
            col = 'grey',
            pch = '+')
      
      if (length( in.PCA.table ) > 1) {
        PCA.cases <- pcs[ in.PCA.table, ]
        points(x = PCA.cases[,1],
               y = PCA.cases[,2],
               col = 'red',
               pch = 20)
        write.csv(x = PCA.cases, file = output.tab)  ##now give the location of the cases on the PCA plot
      }
      
      ### add 1KG labels
      uniq <- unique(population$pop)
      for (i in 1:length(uniq)){
        match <-  which(population$pop == uniq[i])
        match.select <- sample(match, 1)
        text(pcs[match.select,1], pcs[match.select,2], population$pop[match.select ] ,cex=0.7, pos=4, col="black")
      }
      
      dev.off()
      
    }
  }

  
  
################# build the matrix of calls
  message('Starting size of the data frame: ', nrow(data))
  message('Removing non filter') ###apply the basic VQSR filter
  acceptable.VQSR <- c('PASS', 'VQSRTrancheSNP99.00to99.90', 'VQSRTrancheSNP99.90to100.00', 'VQSRTrancheINDEL99.90to100.00', 'VQSRTrancheINDEL99.00to99.90')  
  data <- subset(data, FILTER %in% acceptable.VQSR)
  message('Starting size of the data frame after removing bad filters: ', nrow(data))
  
  matrix.calls <- matrix(data = NA, nrow = nrow(data), ncol = nsamples)
  dimnames(matrix.calls) = list(data$signature, correct.ids)
  for (id in correct.ids) {
     message(id)
     matrix.calls[, id] <- ifelse ( grepl(pattern = '^0\\|0', data[, id]), 0, matrix.calls[, id])
     matrix.calls[, id] <- ifelse ( grepl(pattern = '^0\\|1', data[, id]), 1, matrix.calls[, id])
     matrix.calls[, id] <- ifelse ( grepl(pattern = '^1\\|0', data[, id]), 1, matrix.calls[, id])
     matrix.calls[, id] <- ifelse ( grepl(pattern = '^1\\|1', data[, id]), 2, matrix.calls[, id])
  }

  data$ncarriers.cases <- apply(matrix.calls, FUN = function(x) {sum(x > 0, na.rm  =TRUE)}, MAR = 1)
  data$total.call.cases <- apply(matrix.calls, FUN = function(x) {sum(!is.na(x))}, MAR = 1)
  data$non.ref.calls.cases <- apply(matrix.calls, MAR = 1, FUN = sum, na.rm = TRUE)
  data$maf.cases <- data$non.ref.calls.cases/(2*data$total.call.cases)

  data$missing.rate.cases <- 1 - data$total.call.cases / max(data$total.call.cases, na.rm = TRUE)

  #if (sum(data$total.call.cases < 0, na.rm = TRUE)) {print(subset(data, total.call.cases < 0)); stop()}
  #if (sum(data$non.ref.calls.cases < 0, na.rm = TRUE)) {print(subset(data, non.ref.calls.cases < 0)); stop()}
  #if (sum(data$non.ref.calls.controls < 0, na.rm = TRUE)) {print(subset(data, non.ref.calls.controls < 0)); stop()}

  
  
########### Remove the samples that are not cases
  message('Nb of columns prior to removing non relevant samples ', ncol(data))
  row1 <- as.character(sapply(data[1,], FUN = function(x) {as.character(x)}))
  is.sample <- grepl(row1, pattern = '.\\|.:[0-9]*')
  to.remove <- which ( is.sample & ! names(data) %in% correct.ids)
  if (length(to.remove) > 0) data <- data[, - to.remove]
  message('Nb of columns after removing non relevant samples ', ncol(data))
  
####### get the sample names
  excess.message <- paste('More than', nb.IDs.to.show)
  data$Samples <- sapply(1:nrow(matrix.calls),
                         FUN = function(x) { if (data$ncarriers.cases[x] > nb.IDs.to.show) {return(excess.message)} else  {paste(dimnames(matrix.calls)[[2]][ which( matrix.calls[x,] > 0) ], collapse = ';')}},
                         simplify = TRUE)
  
  data <- annotate.standard.annovar.output(data,
                                           freq.fields = freq.fields,
                                           threshold.rare = threshold.rare,
                                           threshold.somewhat.rare = threshold.somewhat.rare,
                                           choice.transcripts = choice.transcripts,
                                           biomart.gene.description = biomart.gene.description)


###now some extra bit: use the control data as well if there is an external set

  if ('freq.external.controls' %in% names(data)) {
    message('Column with control frequency is available')
    message('Number of rare variants before control filter: ', sum(data$rare))
    data$somewhat.rare <- data$somewhat.rare & ( (data$non.ref.calls.external.controls <= 2) |  (data$freq.external.controls <= threshold.somewhat.rare) | is.na(data$freq.external.controls) )
    data$rare <- data$rare & ( (data$non.ref.calls.external.controls <= 1) |  (data$freq.external.controls <= threshold.rare) | is.na(data$freq.external.controls) )
    data$novel <- data$novel  &  (data$freq.external.controls == 0 | is.na(data$freq.external.controls))
    message('Number of rare variants after control filter: ', sum(data$rare))
  }

  message('Done with the rare/somewhat rare flags')

  
##### Now the case control analysis if this has been requested
  if (run.case.control.variant) {  ### note that at this stage the common rare frequency filters do not yet include the external set
    
############ single variant testing
    my.counts <- as(data[, c('total.call.cases', 'non.ref.calls.cases', 'total.calls.controls', 'non.ref.calls.controls')], 'matrix')
    data$pval.cc.single <- apply(my.counts, MAR = 1, FUN = function(x) {fisher.test(matrix(data = c(2*x[1], x[2], 2*x[3], x[4]), ncol = 2, nrow = 2))$p.value})
    single.variant.test <- subset(data, pval.cc.single < 0.01 & FILTER == 'PASS' & missing.rate.cases < 0.3 & !is.indel)  ##Should I remove the indels?
    single.variant.test <- single.variant.test[ order(single.variant.test$pval.cc.single), ]
    
    my.block <- c('pval.cc.single', 'Samples', 'Func', 'ExonicFunc', 'HUGO', 'Description', 'total.call.cases', 'non.ref.calls.cases', 'ncarriers.cases', 'missing.rate.cases', 'maf.cases', 'n.cases.conf.homs', 'freq.controls', 'total.calls.controls', 'non.ref.calls.controls', 'total.calls.external.controls', 'freq.external.controls', 'AAChange', 'is.indel', 'QUAL')
    my.names2 <-  c(subset(my.block, my.block %in% names(single.variant.test)),
                    subset(names(single.variant.test), ! (names(single.variant.test) %in% c(correct.ids, my.block, c('HomNames', 'HetNames')) ) ),
                    correct.ids)
    
    write.csv(single.variant.test[, my.names2], row.names = FALSE, file = paste(supportFolder, '/single_variant_tests.csv', sep = ''))
  }

  if (run.case.control.gene) { ######### gene based analysis
    message('Running the gene based case control tests')

    lof.cc <- test.case.control (data, correct.ids, type = 'lof', extra.gene.annotations.file = extra.gene.annotations.file, known.genes = known.genes)
    output.lof.cc <- paste(supportFolder, '/case_control_lof.csv', sep = '')
    write.csv(lof.cc$results, row.names = FALSE, file = output.lof.cc)
    message('Output in ', output.lof.cc)
    
    funct.cc <- test.case.control (data, correct.ids, type = 'functional', extra.gene.annotations.file = extra.gene.annotations.file, known.genes = known.genes)
    output.funct.cc <- paste(supportFolder, '/case_control_ns_splice_lof.csv', sep = '')
    write.csv(funct.cc$results, row.names = FALSE, file = output.funct.cc)
    message('Output in ', output.funct.cc)
    
    if (sum (explained.cases) > 0) {  ##is some cases have been explained, redo ir with this information
      lof.cc <- test.case.control (data, correct.ids[ ! explained.cases ], type = 'lof', extra.gene.annotations.file = extra.gene.annotations.file, known.genes = known.genes)
      output.lof.cc <- paste(supportFolder, '/case_control_not_explained_lof.csv', sep = '')
      write.csv(lof.cc$results, row.names = FALSE, file = output.lof.cc)
      message('Output in ', output.lof.cc)
      
      funct.cc <- test.case.control (data, correct.ids[ ! explained.cases ], type = 'functional', extra.gene.annotations.file = extra.gene.annotations.file, known.genes = known.genes)
      output.funct.cc <- paste(supportFolder, '/case_control_not_explained_ns_splice_lof.csv', sep = '')
      write.csv(funct.cc$results, row.names = FALSE, file = output.funct.cc)
      message('Output in ', output.funct.cc)
    }
  }
    

######### remove non variable sites in cases
  matrix.calls <- matrix.calls[ data$non.ref.calls.cases > 0, ]  ##need to fix this, I should not remove low depth variants? Or maybe OK because I do not use read depth?
  data <- subset(data, non.ref.calls.cases > 0)
  message('Size after removing non variable sites in cases: ', nrow(data))
  

################# Now start the proper filtering
  data$potential.comp.het <- FALSE
  data$n.cases.conf.homs <- 0
  summary.frame <- data.frame(ids = correct.ids,
                              n.exonic.calls = NA,
                              percent.homozyg = NA,
                              frac.het.on.X = NA,
                              n.somewhat.rare.exonic.calls = NA,
                              n.rare.exonic.calls = NA,
                              ngenes.comp.het.lof = NA,
                              ngenes.comp.het.func = NA,
                              n.func.rare.calls = NA,
                              n.func.rare.hom.calls = NA,
                              n.lof.rare.calls = NA,
                              n.lof.rare.hom.calls = NA)

  
  for (sample in 1:length(correct.ids)) {
    id <- correct.ids[ sample ]
    message('Sample ', id)

    depth <- as.numeric(gsub(pattern = '.*:', replacement = '', data[, id]))
    data$n.cases.conf.homs <- data$n.cases.conf.homs + ((depth >= depth.threshold.conf.homs) &  matrix.calls[, id] == 2 & !is.na(matrix.calls[, id]))
    
    
    selected <- matrix.calls[, id] %in% c(1, 2) & !is.na(matrix.calls[, id])
    loc.calls <- data[ selected, ]
    loc.calls$Depth <- depth [ selected ]
    calls <- matrix.calls[selected , id]

    good.hom <- (loc.calls$Depth >= 5) & (calls == 2) & !is.na(calls)
    
    summary.frame$n.func.rare.calls[ sample ] <- sum(loc.calls$rare & (loc.calls$splicing | loc.calls$lof | loc.calls$non.syn) & !loc.calls$remove.bad.transcripts , na.rm = TRUE)
    summary.frame$n.func.rare.hom.calls[ sample ] <- sum(loc.calls$rare & (loc.calls$splicing | loc.calls$lof | loc.calls$non.syn) & !loc.calls$remove.bad.transcripts  & good.hom, na.rm = TRUE)
    summary.frame$n.lof.rare.calls[ sample ] <- sum(loc.calls$rare & loc.calls$lof, na.rm = TRUE)
    summary.frame$n.lof.rare.hom.calls[ sample ] <- sum(loc.calls$rare & loc.calls$lof & good.hom, na.rm = TRUE)
    
    summary.frame$n.exonic.calls[ sample ] <- sum(loc.calls$Func == 'exonic', na.rm = TRUE)
    summary.frame$n.rare.exonic.calls[ sample ] <- sum(loc.calls$Func == 'exonic' & loc.calls$rare, na.rm = TRUE)
    summary.frame$n.somewhat.rare.exonic.calls[ sample ] <- sum(loc.calls$Func == 'exonic' & loc.calls$somewhat.rare, na.rm = TRUE)
    summary.frame$frac.het.on.X[ sample ] <- sum( (loc.calls$Chr == 'X') & calls == 1, na.rm = TRUE)/ sum(loc.calls$Chr == 'X' & calls %in% c(1, 2), na.rm = TRUE)

    
######### preferred choice to print the labels
    my.block <- c('Samples', 'Func', 'ExonicFunc', 'HUGO', 'Description', 'non.ref.calls.cases', 'ncarriers.cases', 'missing.rate.cases', 'freq.controls', 'total.calls.controls', 'non.ref.calls.controls', 'total.calls.external.controls', 'freq.external.controls', 'AAChange', id, 'Depth', 'is.indel', 'QUAL')
    my.names2 <-  c(subset(my.block, my.block %in% names(data)), subset(names(data), ! (names(data) %in% c(correct.ids, my.block) ) ))
    my.names2 <- subset(my.names2, ! my.names2 %in% c('Otherinfo', 'Gene.Start..bp.', 'Gene.End..bp.', 'MIM.Gene.Description', 'n.cases.conf.homs', 'HetNames', 'HomNames'))
    
##### output the full list of calls for this sample
    if (print.individual.files) {
      output.all <- paste(all.variants.folder, '/', id, '.csv', sep = '')
      write.csv(x = loc.calls[, my.names2], file = output.all, row.names = FALSE)
      message('Outputting all variants in ', output.all, ', ncalls: ', nrow(loc.calls))
    }
    
############# Now the compound hets
    tab.genes <- table(subset(loc.calls$HUGO.no.splice.info, loc.calls$somewhat.rare & (loc.calls$splicing | loc.calls$non.syn | loc.calls$lof) & !loc.calls$remove.bad.transcripts ))
    potential.comp.het.genes <- subset(tab.genes, tab.genes >= 2)
    comp.het.frame <- subset( loc.calls, HUGO.no.splice.info %in% names(potential.comp.het.genes) & somewhat.rare & (splicing | non.syn | lof) & !loc.calls$remove.bad.transcripts )
    summary.frame$ngenes.comp.het.func[ sample ] <- length( potential.comp.het.genes )
    
    tab.genes.lof <- table(subset(loc.calls$HUGO.no.splice.info, loc.calls$somewhat.rare & loc.calls$lof & !loc.calls$remove.bad.transcripts))
    potential.comp.het.genes.lof <- subset(tab.genes.lof, tab.genes.lof >= 2)
    summary.frame$ngenes.comp.het.lof[ sample ] <- length( potential.comp.het.genes.lof)
    
    output.comp.hets <- paste(compound.hets.folder, '/', id, '.csv', sep = '')
    write.csv(x = comp.het.frame[, my.names2], file = output.comp.hets, row.names = FALSE)
    message('Outputting all compound het functional variants in ', output.comp.hets, ', ncalls: ', nrow(comp.het.frame))
  
    data$potential.comp.het <- data$potential.comp.het | data$signature %in% comp.het.frame$signature

    
######## homozygosity mapping
    if (hom.mapping) {
      output.pdf <- paste(hom.mapping.folder, '/', id, '.pdf', sep = '')
      pdf(output.pdf, width = 8, height = 14)
      
      hzig.frame <- data.frame(Het = (calls == 1), positions = loc.calls$Start, chromosome = loc.calls$Chr, depth = loc.calls$Depth, SegDup = loc.calls$SegDup, is.indel = loc.calls$is.indel)
      hzig.frame <- hzig.frame[ is.na(hzig.frame$SegDup) & ! hzig.frame$is.indel, ]
      
      hzig.frame <- subset(hzig.frame, chromosome %in% as.character(1:22))
      hzig.frame <- subset(hzig.frame, ! ( !Het  & depth < 7) ) ##remove low depth homozygous calls
      hzig.frame <- hzig.frame[ order(as.numeric(hzig.frame$chromosome), hzig.frame$positions), ]
      my.homozyg <- homozyg.mapping.v2 (hzig.frame$Het, positions = hzig.frame$positions, chromosome = hzig.frame$chromosome, plot = TRUE)
      dev.off()
      message('Homozygosity mapping plot in ', output.pdf)
      regions <- my.homozyg[[2]]
      
      if (nrow(regions) >= 1) {
        summary.frame$percent.homozyg[ sample ] <- sum (regions$end - regions$start) / (3*10^9)
      } else {summary.frame$percent.homozyg[ sample ] <- 0}
        
      if (nrow(regions) >= 1) {
        hom.mapping.candidates <- data.frame()
        for (region in 1:nrow(regions)) {
          hmap.loc <- subset(loc.calls, somewhat.rare & calls > 0 & (non.syn | splicing | lof) & !remove.bad.transcripts & (Start > regions$start[region]) & (Start < regions$end[region]) & (Chr == regions$chromosome[region]))
          hom.mapping.candidates <- rbind.data.frame(hom.mapping.candidates, hmap.loc)
        }
        
        hom.mapping.candidates <- hom.mapping.candidates[, my.names2]
        output.hmap <- paste(hom.mapping.folder, '/', id, '.csv', sep = '')
        write.csv(x = hom.mapping.candidates[, my.names2], file = output.hmap, row.names = FALSE)
        message('Outputting hom mapping variants in ', output.hmap, ', ncalls: ', nrow(hom.mapping.candidates))
      
        output.regions <- paste(hom.mapping.folder, '/', id, '_regions.csv', sep = '')
        write.csv(x = regions, file = output.regions, row.names = FALSE)
        message('Outputting hom mapping regions in ', output.regions, ', nregions: ', nrow(regions))      
      }
    }

##### now the somewhat.rare homs- note that I exclude chrX calls for now in that list
    rare.homs <- subset(loc.calls, (! Chr %in% c('X', 'Y'))  & somewhat.rare & calls == 2 & (non.syn | splicing | lof) & !remove.bad.transcripts & (Depth >= depth.threshold.conf.homs))
    rare.homs <- rare.homs[, my.names2]

    output.homs <- paste(hom.variants.folder, '/', id, '.csv', sep = '')
    write.csv(x = rare.homs, file = output.homs, row.names = FALSE)
    message('Outputting all rare homozygous functional variants in ', output.homs, ', ncalls: ', nrow(rare.homs))
    
    
##### now the somewhat.rare hets
    rare.hets <- subset(loc.calls, somewhat.rare & calls >= 1 & (non.syn | splicing | lof) & !remove.bad.transcripts)
    rare.hets <- rare.hets[, my.names2]

    output.hets <- paste(het.variants.folder, '/', id, '.csv', sep = '')
    write.csv(x = rare.hets, file = output.hets, row.names = FALSE)
    message('Outputting all rare heterozygous functional variants in ', output.hets, ', ncalls: ', nrow(rare.hets))
    
    

##### now the variants in known genes, keep the wrong transcripts in this folder for now
    known.genes.calls <- subset(loc.calls, somewhat.rare & calls >= 1 & (non.syn | splicing | lof) 
                                & (Gene %in% known.genes | gsub(pattern = '\\(.*', replacement = '', loc.calls$HUGO) %in% known.genes | HUGO %in% known.genes))
    known.genes.calls <- known.genes.calls[, my.names2]
    output.known <- paste(known.genes.folder, '/', id, '.csv', sep = '')
    write.csv(x = known.genes.calls, file = output.known, row.names = FALSE)
    message('Outputting all rare variants in known genes ', output.known, ', ncalls: ', nrow(known.genes.calls))
  }



  
############################################################ preferred choice to print the labels
  my.block <- c('Samples', 'Func', 'ExonicFunc', 'HUGO', 'Description', 'total.call.cases', 'non.ref.calls.cases', 'ncarriers.cases', 'maf.cases', 'n.cases.conf.homs', 'freq.controls', 'total.calls.controls', 'non.ref.calls.controls', 'total.calls.external.controls', 'freq.external.controls', 'pval.cc.single', 'AAChange', 'is.indel', 'QUAL')
  my.names2 <-  c(subset(my.block, my.block %in% names(data)),
                  subset(names(data), ! (names(data) %in% c(correct.ids, my.block, c('HomNames', 'HetNames')) ) ),
                  correct.ids)
  
  #### output all sorts of overall tables
  output.all.variants <- paste(oFolder, '/all_somewhat_rare_variants_cases.csv', sep = '')
  all.variants <- subset(data, total.call.cases > 0 & somewhat.rare)
  write.csv(x = all.variants[, my.names2], file = output.all.variants, row.names = FALSE)

  ##known genes
  known.genes.calls <- subset(data, (non.syn | splicing | lof) & (HUGO %in% known.genes | Gene %in% known.genes | gsub(pattern = '\\(.*', replacement = '', data$HUGO) %in% known.genes ) & somewhat.rare)
  output.known.genes <- paste(oFolder, '/known_genes.csv', sep = '')
  write.csv(x = known.genes.calls[, my.names2], file = output.known.genes, row.names = FALSE)

  ##compound hets
  comp.hets <- subset(data, potential.comp.het)
  output.comp.hets<- paste(oFolder, '/comp_het_candidates.csv', sep = '')
  write.csv(x = comp.hets[, my.names2], file = output.comp.hets, row.names = FALSE)
    
  ##hom candidates
  is.hom.in.at.least.one <- apply(matrix.calls, MAR = 1, FUN = max, na.rm = TRUE)
  hom.candidates <- subset(data, is.hom.in.at.least.one == 2 & somewhat.rare & (lof | splicing | non.syn))
  output.homs <- paste(oFolder, '/hom_candidates.csv', sep = '')
  write.csv(x = hom.candidates[, my.names2], file = output.homs, row.names = FALSE)

  ##signatures
  signatures <- data[, c('maf.cases', 'total.call.cases', 'signature')]
  write.csv(x = signatures, file = paste(oFolder, '/signatures.csv', sep = ''), row.names = FALSE)

  ###
  write.csv(x = summary.frame,
            file = paste(supportFolder, '/summary_frame.csv', sep = ''),
            row.names = FALSE)


  stamp.file <- paste(oFolder, '/time_stamp.txt', sep = '')
  cat(date(), file = stamp.file)
  cat(paste('\nThreshold for rare variants :', threshold.rare, '\nThreshold for somewhat rare variants: ', threshold.somewhat.rare),  file = stamp.file, append = TRUE)
  
}
