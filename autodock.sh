#! /bin/bash
export ligands="~/ligands"
export mglbin="~/MGLTools-1.5.6/bin"
export script="~/MGLTools-1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24"

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
xyz=$(eBoxSize.pl ref-lig.mol2|tail -n1|sed "s/ /,/g") 
box=$(eBoxSize.pl ref-lig.mol2|head -n1|awk '{ print ($1/3.75)*10 }') #Grid spacing, you can chance it.

#Preparinge receptor
$mglbin/pythonsh $script/prepare_receptor4.py -r receptor.pdb -o receptor.pdbqt

wd=`pwd` #Defining working directory
mkdir results
for i in `cat list`;do
mkdir $wd/$i && cd $wd/$i &&
cp ../receptor.pdbqt . &&
$mglbin/pythonsh $script/prepare_ligand4.py -l ../ligands/${i}.mol2 -o ligand.pdbqt &&
$mglbin/pythonsh $script/prepare_gpf4.py -l ligand.pdbqt -r receptor.pdbqt -p npts="$box,$box,$box" -p gridcenter="$xyz" -o complex.gpf &&
$mglbin/pythonsh $script/prepare_dpf4.py -l ligand.pdbqt -r receptor.pdbqt -o complex.dpf &&
autogrid4 -p complex.gpf -l $i.glg &&
autodock4 -p complex.dpf -l $i.dlg && 
cd $wd && cp $i/$i.dlg ../results/ && 
rm -r $wd/$i &
nrwait $NR_CPUS
done
wait
