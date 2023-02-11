# Create user
mongo mongodb://mongo-0.db-svc:27017/weblog -u admin -p Password --authenticationDatabase admin ./adduser.js

# Create collection & insert initial data
mongo mongodb://mongo-0.db-svc:27017/weblog -u admin -p Password --authenticationDatabase admin ./insert.js
