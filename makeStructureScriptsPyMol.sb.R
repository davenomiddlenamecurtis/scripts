outputFolder="/home/sbandyop/SCHEMA/results"
structureFile="/home/sbandyop/SCHEMA/results/structures.txt" 
amino_acids <- read.csv("/home/sbandyop/BP/PyMol_visualisation_trials/amino_acids.csv")
#with this change all single letter to three letter
outputFolder="/home/rejudcu/ADSP/genes"
structureFile="/home/rejudcu/ADSP/genes/structures.ADSP.txt"

mutatePyMol <-  '

python\nfrom __future__ import print_function\nfrom pymol import cmd\ndef mutate(molecule, chain, resi, target, mutframe="1"):\t\n\ttarget = target.upper()\n\tcmd.wizard("mutagenesis")\n\tcmd.do("refresh_wizard")\n\tcmd.get_wizard().set_mode("%s" % target)\n\tselection = "/%s//%s/%s" % (molecule, chain, resi)\n\tcmd.get_wizard().do_select(selection)\n\tcmd.frame(str(mutframe))\n\tcmd.get_wizard().apply()\n\tcmd.set_wizard("done")\n\t#cmd.set_wizard()\n\t#cmd.refresh()\ncmd.extend("mutate", mutate)\npython end 

'

change_to_three_letter <- function (string){
  index <- match(string, amino_acids$Single_letter)
  output <- as.character(amino_acids[index,2])
  return(output)
}

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
  maxHetsToUse <- 100
  output="set display off; hide null; restrict not water; wireframe -0.16; spacefill 23%; select (ligand,ATP,ADP,AMP); color cpk; select *.FE; spacefill 0.7; color cpk ; select *.CU; spacefill 0.7; color cpk ; select *.ZN; spacefill 0.7; color cpk ; select all;\n"
  pymol_output = sprintf("%s\ncmd.do('refresh_wizard')\nset cartoon_fancy_helices = 0\nset cartoon_highlight_color = grey70\nbg_colour white\nset antialias = 4\nset ortho = 1\nset sphere_mode, 5\nutil.performance(0)\nfetch %s, async = 0\ncolor skyblue, %s\nset label_size, -2\nset label_color, black\nset label_bg_color, orange\nhide nonbonded, all",mutatePyMol,structure, structure)
  for (e in 1:nrow(residues))
  { 
    pos=residues$amino_acid_position[e]
    protein=structures$Uniprot[r]
    for (a in 1:nrow(alignTable))
    {
      if (protein != alignTable$'_struct_ref_seq.pdbx_db_accession'[a]) next
      if((as.numeric(residues$control[e]) + as.numeric(residues$case[e])) > maxHetsToUse ) next 

     
      newPos=pos+alignTable$diff[a]
      if (pos<alignTable$'_struct_ref_seq.db_align_beg'[a] || pos>alignTable$'_struct_ref_seq.db_align_end'[a]) next
      if (residues$control[e]>0 && residues$case[e]>0) {
        color="orange" } else if (residues$case[e]>0) {  
          color="red" } else {
            color="yellow"
          }
      thisOne=sprintf("select %d:%s; color %s; select %d:%s.CA; label \"%s%d%s %d/%d\"; color label black\n",
                      newPos,alignTable$'_struct_ref_seq.pdbx_strand_id'[a],
                      color,
                      newPos,alignTable$'_struct_ref_seq.pdbx_strand_id'[a],
                      substr(residues$amino_acid_change[e],1,1),residues$amino_acid_position[e],substr(residues$amino_acid_change[e],3,3),
                      residues$control[e],residues$case[e])
      
      thisOne_pymol = sprintf("\nmutate %s, resi = %d, chain = %s, target = %s, mutframe =1\ncolor %s, resi %d and chain %s\nlabel resi %d and chain %s and name CB,\"%s%d%s %d/%d\" ",
                              structure,
                              newPos,
                              alignTable$'_struct_ref_seq.pdbx_strand_id'[a],
                              change_to_three_letter(substr(residues$amino_acid_change[e],3,3)),
                              color,
                              newPos,
                              alignTable$'_struct_ref_seq.pdbx_strand_id'[a],
                              newPos,
                              alignTable$'_struct_ref_seq.pdbx_strand_id'[a],
                              substr(residues$amino_acid_change[e],1,1),residues$amino_acid_position[e],substr(residues$amino_acid_change[e],3,3),
                              residues$control[e],residues$case[e]
      )
      
      output=paste(output,thisOne)
      pymol_output=paste(pymol_output, thisOne_pymol)
      #fn=sprintf("%s.%s.%s.%s%s%s.pml",structures$Gene[r],structures$Transcript[r],structures$Structure[r],substr(residues$amino_acid_change[e],1,1),residues$amino_acid_position[e],substr(residues$amino_acid_change[e],3,3))
      #writeLines(pymol_output,fn)
    }
    
  }
  output
  pymol_output
  wr = sprintf("%s.%s.%s.spt", structures$Gene[r],structures$Transcript[r],structures$Structure[r])
  fn=sprintf("%s.%s.%s.pml",structures$Gene[r],structures$Transcript[r],structures$Structure[r])
  writeLines(output,wr)
  writeLines(pymol_output,fn)
}


