outputFolder="/home/rejudcu/ADSP/genes"
structureFile="/home/rejudcu/ADSP/genes/structures.ADSP.txt"

readCifLoop=function(lines,l) { # read a loop from a cif file as long as there are no spaces in any entries
  if (substr(lines[l],1,4)!="loop") {
    print("Error in readCifLoop() - first line does not start with loop")
    return (NA)
  }
  ll=l+1
  while (substr(lines[ll],1,1) == "_") ll=ll+1
  colNames=lines[(l+1):(ll-1)]
  colNames=gsub("\\s","",colNames)
  nCol=length(colNames)
  l=ll
  while (substr(lines[ll],1,1) != "#") ll=ll+1
  originalLines=lines[l:(ll-1)]
  fL=0
  oL=1
  words=""
  fixedLines=character()
  while (oL<=length(originalLines))
    {
	if (substr(originalLines[oL],1,1)!=";") {
	  words=sprintf("%s %s", words,originalLines[oL]) # gives an extra space at the start
	  } else {
	  longLine=""
	  while (substr(originalLines[oL],1,1)!=";") {
	    longLine=paste(longLine,originalLines[oL])
		oL=oL+1
		}
	  words=sprintf("%s %s", words,longLine)
	  }
	  oL=oL+1
	  s=strsplit(words,"\\s+")[[1]]
	  if (length(s)==nCol+1) { 
	    fL=fL+1
		fixedLines[fL]=words
		words=""
	  }
	}
  newTable=data.frame(matrix(NA, ncol = nCol, nrow = fL))
  colnames(newTable)=colNames
  for (r in 1:fL)
  {
    newTable[r,]=strsplit(fixedLines[r],"\\s+")[[1]][2:(nCol+1)]
  }
  return(newTable)
}

structures=data.frame(read.table(structureFile,header=TRUE,stringsAsFactors=FALSE))
setwd(outputFolder)

for (r in 1:nrow(structures))
{
  structure=structures$Structure[r]
  fn=sprintf("%s.cif",structure)
  if (!file.exists(fn)) {
    commLine=sprintf("wget https://files.rcsb.org/view/%s",fn)
	system(commLine)
	}
  cif=readLines(fn)
  l=grep("_struct_ref_seq.seq_align_beg",cif) # all this will fail if some things are done with loop and others not
  if (length(strsplit(cif[l],"\\s+")[[1]])>1) { # we do not have the loop format to parse, just one set of entries, I hope
    colNames=c("_struct_ref_seq.pdbx_db_accession",
	  "_struct_ref_seq.pdbx_strand_id",
	  "_struct_ref_seq.seq_align_beg","_struct_ref_seq.seq_align_end",
	  "_struct_ref_seq.db_align_beg","_struct_ref_seq.db_align_end",
	  "_struct_ref_seq.pdbx_auth_seq_align_beg","_struct_ref_seq.pdbx_auth_seq_align_end")
	alignTable=data.frame(matrix(NA, ncol = length(colNames), nrow = 1))
	colnames(alignTable)=colNames
	for (c in 1:3)
	  {
	  alignTable[1,c]=strsplit(cif[grep(colNames[c],cif)],"\\s+")[[1]][2]
	  }
	for (c in 4:ncol(alignTable))
	  {
	  alignTable[1,c]=as.numeric(strsplit(cif[grep(colNames[c],cif)],"\\s+")[[1]][2])
	  }
  } else { 
    l=grep("_struct_ref_seq.db_align_beg",cif)
	while (substr(cif[l],1,4)!="loop") l=l-1
	alignTable=readCifLoop(cif,l)
  }
  alignTable$'_struct_ref_seq.db_align_beg'=as.numeric(alignTable$'_struct_ref_seq.db_align_beg')
  alignTable$'_struct_ref_seq.db_align_end'=as.numeric(alignTable$'_struct_ref_seq.db_align_end')
  alignTable$'_struct_ref_seq.seq_align_beg'=as.numeric(alignTable$'_struct_ref_seq.seq_align_beg')
  alignTable$'_struct_ref_seq.seq_align_end'=as.numeric(alignTable$'_struct_ref_seq.seq_align_end')
  alignTable$'_struct_ref_seq.pdbx_auth_seq_align_beg'=as.numeric(alignTable$'_struct_ref_seq.pdbx_auth_seq_align_beg')
  alignTable$'_struct_ref_seq.pdbx_auth_seq_align_end'=as.numeric(alignTable$'_struct_ref_seq.pdbx_auth_seq_align_end')
  if (structures$Diff[r]=="?") {
    alignTable$diff=alignTable$'_struct_ref_seq.pdbx_auth_seq_align_beg'-alignTable$'_struct_ref_seq.db_align_beg'
  } else {
	alignTable$diff=as.numeric(structures$Diff[r])
  }
  aaFile=sprintf("%s.aa.txt",structures$Gene[r])
  residues=data.frame(read.table(aaFile,header=TRUE,stringsAsFactors=FALSE))
  residues=subset(residues,transcript==structures$Transcript[r])
  output="set display off; hide null; restrict not water; wireframe -0.16; spacefill 23%; select (ligand,ATP,ADP,AMP); color cpk; select *.FE; spacefill 0.7; color cpk ; select *.CU; spacefill 0.7; color cpk ; select *.ZN; spacefill 0.7; color cpk ; select all;\n"
  for (e in 1:nrow(residues))
  { 
    pos=residues$amino_acid_position[e]
	protein=structures$Uniprot[r]
    for (a in 1:nrow(alignTable))
    {
      if (protein != alignTable$'_struct_ref_seq.pdbx_db_accession'[a]) next
	  
	  newPos=pos+alignTable$diff[a]
	  if (pos<alignTable$'_struct_ref_seq.db_align_beg'[a] || pos>alignTable$'_struct_ref_seq.db_align_end'[a]) next
      if (residues$control[e]>0 && residues$case[e]>0) {
	    color="purple" } else if (residues$case[e]>0) {
		color="blue" } else {
		color="green"
		}
	  thisOne=sprintf("select %d:%s; color %s; select %d:%s.CA; label \"%s%d%s %d/%d\"; color label black\n",
	    newPos,alignTable$'_struct_ref_seq.pdbx_strand_id'[a],
		color,
		newPos,alignTable$'_struct_ref_seq.pdbx_strand_id'[a],
		substr(residues$amino_acid_change[e],1,1),residues$amino_acid_position[e],substr(residues$amino_acid_change[e],3,3),
		residues$control[e],residues$case[e])
	  output=paste(output,thisOne)
	}
  }
  output
  fn=sprintf("%s.%s.%s.spt",structures$Gene[r],structures$Transcript[r],structures$Structure[r])
  writeLines(output,fn)
}

