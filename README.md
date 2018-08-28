# devopsproject

1. Application is developed using Flask python api. It listens on port 5002. 
   /messages - GET method - lists all the received messages
   /messages - POST method - content type as json - accepts the message and write the entry into sqlite3 database. json must contains fields name and messages
   /messages/name_value - GET method - get the json content stored under this name with an extra field 'palindrome'. This value will be either true or false to denote the message is a  palindrome or not

2. Application is dockerized
   Run the following commands to build image and publish them
   make build-image
   make publish-image
   The image is publicly available in dockerhub - mnivedithaa/devopsproject

3. Please install terraform in your local as that is the tool used to automate deployment process in AWS
   Also populate the required aws credentials in file 'dc.tfvars' located inside terraform folder

4. Follow the commad to run and destroy the deployment
   make platform
   make destroyplatform

   When we do the deployment, the output displays the url which is used to access our application

5. Sample queries:
   (i) To post a message
   curl -H "Content-type: application/json" -X POST ${endpoint}/messages -d '{"messages":"madam","name":"nivy"}'
   (ii) To get a message based on name and also mention whether it is a palindrome or not
   curl -X GET http://127.0.0.1:5002/message/nivy
   (iii) To delete the messages based on name
   curl -X DELETE http://127.0.0.1:5002/message/nivy

6. Regarding deployment
   (i) ALB is used. target groups are created. Listeners listen on port 5002
   (ii) ECS cluster is created. Service is created to run the application
   (iii) Application is dockerized and runs in supervisor to run in background and restart if it fails.
