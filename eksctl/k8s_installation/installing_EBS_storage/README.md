### Create IAM Policy via CLI

Save the policy JSON to a file:

```bash
cat <<EOF > ebs-csi-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume", "ec2:CreateSnapshot", "ec2:CreateTags",
        "ec2:CreateVolume", "ec2:DeleteSnapshot", "ec2:DeleteTags",
        "ec2:DeleteVolume", "ec2:DescribeInstances", "ec2:DescribeSnapshots",
        "ec2:DescribeTags", "ec2:DescribeVolumes", "ec2:DetachVolume"
      ],
      "Resource": "*"
    }
  ]
}
EOF
```

Then create the policy:

```bash
aws iam create-policy \
  --policy-name Amazon_EBS_CSI_Driver \
  --policy-document file://ebs-csi-policy.json
```

---

### Attach Policy to Node Group Role

1. **Get the Node IAM Role name:**

```bash
kubectl -n kube-system describe configmap aws-auth
```

Look for the `eks-name` value like:

```
eks-name: arn:aws:iam::<ACCOUNT_ID>:role/<NodeInstanceRoleName>
```

2. **Attach the policy (replace `<NodeInstanceRoleName>`):**

```bash
aws iam attach-role-policy \
  --role-name <NodeInstanceRoleName> \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/Amazon_EBS_CSI_Driver
```
