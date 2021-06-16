#!/bin/bash

### CONFIGURACAO
# POOL DAS VMS
VM_POOL=DISCOS
# DIRETORIO BKP
BACKUP_DIR=/home/BKPs
# QUANTOS SNAPS DEVEM FICAR
SNAPSHOT_COUNT=3
# DATA = DIA/MES/ANO-HORA/MINUTO/SEGUNDO
TIMESTAMP=`date +%d%m%Y-%H%M%S`
# SELEÇÃO DO QUE SERA FEITO O BKP "executando" 
VM_LIST=`virsh list | grep NEW | awk '{print $2}'`
# LOG
LOGFILE="/var/log/kvmbackup.log"

# LOG
echo -e "\n**********\n`date`: INICIANDO BKP DAS VMs DO SERVIDOR BASE: /\n"
echo -e "\n**********\n`date`: INICIANDO BKP DAS VMs DO SERVIDOR BASE: `hostname`\n" >> $LOGFILE
echo -e "VM's EXECUTNADO:\n`virsh list | grep NEW | awk '{print "*",$2}'`"
echo -e "VM's EXECUTANDO:\n`virsh list | grep NEW | awk '{print "*",$2}'`" >> $LOGFILE

for ACTIVEVM in $VM_LIST
    do
        # CRIANDO PASTA BKP
        mkdir -p $BACKUP_DIR/$ACTIVEVM/bkp
		
		### CRIANDO SNAPSHOT
        #LOG
        echo "`date`: CRIANDO SNAP DA VM: $ACTIVEVM"
        echo "`date`: CRIANDO SNAP DA VM: $ACTIVEVM" >> $LOGFILE
        virsh snapshot-create-as --domain $ACTIVEVM --name snapshot-$TIMESTAMP
        sleep 2

		### APAGANDO SNAPS ANTIGOS
        # LOG
        echo "`date`: DELETEANDO SNAPS ANTIGOS: $ACTIVEVM"
        echo "`date`: DELETEANDO SNAPS ANTIGOS: $ACTIVEVM" >> $LOGFILE
        SNAPSHOT_ARR=(`virsh snapshot-list $ACTIVEVM | grep snapshot | awk '{print $1}'`)
            if (( ${#SNAPSHOT_ARR[*]} > $SNAPSHOT_COUNT ))
                then
                    virsh snapshot-delete $ACTIVEVM ${SNAPSHOT_ARR[0]}
                fi

        ### SNAPSHOT LIST
        # write log
        echo -e "LISTA DE SNAPS:\n`virsh snapshot-list $ACTIVEVM`"
        echo -e "LISTA DE SNAPS:\n`virsh snapshot-list $ACTIVEVM`" >> $LOGFILE

        ### VM CONFIGURACAO BACKUP
        #LOG
        echo -e "\n--- `date`: INICIANDO BKP: $ACTIVEVM\n"
        echo -e "\n--- `date`: INICIANDO BPK: $ACTIVEVM\n" >> $LOGFILE
        virsh dumpxml $ACTIVEVM > $BACKUP_DIR/$ACTIVEVM/bkp/$ACTIVEVM-$TIMESTAMP.xml

        ### PAUSANDO VM
        #LOG
		echo "`date`: PAUSANDO VM: $ACTIVEVM"
        echo "`date`: PAUSANDO VM: $ACTIVEVM" >> $LOGFILE
        virsh suspend --domain $ACTIVEVM
        sleep 2
		
		### FAZENDO BKP
		#LOG
		echo "`date`: FAZENDO BPK VM: $ACTIVEVM"
        echo "`date`: FAZENDO BKP: $ACTIVEVM" >> $LOGFILE
		echo "`date`: CAMINHO DO ARQUIVO A FAZER BKP: `virsh domblklist $ACTIVEVM | grep $VM_POOL | awk '{print $2}'`"
		echo "`date`: CAMINHO DO ARQUIVO A FAZER BKP: `virsh domblklist $ACTIVEVM | grep $VM_POOL | awk '{print $2}'`" >> $LOGFILE
		VM_DATA=(`virsh domblklist $ACTIVEVM | grep $VM_POOL | awk '{print $2}'`)
		cp $VM_DATA  $BACKUP_DIR/$ACTIVEVM/bkp/$ACTIVEVM-$TIMESTAMP-bkp.qcow2
		
		### INICIANDO VM
		#LOG
        echo "`date`: INCIANDO VM: $ACTIVEVM"
        echo "`date`: INCIANDO VM: $ACTIVEVM" >> $LOGFILE
        virsh resume --domain $ACTIVEVM
  
    done

#LOG
echo -e "\n`date`: FIM DOS BKP DO SERVIDOR BASE: `hostname`\n**********\n"
echo -e "\n`date`: FIM DOS BKP DO SERVIDOR BASE: `hostname`\n**********\n" >> $LOGFILE
