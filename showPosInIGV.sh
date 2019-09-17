#!/bin/bash
TMPDIR=/home/rejudcu/tmp
IMGDIR=/home/rejudcu/tmp

if [ -z "$bam" -o -z "$chr" -o -z "$pos" ]
then
	echo Need to set: bam chr pos
	exit
fi

ID=${bam##*/}

margin=30
start=$((pos-margin))
end=$((pos+margin))

batchFile=$TMPDIR/$chr.$pos.$ID.batch
xmlFile=$TMPDIR/$chr.$pos.$ID.xml
echo "new
load $bam
// load $xmlFile
snapshotDirectory $IMGDIR
goto $chr:${start}-${end}
sort position
// collapse
snapshot
" > $batchFile

echo '<?xml version="1.0" encoding="UTF-8" standalone="no"?>' > $xmlFile
echo '<Session genome="hg18" locus="'$chr:${start}-${end}'" version="4">' >> $xmlFile
echo '    <Resources>'>> $xmlFile
echo 'Resource path="'$bam'" relativePath="false"/>'>> $xmlFile
echo '    </Resources>
    <Panel height="2552" name="Panel1470822368833" width="1901">'  >> $xmlFile
echo '                <Track color="200,200,200" colorScale="ContinuousColorScale;0.0;271.0;255,255,255;200,200,200" displayMode="COLLAPSED" featureVisibilityWindow="-1" fontSize="10" id="'${bam}'_coverage" name="'$ID' Coverage" showDataRange="true" visible="true">'  >> $xmlFile
echo '                    <DataRange baseline="0.0" drawBaseline="true" flipAxis="false" maximum="271.0" minimum="0.0" type="LINEAR"/>
        </Track>'  >> $xmlFile
echo '        <Track color="0,0,178" colorOption="READ_STRAND" displayMode="EXPANDED" featureVisibilityWindow="-1" fontSize="10" id="'$bam'" name="'$ID'" showAllBases="true" showDataRange="true" visible="true"/>' >> $xmlFile
echo '    </Panel>
    <Panel height="70" name="FeaturePanel" width="1901">
        <Track color="0,0,178" displayMode="COLLAPSED" featureVisibilityWindow="-1" fontSize="10" id="Reference sequence" name="Reference sequence" showDataRange="true" sortable="false" visible="true"/>
        <Track color="0,0,178" colorScale="ContinuousColorScale;0.0;241.49261474609375;255,255,255;0,0,178" displayMode="COLLAPSED" featureVisibilityWindow="-1" fontSize="10" height="35" id="hg18_genes" name="RefSeq genes" renderer="BASIC_FEATURE" showDataRange="true" sortable="false" visible="true" windowFunction="count">
            <DataRange baseline="0.0" drawBaseline="true" flipAxis="false" maximum="241.49261" minimum="0.0" type="LINEAR"/>
        </Track>
    </Panel>
    <PanelLayout dividerFractions="0.007585335018963337,0.9051833122629582"/>
</Session>
' >> $xmlFile