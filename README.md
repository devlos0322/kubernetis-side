# kubernetis-side

## 0. Kubectl API 버전확인
```
$ kubectl api-versions
$ sed -i 's/xxx/yyy/' ~/file.txt # 파일 내용 변경
```
## 1. Node 확인
```bash
$ kubectl get nodes
```
```
NAME     STATUS   ROLES                  AGE   VERSION
m-k8s    Ready    control-plane,master   40h   v1.20.2
w1-k8s   Ready    <none>                 39h   v1.20.2
w2-k8s   Ready    <none>                 39h   v1.20.2
w3-k8s   Ready    <none>                 39h   v1.20.2
```

## 2. Pod 
### 2.1. Pod 생성 및 확인
```bash
$ kubectl run nginx-pod --image=nginx
$ kubectl get pods -o wide
```

```
NAME    READY   STATUS    RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
nginx   1/1     Running   1          40h   172.16.221.130   w1-k8s   <none>           <none>
```
### 2.2. Pod 삭제
```bash
kubectl delete pod nginx
```

```
pod "nginx" deleted
```

### 2.3. yaml파일을 이용한 Pod 생성 및 삭제

```bash
kubectl create -f ~/yaml/nginx-pod.yaml
```

```bash
kubectl delete -f ~/yaml/nginx-pod.yaml 
```
```
pod "nginx-pod" deleted
```

## 3. Deployment 생성하기

```bash
$ kubectl create deployment dpy-hname --image=sysnet4admin/echo-hname
```
```bash
$ kubectl delete deployment dpy-hname
```

## 4. 레플리카 셋으로 파드 관리
### 4.1. Pod를 이용한 replicas를 확장
에러 발생. Deployment로 진행해야함
```bash
$ kubectl run nginx-pod --image=nginx
$ kubectl scale pod nginx-pod --replicas=3
```

```
Error from server (NotFound): the server could not find the requested resource
```

### 4.2. Deployment를 이용한 replicas 확장
kubectl create deployment nginx-deployment --image=nginx
kubectl scale deployment nginx-deployment --replicas=3
kubectl delete deployment nginx-deployment

```
$ kubectl get deploy -o wide
```
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES   SELECTOR
nginx-deployment   3/3     3            3           2m23s   nginx        nginx    app=nginx-deployment
```
```
$ kubectl get pods
```
```
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-84cd76b964-2vd6f   1/1     Running   0          33s
nginx-deployment-84cd76b964-k5w7r   1/1     Running   0          33s
nginx-deployment-84cd76b964-rnh87   1/1     Running   0          57s
nginx-pod                           1/1     Running   0          10m
```

### 4.3 Object spec을 이용하여 delployment 생성하기
디플로이먼트를 생성하면서 한꺼번에 여러 파드 생성 불가능 \
create에서는 replicas옵션 사용할 수 없고, scale은 만들어진 Deployment에서 사용가능 하기 때문 \
Object의 변경사항이 자주 일어나는 경우: apply \
Object의 일관성을 유지하는 경우: create 

```
$ kubectl create -f ~/yaml/nginx-deployment.yaml
$ kubectl sed -i 's/replicas: 3/replicas:6/' ~/yaml/nginx-deployment.yaml
$ kubectl apply -f yaml/nginx-deployment.yaml 
```

```
NAME                          READY   STATUS    RESTARTS   AGE
echo-hname-56fd8fb86d-4xjgn   1/1     Running   0          12m
echo-hname-56fd8fb86d-9qmcm   1/1     Running   0          49s
echo-hname-56fd8fb86d-cqmjx   1/1     Running   0          49s
echo-hname-56fd8fb86d-mw96v   1/1     Running   0          49s
echo-hname-56fd8fb86d-nmm4h   1/1     Running   0          12m
echo-hname-56fd8fb86d-nqjdl   1/1     Running   0          12m
nginx-pod                     1/1     Running   0          35m
```
## 5. Node의 이상상태 설정 및 해제
### 5.1. Node 문제 표시/표시 해제
```
$ kubectl cordon w3-k8s
$ kubectl drain w3-k8s --ignore-daemonsets # 문제 노드의 pod를 다른 곳으로 이동 시키기
$ kubectl uncordon w3-k8s
```

## 6. 외부에서 Pod 접근하기 (서비스)
### 6.1. 노드포트 이용
```bash
$ kubectl create deployment np-pods --image=sysnet4admin/echo-hname
$ kubectl create -f ~/object_spec/nodeport.yaml

```
#### 6.1.1. 노드포트 서비스를 이용한 부하분산 테스트
NodeJS를 이용하여 서비스를 재귀 호출
```javascript
const request = require('request');
function get_requset () {
    request('http://192.168.1.101:30000', function (error, response, body) {
        console.log(body); 
        get_requset();
    });
}
get_requset();
```
```bash
$ kubectl scale deployment np-pods --replicas=3
```
노드포트의 오브젝트 스펙에 적힌 np-pods와 디플로이먼트 이름을 확인하여 동일할 경우 같은 파드라고 간주하기 때문에 자동으로 부하 분산됨

#### 6.1.2. 노드포트 서비스를 expose로 생성하기
```
$ kubectl expose deployment np-pods --type=NodePort --name=nodeport-service-v2 --port=80
$ kubectl delete service nodeport-service
$ kubectl delete service nodeport-service-v2
```

```bash
$ kubectl edit deployments np-pods
$ kubectl autoscale deployment np-pods --min=1 --max=30 --cpu-percent=50
$ kubectl get pods
```
```
NAME                       READY   STATUS    RESTARTS   AGE
nginx-pod                  1/1     Running   0          170m
np-pods-544bc9557c-28qgd   1/1     Running   0          103s
np-pods-544bc9557c-44t9z   1/1     Running   0          58s
np-pods-544bc9557c-4q7cg   1/1     Running   0          119s
np-pods-544bc9557c-757c7   1/1     Running   0          119s
np-pods-544bc9557c-7xm2k   1/1     Running   0          103s
np-pods-544bc9557c-cbt5z   1/1     Running   0          88s
np-pods-544bc9557c-nrsn7   1/1     Running   0          103s
np-pods-544bc9557c-qzkgq   1/1     Running   0          88s
np-pods-544bc9557c-t2554   1/1     Running   0          58s
np-pods-544bc9557c-thp2b   1/1     Running   0          103s
np-pods-544bc9557c-v8s97   1/1     Running   0          119s
np-pods-544bc9557c-vvd5x   1/1     Running   0          2m55s
np-pods-544bc9557c-wk482   1/1     Running   0          58s
np-pods-544bc9557c-xtjfh   1/1     Running   0          58s
```