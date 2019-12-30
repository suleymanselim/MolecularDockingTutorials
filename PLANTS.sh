#! /bin/bash
home=`pwd`				#Working directory
export ligands="$home/ligands"		#Directory for ligands

function nrwait() {
	local nrwait_my_arg
	if [[ -z $1 ]] ; then
	nrwait_my_arg=2
	else
	nrwait_my_arg=$1
	fi
    
	while [[ $(jobs -p | wc -l) -ge $nrwait_my_arg ]] ; do
	sleep 0.33;
	done
}
NR_CPUS=8		#Number of CPU

#All settings are used as default options.

#Getting binding center and box radius using eBoxSize.pl with the reference ligand in the binding pocket.
xyz=$(perl $home/eBoxSize.pl $home/ref-lig.mol2|tail -n1) 
rad=$(perl $home/eBoxSize.pl $home/ref-lig.mol2|head -n1|awk '{ print $1/2 }') 

#config file
cat <<EOF > config
protein_file receptor.mol2
ligand_file ligand.mol2
bindingsite_center $box
bindingsite_radius $rad
EOF

#Preparing receptor
SPORES --mode complete receptor.pdb receptor.mol2

#Virtual screening
for i in `cat list`; do  
mkdir $home/${i} && cd $home/${i} &&
cp $home/config config &&
cp $home/receptor.mol2 . &&
SPORES --mode complete $home/ligands/${i}.mol2 ligand.mol2 &&
PLANTS --mode screen config && score=`awk -F, '{print $2}' bestranking.csv |tail -n1` &&
echo "$i $score" >> $home/PLANTS-results.dat && cd $home && rm -r $i &
nrwait $NR_CPUS
done 
wait

