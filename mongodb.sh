#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell--roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #means /var/log/shell-practice/16-logs.log

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
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "adding mongo repo" 

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "installing mongodb"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enable mongodb"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Start mongodb" 