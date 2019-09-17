# getVarsForProteinPaint
# copyright 2019 David Curtis and Sreejan Bandyopadhyay
#
# Extract relevant variant counts by gene and transcript from scoreassoc output files

# Set variables in next few lines
# prefixSpec is used in the main body of the code as follows:
#    prefix = sprintf(prefixSpec, cohort_names[cc])
#    saoFile=sprintf("%s/%s.%s.sao",resultsFolder,prefix,gene)

resultsFolder="/home/sbandyop/SCHEMA/allResultsSCHEMA"
outputFolder="/home/sbandyop/SCHEMA/results"
geneOutputFile="SCHEMA_genes.txt"
cohort_names_file = "/home/sbandyop/SCHEMA/bothFiles/cohort.names.txt"
cohort_names = readLines(cohort_names_file)
prefixSpec="gva.%s.rare"
geneFile=""
# genes=readLines(geneFile)
genes=c("FYN") 
outputFolder="/home/sbandyop/SCHEMA/results"

resultsFolder="/cluster/project9/bipolargenomes/ADSP/ADSP.all/results"
# resultsFolder="/home/rejudcu/tmp"
outputFolder="/home/rejudcu/tmp"
geneOutputFile="ADSP.C1R.txt"
genes=c("C1R") 
cohort_names = c("gva")
prefixSpec="%s"

entriesPerTranscript=25
entriesPerTranscript=29

gnomADFile="/home/rejudcu/reference/gnomad.exomes.r2.0.2.sites.vcf.bgz" 
results_list <- list()
AFs=c("AF_AFR","AF_AMR","AF_ASJ","AF_EAS","AF_FIN","AF_NFE","AF_OTH","AF_SAS") 

maxTranscripts=30
maxHetsToUse=100
weight_threshold <-  50

g=1
setwd(outputFolder)

getVCFLine=function(vcfFile,tempFile,chr,pos) {
  if (file.exists(tempFile)) file.remove(tempFile)
  
  tabixCommand=sprintf("tabix %s %d:%f-%f > %s",vcfFile,chr,pos,pos,tempFile)
  print(tabixCommand)
  system(tabixCommand)
  if (file.exists(tempFile)) {
    tabixLines=readLines(tempFile)
    tabixLine=tabixLines[1]
  }
  if (is.na(tabixLine)) tabixLine=""
  return(tabixLine)
}

getVCFEntry=function(vcfLine,entryTag) {
  tag=paste(entryTag,"=",sep="")
  entries=unlist(strsplit(vcfLine,";"))
  entry=pmatch(entryTag,entries)
  value=""
  if (!is.na(entry)) {
    value=unlist(strsplit(entries[entry],"="))[2]
  }
  return(value)
}

g=1
setwd(outputFolder)


gResult=data.frame(matrix(NA, ncol = 6, nrow =length(genes)))
colnames(gResult)=c("Gene","SLP","numContDis","numCaseDis","numContDam","numCaseDam")


for (gg in 1:length(genes)){
  
  for (cc in 1:length(cohort_names)){
    gene=genes[gg]
    nValid=0
    nContDis=0
    nCaseDis=0
    nContDam=0
    nCaseDam=0
    prefix = sprintf(prefixSpec, cohort_names[cc])
    saoFile=sprintf("%s/%s.%s.sao",resultsFolder,prefix,gene)
    
    
    lines=readLines(saoFile)
    
    lResults=data.frame(matrix(NA, ncol = 7+length(AFs), nrow = length(lines))) #make sure to cut this down to nValid later on 
    colnames(lResults)=c(c("gene","chr","pos","DNAChange","aaChange","control","case"),AFs)
    locRow=0
    pResults=data.frame(matrix(NA, ncol = 8, nrow = length(lines)*maxTranscripts),stringsAsFactors=FALSE)
    colnames(pResults)=c("gene","transcript","amino_acid_position","amino_acid_change","control","case","chr","pos")
    
    r=1
    
    for (ll in 1:length(lines)) #add nValid = nValid +1 at the bottom of this loop
    {   #use ll=4 when testing as all conditions work 
      words=strsplit(lines[ll],"\\s+")[[1]] 
      if (length(words)!=17) next
      weight=as.numeric(words[16])
      if (weight < weight_threshold) next
      print(weight)
      control = as.numeric(words[4])
      case = as.numeric(words[10])
      if (case+control > maxHetsToUse) next
      
      current_line = lines[ll]
      split_string = unlist(strsplit(current_line, split=":")) 
      chromosome = split_string[1]
      
      
      if (grepl(".", split_string[2], fixed=TRUE)){
        pos = unlist(strsplit(split_string[2], "."))
        chromosome_position = pos[1]
      } else {
        chromosome_position = split_string[2]
      }
      locRow=locRow+1
      lResults$gene[locRow]=gene
      lResults$chr[locRow]=chromosome
      lResults$pos[locRow]=chromosome_position
      lResults$control[locRow]=control
      lResults$case[locRow]=case
      gnomadLine=getVCFLine(gnomADFile,sprintf("%s/%s",outputFolder,"tempGnomAD.vcf"),as.numeric(chromosome),as.numeric(chromosome_position))
      for (f in 1:length(AFs)) 
      {	
        if (gnomadLine=="") {
          lResults[locRow,7+f]=0
        } else {
          lResults[locRow,7+f]=sum(as.numeric(unlist(strsplit(getVCFEntry(gnomadLine,AFs[f]),",")))) # "0.2,0.15" for different alleles
        }
      }
      aWords=strsplit(current_line,"\\|")[[1]]
      t=-entriesPerTranscript
      while (t<length(aWords)-(18+entriesPerTranscript))
      {
        t=t+entriesPerTranscript
        aGene=aWords[t+4]
        if (gene!=aGene) next
        transcript=(aWords[t+7])
        amino_acid_position = (aWords[t+15]) # can be e.g. 1338-1339
        amino_acid_position = strsplit(amino_acid_position,"-")[[1]][1]
        amino_acid_change = aWords[t+16]
        DNA_change=aWords[t+17]
        
        
        if (amino_acid_change=="") next # e.g. upstream in this transcript
        print(gene)
        print(transcript)
        print(amino_acid_position)
        print(amino_acid_change)
        if (is.na(lResults$aaChange[locRow])) {
          lResults$aaChange[locRow]=amino_acid_change
          lResults$DNAChange[locRow]=DNA_change
        }
        pResults[r,1] = gene
        pResults[r,2] = transcript
        pResults[r,3] = amino_acid_position
        pResults[r,4] = amino_acid_change
        pResults[r,5] = control
        pResults[r,6] = case
        pResults[r,7] = as.numeric(chromosome)
        pResults[r,8] = as.numeric(chromosome_position)
        r = r+1
      }
      if (grepl("X",lResults$aaChange[locRow],fixed=TRUE) || grepl("*",lResults$aaChange[locRow],fixed=TRUE)) {
        nContDis=nContDis+control
        nCaseDis=nCaseDis+case
        r=r-1# do not use this row
      }else {
        nContDam=nContDam+control
        nCaseDam=nCaseDam+case
      }
      nValid = nValid + 1
    }
    pResults=pResults[1:(r-1),] #this line might cause problems 
    print(pResults)
    
    aaFile=sprintf("%s/%s.%s.aa.txt", outputFolder, cohort_names[cc], gene)
    
    write.table(pResults, aaFile,quote=FALSE)
    locFile=sprintf("%s/%s.%s.vars.txt", outputFolder, cohort_names[cc], gene)
    write.table(lResults,locFile)
    results_list[[cc]] <- pResults
  }
  all_results <- data.frame(matrix(NA, ncol = 8, nrow = 0))
  colnames(all_results)=c("gene","transcript","amino_acid_position","amino_acid_change","control","case","chr","pos")
  
  
  for (i in 1:length(results_list)){
    pResults <- results_list[[i]]
    ys <- seq(1:nrow(pResults))
    for (y in ys){
      if (is.na(pResults[y, "transcript"])) next
      
      index <- which ((pResults[y,"pos"] == all_results$pos) & (pResults[y, "transcript"] == all_results$transcript) )
      
      
      if (length(index) == 0){
        all_results <- rbind(all_results,  pResults[y, ])
      }
      else {
        all_results[index, "control"] <-  as.numeric(all_results[index, "control"]) + as.numeric(pResults[y, "control"])
        all_results[index, "case"] <- as.numeric(all_results[index, "case"]) + as.numeric(pResults[y, "case"])
      }
    }
  }
  aResultsFile = sprintf("%s/%s.aa.txt", outputFolder, gene)
  write.table(all_results, aResultsFile,quote=FALSE)
  pResults <- all_results
 
  
  transcripts = unique(pResults[,2])
  for (tran in transcripts)
  {
    output=""
    tResults=subset(pResults,transcript==tran)
    for (tt in 1:nrow(tResults))
    {
      if (tResults[tt,4]!="")
      {
        aa=strsplit(tResults[tt,4],"/")[[1]]
        control=tResults[tt,5]
        case=tResults[tt,6]
        if (case+control > maxHetsToUse) next
        if (grepl("X",aa[2],fixed=TRUE) || grepl("*",aa[2],fixed=TRUE) || grepl("X",aa[1],fixed=TRUE)) next # ignore frameshift and nonsense
        if (control>0)
        {
          for (c in 1:control)
          {
            output=sprintf("%s%s%s%s;chr%d:%d;D\n",output,aa[1],tResults[tt,3],aa[2],tResults[tt,7],floor(tResults[tt,8]))
          }
        }
        if (case>0)
        {
          for (c in 1:case)
          {
            output=sprintf("%s%s%s%s;chr%d:%d;X\n",output,aa[1],tResults[tt,3],aa[2],tResults[tt,7],floor(tResults[tt,8]))
          }
        }
      }
    }
    tFile=sprintf("%s/%s.%s.vars.txt", outputFolder, gene,tran)
    writeLines(output,tFile)
  }
  gResult$numContDam[gg]=nContDam
  gResult$numCaseDam[gg]=nCaseDam
  gResult$numContDis[gg]=nContDis
  gResult$numCaseDis[gg]=nCaseDis
}
genes
fn=sprintf("%s/%s",outputFolder,geneOutputFile)
write.table(gResult,fn)


