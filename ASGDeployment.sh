
#!/bin/bash
NAME_TAG="Omron-Connect-Blue"
SECURITY_GRP="sg-1f8f2962"
INSTANCE_ID=`aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, InstanceId]' --filters 'Name=tag:Name,Values=$NAME_TAG' --output text | grep us-east-1 | grep running | awk '{print $3}'`
echo $INSTANCE_ID
DATE=`date +%Y-%m-%d\_%H.%M.%S`
AMI_ID=`aws ec2 create-image --instance-id $INSTANCE_ID --name "$NAME_TAG-$DATE" --description "$NAME_TAG at $DATE UTC" --no-reboot |awk '{print $2}' | sed 's:^.\(.*\).$:\1:'`
echo $AMI_ID
TESTID=`aws ec2 describe-images --image-ids $AMI_ID | grep pending | awk '{print $2}' | sed 's:^.\(.*\).$:\1:' | sed 's/.$//'`
while [ "$TESTID" = "pending" ]
do
TESTID=`aws ec2 describe-images --image-ids $AMI_ID | grep pending | awk '{print $2}' | sed 's:^.\(.*\).$:\1:' | sed 's/.$//'`
echo "waiting to complete AMI"
sleep 20
done
echo "FINISHED AMI"
aws autoscaling create-launch-configuration --launch-configuration-name $NAME_TAG-LC-$DATE --image-id $AMI_ID --instance-type t2.medium --key-name omron-prod  --security-groups $SECURITY_GRP --instance-monitoring Enabled=true --associate-public-ip-address --user-data file:///home/jenkins/userdata.txt --block-device-mappings "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 50 } },{ \"DeviceName\": \"/dev/sdb\", \"Ebs\": { \"VolumeSize\": 20 } } ]"
echo "Launch-Config-Finished"
aws autoscaling update-auto-scaling-group --auto-scaling-group-name Blue-Omron-Connect-Live --launch-configuration-name $NAME_TAG-LC-$DATE
echo "Updated-ASG with new LC"