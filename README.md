# ADO-Scripts
## SetWorkItemDeletePermToDeny
This script will cycle through all azure devops orgs and set the project level permissions "Work-Item Delete" to deny for all users and groups.
This also can be limited to a smaller subset by providing values in the following list below, and also any of these can be specified or left blank:
OrgName: to limit to a specific azure devops organization by providing its name
ProjectId: to limit to a specific project by providing its id
UserDescriptor: to limit running the users to only this specific descriptor
GroupDescriptor: to limit running the groups to only this specific descriptor