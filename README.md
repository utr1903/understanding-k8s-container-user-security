# Understanding Kubernetes container user security

This repo is dedicated to showcase various scenarios in Kubernetes with regards to creating images and running containers as different users.

In order to achieve that a very simple `ubuntu` image is used as a base image and a `test.sh` script is added and executed. The `test.sh` does nothing else than just printing Hello World!

## Case study

We will be running following setups!

| Case | Docker user | Docker group | Docker permission    | K8s user | K8s group | Script executed? |
| ---- | ----------- | ------------ | -------------------- | -------- | --------- | ---------------- |
| 01   | 0           | 0            | -rw-r--r-- 0 0       | 0        | 0         | ✅               |
| 02   | 0           | 0            | -rw-r--r-- 0 0       | 1000     | 0         | ✅               |
| 03   | 0           | 0            | -rw-r--r-- 0 0       | 0        | 1000      | ✅               |
| 04   | 0           | 0            | -rw-r--r-- 0 0       | 1000     | 1000      | ✅               |
| 05   | 0           | 0            | -rw-r--r-- 0 1000    | 0        | 0         | ✅               |
| 06   | 0           | 0            | -rw-r--r-- 0 1000    | 1000     | 0         | ✅               |
| 07   | 0           | 0            | -rw-r--r-- 0 1000    | 0        | 1000      | ✅               |
| 08   | 0           | 0            | -rw-r--r-- 0 1000    | 1000     | 1000      | ✅               |
| 09   | 0           | 0            | -rw-r--r-- 0 1000    | 0        | 2000      | ✅               |
| 10   | 0           | 0            | -rw-r--r-- 0 1000    | 1000     | 2000      | ✅               |
| 11   | 1000        | 0            | -rw-r--r-- 1000 0    | 0        | 0         | ✅               |
| 12   | 1000        | 0            | -rw-r--r-- 1000 0    | 1000     | 0         | ✅               |
| 13   | 1000        | 0            | -rw-r--r-- 1000 0    | 0        | 1000      | ✅               |
| 14   | 1000        | 0            | -rw-r--r-- 1000 0    | 1000     | 1000      | ✅               |
| 15   | 1000        | 0            | -rw-r--r-- 1000 0    | 0        | 2000      | ✅               |
| 16   | 1000        | 0            | -rw-r--r-- 1000 0    | 2000     | 2000      | ✅               |
| 17   | 1000        | 1000         | -rw-r--r-- 1000 1000 | 0        | 0         | ✅               |
| 18   | 1000        | 1000         | -rw-r--r-- 1000 1000 | 1000     | 0         | ✅               |
| 19   | 1000        | 1000         | -rw-r--r-- 1000 1000 | 0        | 1000      | ✅               |
| 20   | 1000        | 1000         | -rw-r--r-- 1000 1000 | 1000     | 1000      | ✅               |
| 21   | 1000        | 1000         | -rw-r--r-- 1000 1000 | 2000     | 2000      | ✅               |
| 22   | 0           | 1000         | -r--r-xr-- 0 1000    | 0        | 1000      | ✅               |
| 23   | 0           | 1000         | -r--r-xr-- 0 1000    | 1000     | 1000      | ✅               |
| 24   | 0           | 1000         | -r--r-xr-- 0 1000    | 2000     | 2000      | ❌               |

### Case 01

Here is our Dockerfile:

```Dockerfile
FROM ubuntu:latest

COPY test.sh /test.sh

CMD ["bash", "/test.sh"]
```

Switch to [app](/app/) directory and build & push the image:

```shell
cd /app
bash build_push_image.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME> --platform amd64|arm64
```

Switch to [helm](/helm/) and deploy the application onto the cluster as root user & group:

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 0
```

```shell
cd /helm
bash deploy.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME>
```

Let's check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 02

Now, in compared to the case before, let's run the container as a non-root user but a root group:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 0
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 03

Now, in compared to the case before, let's run the container as a root user but a non-root group:

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 1000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 04

Now, in compared to the case before, let's run the container as a non-root user and a non-root group:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 05

Now, let's switch the owner of the `test.sh` from root group to a non-root group. Here is our Dockerfile:

```Dockerfile
FROM ubuntu:latest

COPY test.sh /test.sh

RUN chown :1000 /test.sh

CMD ["bash", "/test.sh"]
```

Switch to [app](/app/) directory and build & push the image:

```shell
cd /app
bash build_push_image.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME> --platform amd64|arm64
```

Switch to [helm](/helm/) and deploy the application onto the cluster as root user & group:

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 0
```

```shell
cd /helm
bash deploy.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME>
```

Let's check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 06

Now, in compared to the case before, let's run the container as a non-root user but a root group:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 0
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 07

Now, in compared to the case before, let's run the container as a root user but a non-root group:

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 1000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 08

Now, in compared to the case before, let's run the container as a non-root user and a non-root group:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 09

Now, in compared to the case before, let's run the container as a non-root user and a non-root group:

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 2000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 10

Now, in compared to the case before, let's run the container as a non-root user and a non-root group:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 2000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 11

Now, let's switch the owner of the `test.sh` from root user to a non-root user and have the default user also a non-root user. Here is our Dockerfile:

```Dockerfile
FROM ubuntu:latest

COPY test.sh /test.sh

RUN chown 1000 /test.sh

USER 1000

CMD ["bash", "/test.sh"]
```

Switch to [app](/app/) directory and build & push the image:

```shell
cd /app
bash build_push_image.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME> --platform amd64|arm64
```

Switch to [helm](/helm/) and deploy the application onto the cluster as root user & group:

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 0
```

```shell
cd /helm
bash deploy.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME>
```

Let's check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 12

Now, in compared to the case before, let's run the container as a non-root user but a root group:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 0
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 13

Now, in compared to the case before, let's run the container as a root user but a non-root group:

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 1000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 14

Now, in compared to the case before, let's run the container as a non-root user and a non-root group:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 15

Now, in compared to the case before, let's run the container as a non-root user and a non-root group:

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 2000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 16

Now, in compared to the case before, let's run the container as a non-root user and a non-root group:

```yaml
securityContext:
  runAsUser: 2000
  runAsGroup: 2000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 17

Now, let's switch the owner of the `test.sh` from root user and root group to a non-root user and non-root group. Let's have the default user and group also a non-root user and non-root group. Here is our Dockerfile:

```Dockerfile
FROM ubuntu:latest

COPY test.sh /test.sh

RUN chown 1000:1000 /test.sh

USER 1000:1000

CMD ["bash", "/test.sh"]
```

Switch to [app](/app/) directory and build & push the image:

```shell
cd /app
bash build_push_image.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME> --platform amd64|arm64
```

Switch to [helm](/helm/) and deploy the application onto the cluster as root user & group:

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 0
```

```shell
cd /helm
bash deploy.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME>
```

Let's check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 18

Now, in compared to the case before, let's run the container as a non-root user but a root group:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 0
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 19

Now, in compared to the case before, let's run the container as a root user but a non-root group:

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 1000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 20

Now, in compared to the case before, let's run the container as a non-root user and a non-root group:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 21

Now, in compared to the case before, let's run the container as a non-root user and a non-root group:

```yaml
securityContext:
  runAsUser: 2000
  runAsGroup: 2000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 22

Now, let's switch the owner of the `test.sh` from root group to a non-root group. Let's have the default group also a non-root group. On top of that, let's change file permissions to `-r--r-xr--`. Here is our Dockerfile:

```Dockerfile
FROM ubuntu:latest

COPY test.sh /test.sh

RUN chown :1000 /test.sh && chmod 450 /test.sh

USER :1000

CMD ["bash", "/test.sh"]
```

Switch to [app](/app/) directory and build & push the image:

```shell
cd /app
bash build_push_image.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME> --platform amd64|arm64
```

Switch to [helm](/helm/) and deploy the application onto the cluster as root user & group:

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 1000
```

```shell
cd /helm
bash deploy.sh --registry <YOUR_REGISTRY> --username <YOUR_USERNAME>
```

Let's check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 23

Now, in compared to the case before, let's run the container as a non-root user but a root group:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> Hello World
```

### Case 24

Now, in compared to the case before, let's run the container as a non-root user but a root group:

```yaml
securityContext:
  runAsUser: 2000
  runAsGroup: 2000
```

Let's deploy it again and check the pod logs:

```
kubectl logs -l app=test
-> bash: /test.sh: Permission denied
```
