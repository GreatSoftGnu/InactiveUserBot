# InactiveUserBot
Checks all users in domain and if logon date is further back than 30 days disables the account. If logon date is more than 90 days it sends an email to an account to start the termination process/removal of the stale user account. In my environment I have it going to our ticketing system so it creates a ticket for helpdesk. Also generates a log every time it runs as well as clears out old logs.


![image](https://user-images.githubusercontent.com/32029981/153956481-73ae6c15-2674-438b-9f33-1b8c4dc7669d.png)
![image](https://user-images.githubusercontent.com/32029981/153956224-5209e764-680d-4d37-b7a4-424f9262d404.png)
