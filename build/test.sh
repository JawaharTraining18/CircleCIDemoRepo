pwd
ls -la
chmod +rwx ./.scripts/protoci.sh
chmod +rwx ./.scripts/protoci-cfg.sh
ls -la
./.scripts/protoci.sh -r force-app/main/default/
sfdx force:mdapi:deploy -c --json -d .unpackaged/pre -u $SFDC_DEV06_ALIAS
#sfdx force:mdapi:deploy -c --json -d .unpackaged/retrieve/unpackaged
#sfdx force:source:deploy -c -p ../force-app/main/default -u $SFDC_DEV06_ALIAS
#sfdx force:mdapi:retrieve --json -k .unpackaged/pre/package.xml -r .unpackaged/retrieve
#sfdx force:apex:test:run --testlevel RunLocalTests --outputdir test-results --resultformat tap --targetusername $SFDC_DEV06_ALIAS