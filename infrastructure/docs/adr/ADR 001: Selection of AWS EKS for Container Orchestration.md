Status: Accepted
Context:
The application requires a reliable, scalable environment to run microservices (API Gateway, PHI Processor). 
Considering AWS as the primary cloud provider, ECS and EKS were evaluated. 
The project requires deep integration with the Kubernetes ecosystem (Velero for backups, CSI drivers for Secrets Manager).

Decision:
Use Amazon EKS (version 1.31).
    Use Managed Node Groups for system components (CoreDNS, Ingress Controller).
    Use AWS Fargate (profile "phi-apps") to isolate Protected Health Information (PHI) processing, minimizing the attack surface and simplifying compliance.
    Enable Envelope Encryption for Kubernetes secrets via AWS KMS.

Consequences:
    (+) Full control over the Kubernetes API.
    (+) HIPAA compliance through resource isolation in Fargate.
    (-) Increased operational complexity compared to ECS.