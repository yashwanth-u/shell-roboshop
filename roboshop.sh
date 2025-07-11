#!bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0650920f370e0b14f"
INSTANCES=("mongodb" "mysql" "redis" "catalogue" "user" 
"cart" "shipping" "frontend" "payment" " rabbitmq" "dispatch")
ZONE_ID="Z05426313QK02PI64BDTM"
DOMAIN_NAME="yashwanth.space"

for instance in "${INSTANCES[@]}"
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-0650920f370e0b14f --tag-specifications "ResourceType=instance,
    Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].
        Instances[0].PrivateIpAddress'  --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].
        Instances[0].PublicIpAddress'  --output text)
    fi
    echo "$instance IP address is $IP"
    aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch '
        {
    "Comment": "creating or updating a record set"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$instance'.'$DOMAIN_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : '" $IP "'
        }]
      }
    }]
  }
  '
done
