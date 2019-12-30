#! /bin/bash
export ligands="~/ligands"
export mglbin="~/MGLTools-1.5.6/bin"
export script="~/MGLTools-1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24"
home=`pwd` 	#Working directory

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

#Getting binding center and box size using eBoxSize.pl
x=$(perl $home/eBoxSize.pl $home/ref-lig.mol2|tail -n1|awk '{print $1}') 
y=$(perl $home/eBoxSize.pl $home/ref-lig.mol2|tail -n1|awk '{print $2}') 
z=$(perl $home/eBoxSize.pl $home/ref-lig.mol2|tail -n1|awk '{print $3}') 
box=$(perl $home/eBoxSize.pl $home/ref-lig.mol2|head -n1) 

#Preparing receptor
$mglbin/pythonsh $script/prepare_receptor4.py -r receptor.pdb -o receptor.pdbqt

#Virtual screening
for i in `cat $home/list`;do
mkdir $home/$i && cd $home/$i &&
cp $home/receptor.pdbqt . &&
$mglbin/pythonsh $script/prepare_ligand4.py -l $home/ligands/${i}.mol2 -o ligand.pdbqt &&
vina --receptor receptor.pdbqt --ligand ligand.pdbqt \
--center_x $x --center_y $y --center_z $z \
--size_x $box --size_y $box --size_z $box --out ligand_out.pdbqt --cpu 1 &&
score=`grep "VINA RESULT" ligand_out.pdbqt |head -n1|awk '{print $4}'` &&
echo "$i $score" >> $home/AutoDockVina-results.dat && cd $home &&
rm -r $i &
nrwait $NR_CPUS
done
wait
