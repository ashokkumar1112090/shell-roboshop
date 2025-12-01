#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR="$PWD"
MONGODB_HOST="mongodb.ashokking.sbs"

mkdir -p $LOGS_FOLDER
echo "script start executed at: $(date)" | tee -a $LOG_FILE  # echo printed one to APPEND in log file

if [ $USERID -ne 0 ]; then
  echo -e " $R ERROR  $N: please run this script with root previlege"
  exit 1
fi

VALIDATE(){     
    if  [ $1 -ne 0 ]; then
      echo -e " $2 IS  $R FAILURE $N" | tee -a $LOG_FILE
      exit 1
   else
      echo -e " $2 is $G success $N" | tee -a $LOG_FILE
   fi
}


dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installed nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "creating app"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "downloaded code"

cd /app 
VALIDATE $? "changing directory to app "

unzip /tmp/catalogue.zip
VALIDATE $? "unzipped code"

npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service #$SCRIPT_DIR/
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enable catalogue"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "start catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install MongoDB client"

INDEX=$(mongosh mongodb.ashokking.sbs --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarted catalogue"




