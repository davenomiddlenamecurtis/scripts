wd="/Users/dave_000/OneDrive/dave/refs/ADSP"
saoFile="ADSP.all.summ.txt"

stripZeroGenes=TRUE

library(ggplot2)

qqSLPs<-function(SLPs) {
	rankSLP <- rank(SLPs, na.last=TRUE, ties.method="first")
	nelem=length(SLPs)
	midrank <- (nelem+1)/2
	rMinusMr <- rankSLP-midrank
	absDiff <- abs(rMinusMr/midrank)
	pVal <- 1-absDiff
	logP <- log10(pVal)
	eSLPs <- sign(rankSLP - midrank) * -logP
	return(eSLPs)
}

setwd(wd)
results=data.frame(read.table(saoFile,header=TRUE))
total=rowSums(results[,2:ncol(results)])
results=results[which(total != 0),]

for (c in 2:ncol(results))
{
	SLP=results[,c]
	top=max(SLP)
	bottom=min(SLP)
	SLP=SLP[order(-SLP)]
	eSLP=qqSLPs(SLP)
	filename=sprintf("QQ.%s.png",colnames(results)[c])
	ppi=600
	png(filename,width=6*ppi, height=6*ppi, res=ppi)
	colnames(results)[4]="SLP"
	eSLPname=sprintf("e%s",colnames(results)[c])
	toPlot=data.frame(matrix(ncol=2,nrow=nrow(results)))
	toPlot[,1]=SLP
	toPlot[,2]=eSLP
	colnames(toPlot)=c(colnames(results)[c],eSLPname)
	myplot=ggplot(toPlot,aes_q(x=as.name(eSLPname),y=as.name(colnames(results)[c])))+geom_point(size=1)+ theme_bw() + 
		geom_hline(yintercept=0,size=1.0) +
		geom_vline(xintercept=0,size=1.0) +
		theme(panel.grid.major=element_line(colour = "black",size=0.25)) +
		scale_x_continuous(breaks = seq(2*floor(bottom/2),2*ceiling(top/2),by =2),minor_breaks=NULL,limits=c(2*floor(bottom/2),2*ceiling(top/2))) +
		scale_y_continuous(breaks = seq(2*floor(bottom/2),2*ceiling(top/2),by =2),minor_breaks=NULL,limits=c(2*floor(bottom/2),2*ceiling(top/2))) 
	print(myplot)
	dev.off()
	pos=toPlot[which(SLP>=0),]
	pos=pos[201:nrow(pos),] # remove top 100 genes
	l=lm(pos[,1] ~ pos[,2])
	print(l)
	neg=toPlot[which(SLP<0),]
	neg=neg[1:(nrow(pos)-200),]
	l=lm(neg[,1] ~ neg[,2])
	print(l)
	
}
