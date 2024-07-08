# Understanding Kubernetes container user security

This repo is dedicated to showcase various scenarios in Kubernetes with regards to creating images and running containers as different users.

In order to achieve that a very simple `ubuntu` image is used as a base image and a `test.sh` script is added and executed. The `test.sh` does nothing else than just printing Hello World!

## Case study

We will be running following setups!

| Case | Docker user | Docker group | Docker permission | K8s user | K8s group | Executed with start? | Executed after start? |
| ---- | ----------- | ------------ | ----------------- | -------- | --------- | -------------------- | --------------------- |
| 01   | 0           | 0            | -rw-r--r-- 0 0    | 0        | 0         | ❌                   | ❌                    |
| 02   | 0           | 0            | -rwxr--r-- 0 0    | 0        | 0         | ✅                   | ✅                    |
| 03   | 0           | 0            | -rwxr--r-- 0 0    | 1000     | 0         | ✅                   | ❌                    |
| 04   | 0           | 0            | -rwxr--r-- 0 0    | 0        | 1000      | ✅                   | ✅                    |
| 05   | 0           | 0            | -rwxr--r-- 0 0    | 1000     | 1000      | ❌                   | ❌                    |
| 06   | 0           | 1000         | -rwxr-xr-- 0 1000 | 0        | 0         | ✅                   | ✅                    |
| 07   | 0           | 1000         | -rwxr-xr-- 0 1000 | 1000     | 0         | ❌                   | ❌                    |
| 08   | 0           | 1000         | -rwxr-xr-- 0 1000 | 0        | 1000      | ✅                   | ✅                    |
| 09   | 0           | 1000         | -rwxr-xr-- 0 1000 | 1000     | 1000      | ✅                   | ✅                    |
| 10   | 0           | 1000         | -rwxr-xr-- 0 1000 | 1000     | 2000      | ❌                   | ❌                    |
| 11   | nonroot     | nonroot      | -rwxr-xr-- 0 1000 | 0        | 0         | ✅                   | ✅                    |
| 12   | nonroot     | nonroot      | -rwxr-xr-- 0 1000 | 2000     | 1000      | ✅                   | ✅                    |
| 13   | nonroot     | nonroot      | -rwxr-xr-- 0 1000 | 2000     | 2000      | ❌                   | ❌                    |

In order to run and check the results, do the following:

Switch to [app](/app/) directory and build & push the image:

```shell
cd /app
bash build_push_image.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME> --platform amd64|arm64
```

To deploy -> Switch to [helm](/helm/) and run [`deploy.sh`](/helm/deploy.sh):

```yaml
securityContext:
  runAsUser: xxx
  runAsGroup: xxx
```

```shell
cd /helm
bash deploy.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME>
```

To check the pod status:

```shell
kubectl describe pod -l app=test
```

To check the pod logs:

```shell
kubectl logs -l app=test
```

To execute the script within the pod:

```shell
kubectl exec -it $(kubectl get po -l app=test -o jsonpath='{.items[0].metadata.name}') -- bash
/test.sh
```

### Case 01, 02, 03, 04, 05

The Dockerfile:

```Dockerfile
FROM ubuntu:latest

COPY test.sh /test.sh

CMD ["/test.sh"]
```

### Case 06, 07, 08, 09, 10

The Dockerfile:

```Dockerfile
FROM ubuntu:latest

COPY test.sh /test.sh

RUN chown :1000 /test.sh && chmod 750 /test.sh

USER :1000

CMD ["/test.sh"]
```

### Case 11, 12

The Dockerfile:

```Dockerfile
FROM ubuntu:latest

COPY test.sh /test.sh

RUN chown :1000 /test.sh && chmod 750 /test.sh

USER nonroot:nonroot

CMD ["/test.sh"]
```
