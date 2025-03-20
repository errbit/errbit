# Deploy to Kubernetes (experimental)

## Clone and prepare the source code repository

```shell
git clone git@github.com:errbit/errbit.git
cd errbit
```

## Create replication controller

```shell
kubectl create -f docs/deployment/example/kubernetes/rc.yml
```

## Create svc

```shell
kubectl create -f docs/deployment/example/kubernetes/svc.yml
```
