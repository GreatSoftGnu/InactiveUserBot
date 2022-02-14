# InactiveUserBot
Checks all users in domain and if logon date is further back than 30 days disables the account. If logon date is more than 90 days it sends an email to an account to start the termination process/removal of the stale user account. In my environment I have it going to our ticketing system so it creates a ticket for helpdesk. Also generates a log every time it runs as well as clears out old logs.


![image](https://user-images.githubusercontent.com/32029981/153957224-ec5eb0b2-41b2-48a9-939d-09ae418e17ea.png)
![image](https://user-images.githubusercontent.com/32029981/153957209-48bf7b1d-78a9-4e8b-bc1c-8d983f1a6607.png)
