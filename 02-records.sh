#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f" #everyon has same
SG_ID="sg-08465db66b958e1af" #in your aws security group id
ZONE_ID="Z054321925TDC5TE1HMOZ" #CHECK in aws hosted zones your id will be there
DOMAIN_NAME="ashokking.sbs"

for instance in $@   #RUN SCRIPT give args ex: $ sh 01-record.sh frontend mysql
 do 
     INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

   # get private ip
   if [ $instance != "frontend" ]; then
       IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
       RECORD_NAME="$instance.$DOMAIN_NAME" #mongodb.ashokking.sbs
   else
         IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
      RECORD_NAME="$DOMAIN_NAME" #ashokking.sbs   bcz front end 
    fi 
   
   echo "$instance: $IP"



aws route53 change-resource-record-sets \
  --hosted-zone-id Z054321925TDC5TE1HMOZ \
  --change-batch '
  {
    "Comment": "Updating record set"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$RECORD_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }
  '

done