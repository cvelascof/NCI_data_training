#!/bin/bash
ulimit -s unlimited
source  /short/z00/jbw900/apps/pangeo/26092019/etc/profile.d/conda.sh 
conda activate pangeo

jobdir=$PBS_O_WORKDIR/.$PBS_JOBID
if [ -d $jobdir  ]; then
    rm -rf $jobdir
fi
mkdir $jobdir

if [ -e ${PBS_O_WORKDIR}/scheduler.json  ]; then
    rm  ${PBS_O_WORKDIR}/scheduler.json
fi

cd $jobdir
dsport=$(shuf -n 1 -i 8700-8800)
dask-scheduler --port ${dsport} --scheduler-file ${PBS_O_WORKDIR}/scheduler.json >& ${jobdir}/scheduler.log  &
sleep 15
for node in `cat $PBS_NODEFILE | uniq`
do
    index=-1
    for all_node in  `cat $PBS_NODEFILE`
    do
	((index= $index+1))
	if [ $node == $all_node ]
	then	    
	    pbsdsh bash -n $index  "/home/900/rxy900/short_fp0/apps/pangeo/2019.08.24/envs/pangeo/bin/pangeo.worker.sh"  &
	    break
	fi
    done
done
sleep 10

cd $PBS_O_WORKDIR

rm -rf client_cmd

sport=$(shuf -n 1 -i 8300-8400)
echo "ssh -N -L ${sport}:`hostname`:${sport} ${USER}@raijin.nci.org.au & " >& client_cmd
jupyter lab --no-browser --ip=`hostname` --port=${sport} & 
sleep 20

if [ -e ${PBS_O_WORKDIR}/scheduler.json  ]; then
    dport=`grep -i "dashboard" ${PBS_O_WORKDIR}/scheduler.json | awk '{print $2}'`
    echo "ssh -N -L ${dport}:`hostname`:${dport} ${USER}@raijin.nci.org.au &" >> client_cmd
fi

