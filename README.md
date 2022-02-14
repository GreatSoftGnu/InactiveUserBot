# InactiveUserBot
Checks all users in domain and if logon date is further back than 30 days disables the account. If logon date is more than 90 days it sends an email to an account to start the termination process/removal of the stale user account. In my environment I have it going to our ticketing system so it creates a ticket for helpdesk. Also generates a log every time it runs as well as clears out old logs.


![image](https://user-images.githubusercontent.com/32029981/153957168-d0df011a-fb5f-4ff8-bae6-73f750ade2ef.png)
![image](https://user-images.githubusercontent.com/32029981/153957131-5b6d5098-1dd6-4b13-b39d-9fadd11754fb.png)
