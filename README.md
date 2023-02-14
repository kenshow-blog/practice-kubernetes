## なにか

私が kubernetes を学習するにあたってメモ書きしたリポジトリです。

kubernetes の基礎 ~ 応用(kubernetes 環境での web アプリ開発)まで取り組んでいました。

## kubernetes 上で web アプリ構築

### システム構成図

[システム構成図 1](./web-app/out/システム構成.png)

[システム構成図 2](./web-app/out/システム構成1.png)

### ネットワーク構成図

[ネットワーク構成図](./web-app/out/ネットワーク構成.png)

### 開発工程

1. db

2. ap サーバー

3. フロントエンド

4. web サーバー(nginx)

### secret.yml の作成

```sh
openssl rand -base64 1024 | tr -d '\r\n' | cut -c 1-1024 > keyfile
kubectl create secret generic mongo-secret --from-literal=root_username=admin --from-literal=root_password=Password --from-file=./keyfile
```

### あるサービスから他サービスへのアクセス

pod 名 + headless service 名でアクセスできる

```
ping mongo-1.db-svc
```

### pod 上で立ち上げる自作 Docker Image が起動するかを確認する

image が db に繋がるか確かめるために手動でコンテナ立ち上げ

```
docker run -e MONGODB_USERNAME="user" -e MONGODB_PASSWORD="welcome" -e MONGODB_HOSTS="192.168.49.2:32717" -e MONGODB_DATABASE="weblog" -d -p 8080:3000 weblog-app:v1.0.0
```

web サーバーが ap-server と疎通できるか確認するための手動コンテナ立ち上げ

```
docker run -e APPLICATION_HOST=192.168.49.2:30000 -p 8080:80 -d weblog-web:v1.0.0
```

## kubernetes 学習メモ

[仮想化環境](./out/%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%BC%E3%83%B3%E3%82%B7%E3%83%A7%E3%83%83%E3%83%88%202023-02-04%2017.19.16.png)

1. minikube のインストールを行う

## クラスタ実行/停止/状態確認

実行: minikube start --vm-driver=none
停止: minikube stop
状態確認: minikube status

## アドオンを操作するコマンド

追加: minikube addons enable ADDON_NAME
削除: minikube addons disable ADDON_NAME
一覧確認: minikube addons list

## Docker コマンド復習

使われてないイメージを一括削除

`docker image prune`

## Kubernetes 入門

### hello-world を k8s 上で実行する

- `kubectl run hello-world --
image hello-world --restart=Never`

- `kubectl get pod`で作られてか確認

- `kubectl logs pod/hello-world`でログを確認

### k8s とは？

コンテナオーケストレーション

システム運用で困っていたことが解決できる

- システムリソースの利用率に無駄がある → 複数コンテナの共存
- 突発的な大量アクセスでシステムが応答しなくなった → 水平スケール
- 突然、一部システムがダウンした → 監視 & 自動デプロイ
- リリースのたびにサービス停止が発生する → ローリングデプロイ

使えるリソースを一元管理

マスターノードとワーカーノードが存在する

マスターノードを経由して各ワーカーノードを操作する

4 分類 10 種類のリソース

ワークロード

- Pod
- ReplicaSet
- Deployment
- StatefulSet

サービス

- Service
- Ingress

設定

- ConfigMap
- Secret

ストレージ

- PersistentVolume
- PersistentVolumeClaim

リソース作成コマンド

`kubectl apply -f pod.yml`

pod.yml はマニフェストファイル

種別: kind はリソース種別。kind によって apiVersion は決まっている

メタデータ: Pod 名は名前空間と合わせて一意にする。

コンテナ定義: spec 内にコンテナ名を指定、どのイメージを指定するかもできる。

Secret リソースのコマンド作成

`kubectl create secret generic NAME OPTIONS`

k8s と Docker のコマンド操作の違い
Docker: ENTRYPOINT
k8s: command

Docker: CMD
k8s: args

apiVersion は k8s の reference から確認

コンテナへ入る
kubectl exec -it POD sh

exit でコンテナから出る

### ファイル転送

`kubectl cp SRC DEST`
SRC: 転送元ファイル
DEST: 転送先ファイル

例

`kubectl cp ./sample.txt debug:/var/tmp/sample.txt`

### ログの確認

状態の確認

kubectl describe [TYPE/NAME]

例
kubectl describe pod/debug

ログの確認(アクセスログなど)

kubectl logs [TYPE/NAME]

`kubectl get pod -o wide`で ip アドレスも確認可能

## Pod

最小単位、同一環境で動作する Docker コンテナの集合

複数のコンテナを所有することが可能

## ReplicaSet

Pod の集合。Pod をスケールできる
replicas 2 を指定すると 2 つコンテナができる

```
kensho@test practice-kubernetes % kubectl apply -f replicaset.yml
replicaset.apps/sample created
kensho@test practice-kubernetes % kubectl get pods
NAME           READY   STATUS    RESTARTS   AGE
sample-mcplt   1/1     Running   0          8s
sample-njwn7   1/1     Running   0          8s
```

## Deployment

ReplicaSet の集合。ReplicaSet の世代管理ができる。

replicaset の履歴保存する

strategy: デプロイ方法を指定する
maxSurge: レプリカ数を超えて良い Pod 数
maxUnavailable: 一度に消失して良い Pod 数

ロールアウト履歴確認
`kubectl rollout history TYPE/NAME`

ロールバック
`kubectl rollout undo TYPE/NAME --to-revision=N(指定したリビジョンに戻す)`

作成例

```
kensho@test practice-kubernetes % kubectl get all
NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-5988866fb8-9plts   1/1     Running   0          22s
pod/nginx-5988866fb8-ct7rb   1/1     Running   0          22s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   32h

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   2/2     2            2           22s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-5988866fb8   2         2         2       22s
```

```
% kubectl rollout history deploy/nginx
deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
2         Update nginx
```

CHANGE-CAUSE を更新するには metadata に以下を追記

```
metadata:
  name: nginx
  annotations:
    kubernetes.io/change-cause: "Update nginx"
```

## Service

外部公開、名前解決、L4 ロードバランサーの役割を果たす。

[サービス](./out/service.png)

```
kubectl get all
NAME        READY   STATUS    RESTARTS   AGE
pod/nginx   1/1     Running   0          103s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        2d6h
service/web-svc      NodePort    10.107.255.230   <none>        80:30000/TCP   41s
```

**_つまづきポイント_**
`minikube ipのip + 30000`
ではアクセスできない

1. `minikube service web-svc --url`で ssh で繋げた状態にする
2. `ps -ef | grep docker@127.0.0.1`で開いているポートを確認
3. -L 60789:10.107.255.230:80 と会ったら 60789 がつながっているので localhost:68789 にアクセスすると繋がる。

## ConfigMap について学ぶ

k8s で使用する設定情報を集約するファイル

watch mode

`kubectl get pods -w`

**_環境変数で接続する場合_**
valueFrom に作成した ConfigMap を指定する。

```yml
env:
  - name: TYPE
    valueFrom:
      configMapKeyRef:
        name: sample-config
        key: type
```

**\*volumes と volumeMounts に指定してマウント**

## Secret

k8s 上で利用する機微情報

`kubectl create secret generic NAME [option]`
名称を指定して Secret を生成

オプション

- --from-literal=key=value キーバリューを指定して作成
- --from-file=filename ファイルから作成

`echo -n 'TEXT' | base64`
指定した文字列の Base64 変換後文字列を取得する。

```
touch secret.yml
kensho@test practice-kubernetes % kubectl create secret generic sample-secret --from-literal=message='H
ello World!' --from-file=./keyfile
secret/sample-secret created
kensho@test practice-kubernetes % kubectl get secret
NAME            TYPE     DATA   AGE
sample-secret   Opaque   2      8s
kensho@test practice-kubernetes % kubectl get secret/sample-secret -o yaml
```

生成された yaml をコピペする

## 永続データ

- **_PersistentVolume(PV)_**
  永続データの実態

- **_PersistentVolumeClaim(PVC)_**
  永続データの要求

## StatefulSet

Pod の集合。Pod をスケールする際の名前が一定。

リソースを立ち上げ一時的に作成した pod から本リソースへアクセスする。

```
% kubectl run debug --image=centos:7 -it --rm --restart=Never -- sh
If you don't see a command prompt, try pressing enter.
sh-4.2# curl http://nginx-0.sample-svc/
```

## Ingress

外部公開、L7 ロードバランサー

URL でサービスを切り替えられる

## minikube 特有の罠

hostPath はルートディレクトリに作らないとマウントができない。

> A note on mounts, persistence, and minikube hosts
> minikube is configured to persist files stored under the following directories, which are made in the Minikube VM (or on your localhost if running on bare metal). You may lose data from other directories on reboots.

/data
/var/lib/minikube
/var/lib/docker
/tmp/hostpath_pv
/tmp/hostpath-provisioner
引用：https://minikube.sigs.k8s.io/docs/reference/persistent_volumes/
