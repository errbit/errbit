# Deploy to Kubernetes (experimental)

### Clone and prepare the source code repository
```bash
git clone git@github.com:errbit/errbit.git
cd errbit
```

### Create replication controller
```bash
kubectl create -f docs/deployment/example/kubernetes/rc.yaml
```

### Create svc
```bash
kubectl create -f docs/deployment/example/kubernetes/svc.yaml
```
