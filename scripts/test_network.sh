#!/bin/bash

#Defaults
acc_Req=5
acc_Made=0
acc_Def_Name="miner"
PRIVATE_KEY=34EpMEDFJwKbxaF7FhhLyEe3AhpM4dwHMLVfs4JyRto5

#Array Declaration
acc_Name=()
acc_Pub=()
acc_Priv=()

#Parse flags
while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "options:"
                        echo "-h, --help                Show this message"
                        echo "-a,      specify the number of accounts to make"
                        echo "-n,      name of the accounts"
                        exit 0
                        ;;
                -a)
                        shift
                        if test $# -gt 0; then
                                export acc_Req=$1
                        else
                                echo "No accounts requested"
                                exit 1
                        fi
                        shift
                        ;;
                -n)
                        shift
                        if test $# -gt 0; then
                                export acc_Def_Name=$1
                        else
                                echo "No accounts requested"
                                exit 1
                        fi
                        shift
                        ;;
        esac
done


while [ $acc_Made != $acc_Req ]
do
  #We need to do this to make JQ happy
  cmd=$(node ./src/cli.js keypair|sed s/\ pub:/\"pub\":/g|sed s/priv:/\"priv\":/g|sed s/' }'/'}'/g|tr -d '\n'|tr -d ' '|sed s/\'/\"/g)


  acc_Made=$(($acc_Made+1))
  acc_Pub+=($(echo $cmd|jq -r .pub))
  acc_Priv+=($(echo $cmd|jq -r .priv))
  acc_Name+=($(echo $acc_Def_Name$acc_Made))
done
echo ${acc_Name[@]}

# create accounts
name=0
for key in "${acc_Pub[@]}"
do node src/cli.js createAccount $PRIVATE_KEY master $key ${acc_Name[name]}
name=$name+1
done


sleep 5

# send some tokens
for name in "${acc_Name[@]}"
do node src/cli.js transfer $PRIVATE_KEY master $name 10000
done

sleep 10

# display nodes ip and port in profile
node src/cli.js profile $PRIVATE_KEY master '{"node":{"ws":"ws://127.0.0.1:6001"}}'
name=0
for key in "${acc_Priv[@]}"
do port=$name+6001
node src/cli.js profile $key ${acc_Name[name]} '{"node":{"ws":"ws://127.0.0.1:'$port'"}}'
name=$name+1
done
# everyone votes for itself
name=0
for key in "${acc_Priv[@]}"
do node src/cli.js approveNode $key ${acc_Name[name]} ${acc_Name[name]}
done
