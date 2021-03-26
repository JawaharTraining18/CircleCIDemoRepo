SFDC_DEV06_CLIENTID="3MVG9aWdXtdHRrI0sEVZM..iq94vUk8e51zeqPdxesePKneBPn.y049pCJh7NHm0u0VU6vfgoonQWH0do1AYz"
SFDC_DEV06_USER=$(echo "deepak.andeli@servicemax.com.hts.dev06")
chmod +rwx ./.scripts/protoci.sh
chmod +rwx ./.scripts/protoci-cfg.sh
./.scripts/protoci.sh -r force-app/main/default/
#ls -la
#sfdx force:org:list
#export SFDX_AUDIENCE_URL=https://test.salesforce.com
#sfdx force:auth:jwt:grant --clientid $SFDC_DEV06_CLIENTID --jwtkeyfile ./keys/server.key --username $SFDC_DEV06_USER --setdefaultdevhubusername --setalias $SFDC_DEV06_ALIAS --instanceurl  https://horiba-apac--dev06.my.salesforce.com/
#sfdx force:org:list
sudo chmod -R a+rwx .unpackaged
sfdx force:mdapi:deploy -c --json -d .unpackaged/pre -u $SFDC_DEV06_USER -w 5 -l RunSpecifiedTests -r "SMAX_PS_SetFieldsOnWOWebServ_UT" --apiversion 50.0
#sfdx force:mdapi:deploy -c --json -d .unpackaged/pre -u $SFDC_DEV06_ALIAS -w 5 -l RunSpecifiedTests -r "SMAX_PS_SetFieldsOnWOWebServ_UT" --apiversion 50.0
#sfdx force:mdapi:deploy -c --json -d .unpackaged/pre -u $SFDC_DEV06_ALIAS -l RunAllTestsInOrg
#sfdx force:mdapi:deploy -c --json -d .unpackaged/retrieve/unpackaged
#sfdx force:source:deploy -c -p ../force-app/main/default -u $SFDC_DEV06_ALIAS
#sfdx force:mdapi:retrieve --json -k .unpackaged/pre/package.xml -r .unpackaged/retrieve
#sfdx force:apex:test:run --testlevel RunLocalTests --outputdir test-results --resultformat tap --targetusername $SFDC_DEV06_ALIAS