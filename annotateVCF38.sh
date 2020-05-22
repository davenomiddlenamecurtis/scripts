#!/bin/bash
set -x
use23=yes

root=$1
if [ -z "$mult" ]
then
  mult=yes
# annotations for multiple transcripts
fi
if [ "$useX" == "yes" ]
then
 allChrs="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X"
else
if [ "$use23" == "yes" ]
then
 allChrs="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23"
else
 allChrs="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22"
fi
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

# export PERL5LIB=/usr/lib/perl64:$PERL5LIB
OLDPERL5LIB=$PERL5LIB
export PERL5LIB=/usr/lib/perl64
for c in $chrs
do
chrfile=$root$MULT.annot.$c.vcf
if [ ! -e $chrfile.done ]
then
# tabix $root.vars.vcf.gz $c:0-400000000 | perl $VEP \
#	--cache --dir /share/ref/VEP/Cache --merged --offline \
#	--format vcf --output_file $chrfile --vcf --force_overwrite \
#	--sift b --polyphen b $PICK
tabix $root.vars.vcf.gz $c:0-400000000 | perl /share/apps/ensembl-vep-97/vep \
    --synonyms ~/vep/chr_synonyms.txt \
	--cache --dir /cluster/project9/bipolargenomes/vepcache --merged --port 3337 --force_overwrite \
	--sift b --polyphen b --offline --assembly GRCh38 --format vcf \
	--fasta /cluster/project9/bipolargenomes/vepcache/homo_sapiens_merged/97_GRCh38 \
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
PERL5LIB=/usr/lib/perl64:/share/apps/genomics/vcftools-0.1.13/lib/perl5/site_perl/
VCFCONCAT=/share/apps/genomics/vcftools-0.1.13/bin/vcf-concat
$VCFCONCAT $vcfs > $root$MULT.annot.vcf
rm $root$MULT.annot.vcf.gz # just in case
bgzip $root$MULT.annot.vcf
tabix -f -p vcf $root$MULT.annot.vcf.gz
