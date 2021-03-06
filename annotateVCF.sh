#!/bin/bash
set -x

root=$1
if [ -z "$mult" ]
then
  mult=yes
# annotations for multiple transcripts
fi
if [ "$X" == "no" ]
then
 allChrs="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22"
else
 allChrs="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X"
fi

# VEP=/share/ref/VEP/ensembl-tools-release-87/scripts/variant_effect_predictor/variant_effect_predictor.pl
# bcftools=/share/apps/genomics/bcftools-1.3.1/bin/bcftools needs vcf.gz's to be indexed
VCFCONCAT=/home/rejudcu/bin/vcf-concat

if [ -z "$root" ]
then
  echo Usage: $0 vcfRoot [ target is vcfRoot.vcf.gz, can also first export mult=no for only one transcript and X=no if no X chromosome data ]
  exit
fi

if [ ! -e $root.vars.vcf.gz.tbi ]
then
  if [ ! -e $root.vars.vcf.gz.tbi.lock ]
  then
    echo locked > $root.vars.vcf.gz.tbi.lock
	if [ ! -e $root.vars.vcf ] # I may have copied this from elsewhere
	then
      zcat $root.vcf.gz | cut -f1-9 > $root.vars.vcf
	fi 
    bgzip $root.vars.vcf
    tabix -p vcf $root.vars.vcf.gz
	rm $root.vars.vcf.gz.tbi.lock # may be multiple scripts running in parallel
  else
    while [ -e $root.vars.vcf.gz.tbi.lock ]
	do 
	  sleep 10m
	done
  fi
fi

PICK=
MULT=.mult

if [ "$mult" == no ]
then
  PICK=--pick
  MULT=
fi

if [ "$chr" == "" ]
then
  chrs=$allChrs
else
  chrs=$chr
fi

for c in $chrs
do
chrfile=$root$MULT.annot.$c.vcf
if [ ! -e $chrfile.done ]
then
# tabix $root.vars.vcf.gz $c:0-400000000 | perl $VEP \
#	--cache --dir /share/ref/VEP/Cache --merged --offline \
#	--format vcf --output_file $chrfile --vcf --force_overwrite \
#	--sift b --polyphen b $PICK
tabix $root.vars.vcf.gz $c:0-400000000 | perl /cluster/project9/bipolargenomes/vep/ensembl-vep/vep \
	--cache --dir /cluster/project9/bipolargenomes/vep/Cache97 --merged --port 3337 --force_overwrite \
	--sift b --polyphen b --offline --assembly GRCh37 --format vcf \
	--fasta /cluster/project9/bipolargenomes/vep/Cache97/homo_sapiens/97_GRCh37 \
	--vcf --output_file $chrfile $PICK
bgzip $chrfile
echo done > $chrfile.done
fi
done

vcfs=
allDone=yes
for c in $allChrs
do
chrfile=$root$MULT.annot.$c.vcf
vcfs="$vcfs $chrfile.gz"
if [ ! -e $chrfile.done ]
then
  allDone=no
fi
done

if [ $allDone == no ]
then
  exit
fi

# $bcftools concat -o $root$MULT.annot.vcf $vcfs
$VCFCONCAT $vcfs > $root$MULT.annot.vcf
rm $root$MULT.annot.vcf.gz # just in case
bgzip $root$MULT.annot.vcf
tabix -f -p vcf $root$MULT.annot.vcf.gz

	