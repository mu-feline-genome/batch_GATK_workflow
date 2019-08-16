#!/bash/bin
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
--sample )
shift; SM=$1
;;
--bam )
shift; BAM=$1
;;
--log )
shift; LOG=$1
;;
--metrics )
shift; METRICS=$1
;;
--gvcf )
shift; GVCF=$1
;;
--workdir )
shift; CWD=$1
;;
--bqsr )
shift; BQSR=$1
;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi


if [[ BQSR = true ]]; then
    inStatus=recal
elif [[ BQSR = false ]]; then
    inStatus=realign
fi


echo -e "$(date)\t$SM moving final files and performing md5sum checks, updating permissions\n" &>> $CWD/$SM/log/$SM.run.log

# bams 
echo $(md5sum $CWD/$SM/bam/$SM.$inStatus.bam | cut -f1 -d' ') $SM.bam > $BAM/$SM.bam.md5 &
echo $(md5sum $CWD/$SM/bam/$SM.unmap.bam | cut -f1 -d' ') $SM.unmap.bam > $BAM/$SM.unmap.bam.md5 &
echo $(md5sum $CWD/$SM/bam/$SM.halfmap.bam | cut -f1 -d' ') $SM.halfmap.bam > $BAM/$SM.halfmap.bam.md5 &

cp $CWD/$SM/bam/$SM.$inStatus.bam $BAM/$SM.bam* &
cp $CWD/$SM/bam/$SM.unmap.bam $BAM/$SM.unmap.bam &
cp $CWD/$SM/bam/$SM.halfmap.bam $BAM/$SM.halfmap.bam &

# gvcf
echo $(md5sum $CWD/$SM/gvcf/$SM.g.vcf.gz | cut -f1 -d' ') $SM.g.vcf.gz > $GVCF/$SM.g.vcf.gz.md5 &

cp $CWD/$SM/gvcf/$SM.g.vcf.gz $GVCF/$SM.g.vcf.gz &

wait

# set up full path md5sums for final check
touch $CWD/$SM/log/$SM.final.check.txt

echo (cut -f1 -d' ' $BAM/$SM.bam.md5) $BAM/$SM.bam &>> $CWD/tmp/$SM.final.bam.md5
md5sum -c $CWD/tmp/$SM.final.bam.md5 &>> $CWD/$SM/log/$SM.final.check.txt &

echo (cut -f1 -d' ' $BAM/$SM.unmap.bam.md5) $BAM/$SM.unmap.bam &>> $CWD/tmp/$SM.final.unmap.md5
md5sum -c $CWD/tmp/$SM.final.unmap.md5 &>> $CWD/$SM/log/$SM.final.check.txt &

echo (cut -f1 -d' ' $BAM/$SM.halfmap.bam.md5) $BAM/$SM.halfmap.bam &>> $CWD/tmp/$SM.final.halfmap.md5
md5sum -c $CWD/tmp/$SM.final.halfmap.md5 &>> $CWD/$SM/log/$SM.final.check.txt &

echo (cut -f1 -d' ' $GVCF/$SM.g.vcf.gz.md5) $GVCF/$SM.g.vcf.gz &>> $CWD/tmp/$SM.final.gvcf.md5
md5sum -c $CWD/tmp/$SM.final.gvcf.md5 &>> $CWD/$SM/log/$SM.final.check.txt &

wait

# make sure all checks passed
if [[ $(grep "OK" $CWD/$SM/log/$SM.final.check.txt | wc -l) = 4 ]]; then
	echo -e "$(date)\t $SM cp passed checks, updating permissions\n" &>> $CWD/$SM/log/$SM.run.log
	chmod ugo-w $BAM/$SM.* $GVCF/$SM.*
else
	echo -e "$(date)\t $SM cp did not pass checks, removing files from final path, exiting\n" &>> $CWD/$SM/log/$SM.run.log
	rm $BAM/$SM.* $GVCF/$SM.*
	scancel $SM
	sleep 5m
fi


cp -r $CWD/$SM/log $LOG/$SM &
cp -r $CWD/$SM/metrics $METRICS/$SM &

wait

chmod -R ugo-w $LOG/$SM $METRICS/$SM








