# Database_Course_Project

## Running project

1. Clone the project and run docker:
  
     Docker compose up -d

2. Go to pgadmin http://localhost:8080/

3. Login with credentials

     Username: admin@example.com

     password: admin

4. Add new server

     name: movies_db

     host name/address: postgres_db

     username: postgres

     password: mysecretpassword

     maintanence database: movies_db

5. After saving service, the database should exist with necessary tables

6. Do this command in terminal to add data to tables

    docker exec -it postgres_db psql -U postgres -d movies_db -f data/load.sql

7. Go to pgadmin http://localhost:8080/

8. open http://localhost:3001 in your browser to see the web app (its included when compose up the docker)