geneFile="/home/rejudcu/NMDAR/NMDARgenes.lst"
genes=c("FYN","GRIN2A","GRIN2B","GRIN1","CAMK2A","CAMK2B","CAMK2G","CAMK2D","PRKCA","PRKACA","SRC","CSNK2A1","CSNK2A2","CSNK2B","PTK2B")
resultsFolder="/cluster/project9/bipolargenomes/SSS2/SSS2.VEP.both/results"
annotationFile="/home/rejudcu/vcf/SSS2/SSS2.multiple.annot.vcf.gz"
outputFolder="/cluster/project9/bipolargenomes/antonia/results"
prefix="SSS2.VEP.both"
argFile="/home/rejudcu/pars/gva.SSS2.VEP.both.arg"
gnomADFile="/cluster/project9/bipolargenomes/gnomAD/gnomad.exomes.r2.0.2.sites.vcf.bgz"
AFs=c("AF_AFR","AF_AMR","AF_ASJ","AF_EAS","AF_FIN","AF_NFE","AF_OTH","AF_SAS")
geneOutputFile="NMDARgenes.txt"
maxTranscripts=30

maxHetsToUse=10


g=1
setwd(outputFolder)

getVCFLine=function(vcfFile,tempFile,chr,pos) {
if (file.exists(tempFile)) file.remove(tempFile)

tabixCommand=sprintf("tabix %s %d:%d-%d > %s",vcfFile,chr,pos,pos,tempFile)
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
for (gg in 1:length(genes))
{
gene=genes[gg]
nValid=0
nContDis=0
nCaseDis=0
nContDam=0
nCaseDam=0
saoFile=sprintf("%s/%s.%s.sao",resultsFolder,prefix,gene)
  
lines=readLines(saoFile)
commandString=sprintf("tabix %s ", annotationFile)

		for (ll in 1:length(lines))
		{
		words=strsplit(lines[ll],"\\s+")[[1]] 
		if (length(words)>2 && words[1]=="SLP") {
			gResult[gg,1]=gene
			gResult[gg,2]=words[3]
			}
		if (length(words)!=17) next
		weight=as.numeric(words[16])
		if (weight < 150) next
		print(weight)
	    control = as.numeric(words[4])
	    case = as.numeric(words[10])
		if (case+control > maxHetsToUse) next
		
        current_line = lines[ll]
        split_string = unlist(strsplit(current_line, split=":")) 
        chromosome = split_string[1]
        chromosome_position = split_string[2]
        print(chromosome)
        print(chromosome_position)
		commandString=sprintf(" %s %s:%s-%s ", commandString,chromosome,chromosome_position,chromosome_position)
		print(commandString)
		sASCommand=sprintf("showAltSubs --arg-file %s --position %s:%s > %s/%s.%s.%s.subs.txt",argFile,chromosome,chromosome_position,outputFolder,gene,chromosome,chromosome_position)
		print(sASCommand)
        system(sASCommand)
		nValid=nValid+1
		}
		
	geneAnnotFile=sprintf("%s/%s.annot.vcf", outputFolder,gene)	
	commandString=sprintf(" %s> %s ", commandString,geneAnnotFile)
	system(commandString)

	r=1
	aLines=readLines(geneAnnotFile)
	aL=1
	lResults=data.frame(matrix(NA, ncol = 7+length(AFs), nrow = nValid))
	colnames(lResults)=c(c("gene","chr","pos","DNAChange","aaChange","control","case"),AFs)
	locRow=0
	pResults=data.frame(matrix(NA, ncol = 8, nrow = length(aLines)*maxTranscripts),stringsAsFactors=FALSE)
	colnames(pResults)=c("gene","transcript","amino_acid_position","amino_acid_change","control","case","chr","pos")
	for (ll in 1:length(lines))
	{
		words=strsplit(lines[ll],"\\s+")[[1]] 
		if (length(words)!=17) next
		weight=as.numeric(words[16])
		if (weight < 150) next
		print(weight)
	    control = as.numeric(words[4])
	    case = as.numeric(words[10])
		if (case+control > maxHetsToUse) next
		
        current_line = lines[ll]
        split_string = unlist(strsplit(current_line, split=":")) 
        chromosome = split_string[1]
        chromosome_position = split_string[2]

		aWords=strsplit(aLines[aL],"\\|")[[1]]
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
		

		t=-25
		while (t<length(aWords)-(18+25))
		{
			t=t+25
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
			}
		else {
			nContDam=nContDam+control
			nCaseDam=nCaseDam+case
		}
		aL=aL+1
	}
pResults=pResults[1:(r-1),]
print(pResults)

aaFile=sprintf("%s/%s.aa.txt", outputFolder, gene)

write.table(pResults, aaFile,quote=FALSE)
locFile=sprintf("%s/%s.vars.txt", outputFolder, gene)
write.table(lResults,locFile)


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
				output=sprintf("%s%s%s%s;chr%d:%d;D\n",output,aa[1],tResults[tt,3],aa[2],tResults[tt,7],tResults[tt,8])
				}
			}
			if (case>0)
			{
			for (c in 1:case)
				{
				output=sprintf("%s%s%s%s;chr%d:%d;X\n",output,aa[1],tResults[tt,3],aa[2],tResults[tt,7],tResults[tt,8])
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



		
