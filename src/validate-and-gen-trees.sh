#!/bin/sh

#
# First check to see if you need to create/update your yang repository of
# all IETF published YANG models.
#
if [ ! -d ../bin/yang-parameters ]; then
   rsync -avz --delete rsync.iana.org::assignments/yang-parameters ../bin/
fi

for i in ../bin/*\@$(date +%Y-%m-%d).yang
do
    name=$(echo $i | cut -f 1-3 -d '.')
    echo "Validating YANG module $name.yang"
    if test "${name#^example}" = "$name"; then
        response=`pyang --ietf --lint --strict --canonical -p ../bin -f tree --max-line-length=72 --tree-line-length=69 $name.yang > $name-tree.txt.tmp`
    else            
        response=`pyang --ietf --strict --canonical -p ../bin -f tree --max-line-length=72 --tree-line-length=69 $name.yang > $name-tree.txt.tmp`
    fi
    if [ $? -ne 0 ]; then
        printf "$name.yang failed pyang validation\n"
        printf "$response\n\n"
        echo
	rm yang/*-tree.txt.tmp
        exit 1
    fi
    fold -w 71 $name-tree.txt.tmp > $name-tree.txt
    response=`yanglint -p ../src/yang $name.yang -i`
    if [ $? -ne 0 ]; then
       printf "$name.yang failed yanglint validation\n"
       printf "$response\n\n"
       echo
       exit 1
   fi
   echo "$name.yang is VALID"
done
rm ../bin/*-tree.txt.tmp

for i in ../bin/ietf-bfd-stability\@$(date +%Y-%m-%d).yang
do
    name=$(echo $i | cut -f 1-3 -d '.')
    echo "Generating abridged tree diagram for $name.yang"
    if test "${name#^example}" = "$name"; then
       response=`pyang --lint --strict --canonical -p ../bin -f tree --tree-depth=7 --max-line-length=69 --tree-line-length=69 $name.yang > $name-sub-tree.txt.tmp`
    else            
       response=`pyang --ietf --strict --canonical -p ../bin -f tree --tree-depth=3 --max-line-length=69 --tree-line-length=69 $name.yang > $name-sub-tree.txt.tmp`
    fi
    if [ $? -ne 0 ]; then
        printf "$name.yang failed generation of sub-tree diagram\n"
        printf "$response\n\n"
        echo
	rm yang/*-sub-tree.txt.tmp
        exit 1
    fi
    fold -w 69 $name-sub-tree.txt.tmp > $name-sub-tree.txt
done
rm ../bin/*-sub-tree.txt.tmp

# Validate Stability BFD examples
for i in yang/example-bfd-stability-a.1.*.xml
do
    name=$(echo $i | cut -f 1-3 -d '.')
    echo "Validating $name.xml"
    response=`yanglint -ii -t config -p ../bin/yang-parameters -p ../bin ../bin/yang-parameters/ietf-key-chain@2017-06-15.yang ../bin/yang-parameters/iana-if-type@2023-01-26.yang ../bin/yang-parameters/ietf-bfd-ip-sh@2022-09-22.yang ../bin/yang-parameters/ietf-bfd@2022-09-22.yang ../bin/ietf-bfd-stability\@$(date +%Y-%m-%d).yang $name.xml`
    if [ $? -ne 0 ]; then
       printf "failed (error code: $?)\n"
       printf "$response\n\n"
       echo
       exit 1
    fi
done
