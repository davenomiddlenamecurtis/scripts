genes=c("SETD1A","HERC1","TRIO","S1PR4","RTKN","FYN","GRIN2A","GRIN2B","GRIN1","CAMK2A","CAMK2B","CAMK2G","CAMK2D","PRKCA","PRKACA")
resultsFolder="/cluster/project9/bipolargenomes/SSS2/SSS2.VEP.both/results"
annotationFile="/home/rejudcu/vcf/SSS2/SSS2.vars.annot.vcf.gz"
outputFolder="/cluster/project9/bipolargenomes/antonia/results"
prefix="SSS2.VEP.both"

annotationFile="/home/rejudcu/vcf/SSS2/SSS2.multiple.annot.vcf.gz"
averageTranscripts=20
pResults=data.frame(matrix(0, ncol = 6, nrow = length(genes)*averageTranscripts),stringsAsFactors=FALSE)
colnames(pResults)=c("gene","transcript","amino_acid_position","amino_acid_change","control","case")

# genes=c("GRIN1")
# outputFolder="/home/rejudcu/tmp"

g=1
r=1
for (gene in genes)
{
saoFile=sprintf("%s/%s.%s.sao",resultsFolder,prefix,gene)
saoFile
lines=readLines(saoFile)
commandString=sprintf("tabix %s ", annotationFile)
commandString
    
lines=readLines(saoFile)
	l=1;
	for (ll in 1:length(lines))
		{
		words=strsplit(lines[ll],"\\s+")[[1]] 
		if (length(words)!=17) next
		weight=as.numeric(words[16])
		if (weight < 150) next
		print(weight)
	    control = words[4]
	    case = words[10]
		
        current_line = lines[ll]
        split_string = unlist(strsplit(current_line, split=":")) 
        chromosome = split_string[1]
        chromosome_position = split_string[2]
        print(chromosome)
        print(chromosome_position)		
        	
		commandString=sprintf(" %s %s:%s-%s ", commandString,chromosome,chromosome_position,chromosome_position)
		print(commandString)
		}
		
geneAnnotFile=sprintf("%s/%s.annot.vcf", outputFolder,gene)	
commandString=sprintf(" %s> %s ", commandString,geneAnnotFile)
system(commandString)

lines=readLines(geneAnnotFile)


	l=1;
	for (ll in 1:length(lines))
		{
		words=strsplit(lines[ll],"\\|")[[1]]
		gene=(words[4])
		t=0
		while (t<length(words)-18)
		{
		transcript=(words[t+7])
		amino_acid_position = (words[t+15])
        amino_acid_change = (words[t+16])
        print(gene)
        print(transcript)
        print(amino_acid_position)
        print(amino_acid_change)
        
        pResults[r,1] = gene
        pResults[r,2] = transcript
		pResults[r,3] = amino_acid_position
		pResults[r,4] = amino_acid_change
	    pResults[r,5] = control
	    pResults[r,6] = case
	    r = r+1
		t=t+25
		}
		}
pResults=pResults[1:(r-1),]
print(pResults)

aaFile=sprintf("%s/%s.aa.txt", outputFolder, gene)

write.table(pResults, aaFile)
        }
