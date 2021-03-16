## pat that needs access across all azure devop orgs that script 
## needs to run against, as this is used to pull that list
[string]$PAT = "PAT" 
[string]$DefaultOrg = "ORGNAME" ## this is used to call member entitlement api to get id
[string]$MemberToUse = "email" ## member to use to pull all azure devops orgs has access to, as a memberId is required to call that api
[string]$NamespaceId = "52d39943-cb85-4d7f-8fa8-c6baac873819" ## this is for namespace of project, only to be changed if wanting to set a different permission on a different namespace

## auth into az devops with personal access token
echo $PAT | az devops login


## for limiting to a specific org, project, group, or user, leave blank if not wanting to limit that category:
$TestingOrgName = "LIMIT_TO_ORGNAME"
$TestingProjectId = "LIMIT_TO_PROJECTID"
$TestingGroupDescriptor = ""## for example vssgp.HJAS...
$TestingUserDescriptor = ""## for example aad.HJAS...




## get full list of azure devops orgs, in order to do this will
## call the accounts api, but to do this a memberId is a required field,
## so we need to call the MemberEntitlment api first to get the memberId
$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriAccounts = "https://app.vssps.visualstudio.com/_apis/accounts?api-version=5.1"
$UriMemberEntitlment = "https://vsaex.dev.azure.com/$DefaultOrg/_apis/userentitlements?api-version=5.1-preview.2"

## need to get memberId first as will need it to call api to get all orgs
$member = Invoke-RestMethod -Uri $UriMemberEntitlment -Method get -Headers $AzureDevOpsAuthenicationHeader
$memberId = ""

## cycle through members and get the id for the member pertaining to one set above
foreach ($user in $member.members)
{
    if ($user.user.principalname -eq $MemberToUse)
    {
        $memberId = $user.id
    }
}

## pass in memberId as body and call api to get all accounts (organizations)
$accountsRequestBody = @{
    "memberId" = $memberId
}
$accountret = Invoke-RestMethod -Uri $UriAccounts -Method get -Headers $AzureDevOpsAuthenicationHeader -Body $accountsRequestBody -ContentType "application/json"
$allorgs = $accountret.value



## cycle through each org
foreach ($org in $allorgs)
{
    ## if wanting to test with 1 specific org or for all
    if (!$TestingOrgName -OR $org.accountName -eq $TestingOrgName)
    {
        $OrgUri = "https://dev.azure.com/" + $org.accountName + "/"

        ## get all projects in org
        $projectIds = az devops project list --org $OrgUri --query "value[*].id" -o tsv
        foreach($project in $projectIds)
        {
            if (!$TestingProjectId -OR $project -eq $TestingProjectId)
            {
                ## cycle through all groups and remove permission
                $groupdescriptors = az devops security group list --query "graphGroups[*].descriptor" -o tsv
                foreach($groupdescriptor in $groupdescriptors)
                {
                    ## this will not work for Project Administrators group, since that is a default that cannot be changed

                    ## if wanting to test with 1 specific group or for all
                    if (!$TestingGroupDescriptor -OR $groupdescriptor -eq $TestingGroupDescriptor)
                    {
                        $token = "`$PROJECT:vstfs:///Classification/TeamProject/" + $project

                        az devops security permission update --id $NamespaceId --subject $groupdescriptor --token $token --deny-bit 8192 --allow-bit 0 --merge true
                    }
                }

                ## cycle through all users and remove permission
                $userdescriptors = az devops user list --query "members[*].user.descriptor" -o tsv
                foreach($userdescriptor in $userdescriptors)
                {
                    ## if wanting to test with 1 specific user or for all                   
                    if (!$TestingUserDescriptor -OR $userdescriptor -eq $TestingUserDescriptor)
                    {
                        $token = "`$PROJECT:vstfs:///Classification/TeamProject/" + $project

                            az devops security permission update --id $NamespaceId --subject $userdescriptor --token $token --deny-bit 8192 --allow-bit 0 --merge true
                    }
                }
            }
        }
    }
}



