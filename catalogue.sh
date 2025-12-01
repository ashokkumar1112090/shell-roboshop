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

curl -s -L -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip #hide progress still shows error (sS)
VALIDATE $? "downloaded code"

cd /app 
VALIDATE $? "changing directory to app "

rm -rf /app/*
VALIDATE $? "Removing existing code"  #idempotent (2nd time) if code already there delete it

unzip -qq /tmp/catalogue.zip #tohide archieve summary qq used
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

INDEX=$(mongosh mongodb.ashokking.sbs --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")   #script idempotent bcz 2nd time again we dont load here that is cmd
#google shellscript cmd to check mongodb collection exist
#less than 0 here bcz if not there it shows -1 if ther its hows greater than 0
#index varb bcz it represent index of cat products 
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarted catalogue"

#refer 19-set.sh in shell practcie basics folder you will know usage of set
#refer catalogue-set.sh folder



