#!/bin/bash
### Script Name: /path/file.sh
### Author: Paul Carmuciano 2018-12-06

### Description: xxx
# Functioning prototype of linux CI/CD script that generates deployable artifacts 
# for sfdx force:mdapi:deploy from GIT changes.
#
# The GIT_COMMIT_SEED is derived from a static point (firstKnownGoodCommit) though 
# could be dynamic based on CI tool storing artifact on last known successful build.
#
# Logic is linear, so could implement functions especially now we pre/post deploy
# different metadata types, essentially running some logic twice.
#


## default params
echo "file name1: $file"
deploymentPhase="pre"
#firstKnownGoodCommit=4fdec4746b42820116ff7d8810e365b570e966af
firstKnownGoodCommit=b0784adaa4bbee28804364828b593545b2133656

## get params
while [[ "$#" -gt 0 ]]
  do
    case $1 in
        -r|--relativepath)
        PATH_REL="$2"
    ;;
        -g|--gitcommitseed)
        GIT_COMMIT_SEED="$2"
    ;;
        -d|--deploymentphase)
        deploymentPhase="$2"
    ;;
    esac    
  shift
done
echo "file name2: $file"
############################################################
# includes
############################################################
#. $PATH_REL'.scripts/protoci-cfg.sh'
. '.scripts/protoci-cfg.sh'

############################################################
# Array Functions - thanks someone
############################################################
echo "file name3: $file"
# Dynamically create an array by name

function arr() {
    [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable1" 1>&2 ; return 1 ; }
    declare -g -a $1=\(\)   
}

# Insert incrementing by incrementing index eg. array+=(data)
function arr_insert() { 
    [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable2" 1>&2 ; return 1 ; }
    declare -p "$1" > /dev/null 2>&1
    [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
    declare -n r=$1
    r[${#r[@]}]="$2"
}
# Insert incrementing by incrementing index eg. array+=(data)
function arr_check() { 
    [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable3 " 1>&2 ; return 1 ; r=0; }
    declare -p "$1" > /dev/null 2>&1
    [[ $? -eq 1 ]] && { return 1 ; r=0; }
    declare -n r=$1
}
# Get the array content ${array[@]}
function arr_get() {
    [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable4" 1>&2 ; return 1 ; }
    declare -p "$1" > /dev/null 2>&1
    [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
    declare -n r=$1 
    echo ${r[@]}
}


############################################################
# Get Diff
############################################################
# Currently using a seed commit, but should move to build 
# artefacts, last_known_successful_deploy
echo "file name4: $file"

if [ "$GIT_COMMIT_SEED" != "" ] ; then
    gitDiffCommitSeed=$GIT_COMMIT_SEED
else

    # set a seed var
    gitDiffCommitSeed=

    # get from cache for this branch (circleci specific)
    echo "Looking for previous commit via cache ..."
    if [ -d .build ]; then
        # get sha1 out of cache
        [ -d .build ] && previousBuildSuccessSHA1=$(<.build/build-status/build-success-SHA1)
        gitDiffCommitSeed=$previousBuildSuccessSHA1
        # now look for commit seed, by finding 1 after previousBuildSuccessSHA1, 
        # or count back from HEAD
        # or use first parent
        #echo "Looking for commit seed ..."
        #echo
        #for sha1 in $(git log --format=format:%H); do
        #    if [[ $sha1 != $previousBuildSuccessSHA1 ]]; then
        #        gitDiffCommitSeed=$sha1
        #    else
        #        gitDiffCommitSeed=$sha1
        #        echo "Found $gitDiffCommitSeed as 1 after sha1 $sha1 ..."
        #        echo
        #        break
        #    fi
        #done
    else
        echo "Directory .build not found, no cached result"
        gitDiffCommitSeed=$firstKnownGoodCommit
    fi
fi
echo "Using gitDiffCommitSeed: $gitDiffCommitSeed"

echo "file name5: $file"


############################################################
# Organise Metadata & Copy Files
############################################################
#echo "the diff"

declare -a metaTypesInited;
DEPLOY_DIRECTORY=".unpackaged/$deploymentPhase"

# make destination
mkdir -p $DEPLOY_DIRECTORY
echo "file name6: $file"

# organise meta items
#while IFS= read -r -d '' file; do
while IFS= read  '' file; do
    echo "file name7: $file"
    pathPrefix=${file%/*}
    echo "pathPrefix: $pathPrefix"
    METAFOLDER=${pathPrefix##*/}
    echo "METAFOLDER: $METAFOLDER"
    tempFile3=${file##*/}
    echo "tempFile3: $tempFile3"
    #echo "tempFile2 " $tempFile2
    #echo "tempFile3 " $tempFile3
    file=$METAFOLDER'/'$tempFile3
    echo "file: $file"



    META_ITEM="$file" #${metaItems[i]}
    META_TYPE=${META_ITEM%%\/*} # eg reports/
    META_TYPE=$METAFOLDER
    META_FILENAME=${META_ITEM#*\/}
    META_NAME=${META_FILENAME%*.*}
    #META_NAME=${META_ITEM}

    # Ignore -meta.xml
    if ([[ $deploymentPhase == "pre" ]] \
        && [[ $META_ITEM != *"-meta.xml"* ]] \
        && [[ $META_ITEM != "."* ]] \
        && [[ $META_ITEM != "assets/"* ]] \
        && [[ $META_ITEM != "connectedApps/"* ]] \
        && [[ $META_ITEM != "networks/"* ]] \
        && [[ $META_ITEM != "siteDotComSites/"* ]] \
        && [[ $META_ITEM != "flows/"* ]] \
        && [[ $META_ITEM != "flowDefinitions/"* ]] \
        && [[ $META_ITEM != *"package.xml"* ]] \
        && [[ $META_ITEM != *".DS_Store"* ]] \
        && [[ $META_ITEM == *"/"* ]] \
    ) ||([[ $META_ITEM == *".app-meta.xml"* ]] \
    ) ||([[ $deploymentPhase == "post" ]] \
        && [[ $META_ITEM == "flows/"* ]] \
    ); then
        
        #If Processing a Custom Application, make sure we remove the ".app-meta" substring from the Meta name
        if [[ $META_ITEM == *".app-meta.xml"* ]]; then 
            #META_NAME=echo $META_NAME | cut -d'.' -f 1
            META_NAME=$(echo $META_NAME | cut -d'.' -f 1) 
            echo "NEW META_NAME" $META_NAME
        fi
        
        # First check if metaItemsOfType_META_TYPE requires declaration
        # declare dyn array
        arr_check "metaItemsOfType_$META_TYPE"
        checkResult=$?
        if [[ $checkResult == 1 ]]; then 
            echo 'checkResult' $checkResult 'means' $META_TYPE 'is unset. declaring type () '
            arr "metaItemsOfType_$META_TYPE"
            arr "metaMembersOfType_$META_TYPE"
            metaTypesInited+=("$META_TYPE")

            echo "Create folder "$DEPLOY_DIRECTORY/$META_TYPE
            # mkdir, na for nested
            mkdir -p "$DEPLOY_DIRECTORY/$META_TYPE"
        fi

        # set the nested indicator / handled nested folders & -meta.xmls
        nested=false
        nestedFolder=
        nestedType=
        if [[ $META_NAME != *"/"* ]]; then
            nested=true
            #nestedFolder=${META_NAME%\/*}
            #nestedFolder=$METAFOLDER
            # create the folder
            mkdir -p "$DEPLOY_DIRECTORY/$META_TYPE/$nestedFolder"
            # copy the folder meta
            if [[ -f "$META_TYPE/$nestedFolder-meta.xml" ]]; then
                # copy the -meta file for the folder
                cp "$META_TYPE/$nestedFolder-meta.xml" "$DEPLOY_DIRECTORY" --parents
                
                # check if we have a meta <member> for this folder
                nestedMember="<members>$nestedFolder</members>"
                nestedFolderMemberItems=$(arr_get metaMembersOfType_$META_TYPE)
                if ! grep -q "<members>$nestedFolder</members>" <<< "${nestedFolderMemberItems[@]}" ; then
                    #arr_insert "metaItemsOfType_$META_TYPE" "$nestedFolder"
                    echo "arr_insert1"
                    arr_insert "metaMembersOfType_$META_TYPE" "\t\t$nestedMember\r\n"
                fi                
            fi
        fi

        # inform
        echo "META_ITEM     $META_ITEM"
        echo "META_TYPE     $META_TYPE"
        echo "META_FILENAME $META_FILENAME"
        echo "META_NAME     $META_NAME"
        echo "nested/folder $nested $nestedFolder"
        echo        

        # use dyn array
        #arr_insert "metaItemsOfType_$META_TYPE" "${META_ITEM}"
        echo "arr_insert2"
        if [[ -z "$META_NAME" ]]; then
            echo "NULL"
        else
            arr_insert "metaMembersOfType_$META_TYPE" "\t\t<members>$META_NAME</members>\r\n"
        fi

        # copy src and meta, considering target folder from nested / not nested
        targetFolder="$META_TYPE"
        if ( [[ nested ]] ); then
            targetFolder="$META_TYPE/$nestedFolder"
        fi
        cp -p "$PATH_REL$META_ITEM" "$DEPLOY_DIRECTORY/$targetFolder/"
        if [[ $META_TYPE != "profiles"* ]];then
            if [[ -f "$PATH_REL$META_ITEM-meta.xml" ]]; then
                cp -p "$PATH_REL$META_ITEM-meta.xml" "$DEPLOY_DIRECTORY/$targetFolder/"
            fi
        fi
        echo
    fi
done < <(git diff -z --name-only --diff-filter=MAR $gitDiffCommitSeed...HEAD ./force-app/main/default/)

############################################################
# If org cannot deploy flows as active (no test coverage)
############################################################
# use a flow (meta item) that we know always succeeds
persistentFlowMetaItem="flows/zCiCdPeristentSuccess.flow"
# could also check the persistent item is not in scope already
if ([[ $deploymentPhase == "post" ]]); then
    # try create directly, may already exist
    if [ ! -d "$DEPLOY_DIRECTORY/flows" ]; then
        mkdir -p "$DEPLOY_DIRECTORY/flows"
    fi
    if [[ ! -f "$DEPLOY_DIRECTORY/$persistentFlow" ]]; then
        arr_check "metaItemsOfType_flows"
        checkResult=$?
        if [[ $checkResult == 1 ]]; then 
            arr "metaItemsOfType_flows"
            arr "metaMembersOfType_flows"
            metaTypesInited+=("flows")
        fi
        # use dyn array
        arr_insert "metaItemsOfType_flows" "$persistentFlowMetaItem"
        META_FILENAME=${persistentFlowMetaItem#*\/}
        META_NAME=${META_FILENAME%*.*}
        arr_insert "metaMembersOfType_flows" "\t\t<members>$META_NAME</members>\r\n"
        cp -p "$persistentFlowMetaItem" "$DEPLOY_DIRECTORY/flows/"
    fi
fi

############################################################
# Generate Manifest
############################################################

SF_MDAPI_VERSION='50.0'
PACKAGE_XML_STREAM=

# iterate in-context metadata types
for key in "${!metaTypesInited[@]}"; 
do 
    # init the <type>
    PACKAGE_XML_STREAM+='\t<types>\r\n'

    echo "metaTypesInitedkey "${metaTypesInited[$key]}
    # add meta items
    metaItems=$(arr_get metaMembersOfType_${metaTypesInited[$key]})
    #echo "metaItems $metaItems"
    PACKAGE_XML_STREAM+=$metaItems

    # consider the type <name>
    # get the type to translate to MDAPI TYPE
    META_TYPE="${metaTypesInited[$key]}"
    echo "META_TYPE " $META_TYPE
    SF_METADATA_TYPE="mdf_localTypeToType_$META_TYPE"
    PACKAGE_XML_STREAM+='\t\t<name>'${!SF_METADATA_TYPE}'</name>\r\n'

    # close out type
    PACKAGE_XML_STREAM+='\t</types>\r\n'

done;

# only produce a file when items exist
if [[ $PACKAGE_XML_STREAM != "" ]]; then

    PACKAGE_XML='<?xml version="1.0" encoding="UTF-8"?>\r\n'
    PACKAGE_XML+='<Package xmlns="http://soap.sforce.com/2006/04/metadata">\r\n'
    PACKAGE_XML+=$PACKAGE_XML_STREAM
    PACKAGE_XML+='\t<version>'$SF_MDAPI_VERSION'</version>\r\n'
    PACKAGE_XML+='</Package>'
    echo -e $PACKAGE_XML
    echo -e $PACKAGE_XML > "$DEPLOY_DIRECTORY/package.xml"

fi

#echo
#read -rsp $'Done, press enter to continue...\n'
