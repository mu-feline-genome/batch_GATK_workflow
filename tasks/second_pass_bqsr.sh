#!/bin/bash
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
--sample )
shift; SM=$1
;;
--gatk )
shift; GATK=$1
;;
--java )
shift; JAVAMOD=$1
;;
--rversion )
shift; RMOD=$1
;;
--ref )
shift; REF=$1
;;
--threads )
shift; THREADS=$1
;;
--recal )
shift; RECAL=$1
;;
--perform )
shift; PERFORM=$1
;;
--workdir )
shift; CWD=$1
;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

module load $JAVAMOD
module load $RMOD

if [[ $PERFORM = true ]]; then
    echo -e "$(date): second_pass_bqsr.sh is running on $(hostname)" &>>  $CWD/$SM/metrics/perform_second_pass_bqsr_$SM.txt
    vmstat -twn -S m 1 >> $CWD/$SM/metrics/perform_second_pass_bqsr_$SM.txt &
fi

echo -e "$(date)\tbegin\tsecond_pass_bqsr.sh\t$SM\t" &>> $CWD/$SM/log/$SM.run.log

java -Djava.io.tmpdir=$CWD/$SM/tmp -jar $GATK \
-nct $THREADS \
-T BaseRecalibrator \
-R $REF \
-I $CWD/$SM/tmp/$SM.bams.list \
-knownSites $RECAL \
-o $CWD/$SM/metrics/$SM.post_recal_data.table \
-BQSR $CWD/$SM/metrics/$SM.recal_data.table

if [[ -s $CWD/$SM/metrics/$SM.post_recal_data.table ]]; then
    echo -e "$(date)\tend\tsecond_pass_bqsr.sh\t$SM\t" &>> $CWD/$SM/log/$SM.run.log
else
    echo -e "$(date)\tfail\tsecond_pass_bqsr.sh\t$SM\t" &>> $CWD/$SM/log/$SM.run.log
    scancel -n $SM
fi

echo -e "$(date)\tbegin\tsecond_pass_bqsr.sh-analyze\t$SM\t" &>> $CWD/$SM/log/$SM.run.log

java -Djava.io.tmpdir=$CWD/$SM/tmp -jar $GATK \
-T AnalyzeCovariates \
-R $REF \
-before $CWD/$SM/metrics/$SM.recal_data.table \
-after $CWD/$SM/metrics/$SM.post_recal_data.table \
-plots $CWD/$SM/metrics/$SM.recalibration_plots.pdf

if [[ -s $CWD/$SM/metrics/$SM.recalibration_plots.pdf ]]; then
    echo -e "$(date)\tend\tsecond_pass_bqsr.sh-analyze\t$SM\t" &>> $CWD/$SM/log/$SM.run.log
else
    echo -e "$(date)\tfail\tsecond_pass_bqsr.sh-analyze\t$SM\t" &>> $CWD/$SM/log/$SM.run.log
    scancel -n $SM
fi
