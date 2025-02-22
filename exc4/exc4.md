[Назад](../README.md)

---
## Задание 4: Защита доступа к кластеру Kubernetes

> Определите все роли и их полномочия при работе с Kubernetes

### Роли

| Роль              | Права роли                                                                                     | Группы пользователей             |
|-------------------|------------------------------------------------------------------------------------------------|----------------------------------|
| `view-only`       | Просмотр всех ресурсов в кластере (`get`, `list`, `watch`).                                    | Аналитики, аудиторы              |
| `cluster-admin`   | Полный доступ ко всем ресурсам (`*` на `*` ресурсах).                                          | Администраторы кластера          |
| `secrets-reader`  | Доступ только к секретам (`get`, `list`, `watch` на `secrets`).                                | DevOps, секьюрные инженеры       |
| `developer`       | CRUD подов, конфигурационных карт, деплойментов (`create`, `update`, `delete`).                | Разработчики                     |
| `namespace-admin` | Полный контроль ресурсов внутри конкретного namespace (`*` на `*` ресурсах в одном namespace). | Техлиды, ответственные за сервис |

### Пользователи

| Пользователь      | УЗ             | Группа                  | Назначенная роль  | Описание                                                   |
|-------------------|----------------|-------------------------|-------------------|------------------------------------------------------------|
| Рик Санчез        | `rick.sanchez` | Администраторы кластера | `cluster-admin`   | Главный архитектор, управляет кластером.                   |
| Морти Смит        | `morty.smith`  | Разработчики            | `developer`       | Разрабатывает сервисы, деплоит приложения.                 |
| Саммер Смит       | `summer.smith` | Разработчики            | `developer`       | Работает над поддержкой сервисов.                          |
| Бёрдперсон        | `birdperson`   | Техлиды                 | `namespace-admin` | Контролирует ресурсы в своём namespace.                    |
| Джерри Смит       | `jerry.smith`  | Аналитики               | `view-only`       | Только читает ресурсы кластера.                            |
| Абрадольф Линклер | `abrodolph`    | DevOps                  | `secrets-reader`  | Отвечает за безопасность и доступ к секретам.              |
| Сквончи           | `squanchy`     | Аналитики               | `view-only`       | Анализирует инфраструктуру, имеет доступ только на чтение. |


---
> Подготовьте скрипты для создания пользователей
 
```shell
#!/bin/bash

# Создание сертификатов для пользователей
create_user_cert() {
  USERNAME=$1
  USERGROUP=$2
  CERT_DIR="certs"
  mkdir -p $CERT_DIR

  openssl genrsa -out $CERT_DIR/${USERNAME}.key 2048
  openssl req -new -key $CERT_DIR/${USERNAME}.key -out $CERT_DIR/${USERNAME}.csr -subj "/CN=${USERNAME}/O=${USERGROUP}"
  openssl x509 -req -in $CERT_DIR/${USERNAME}.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out $CERT_DIR/${USERNAME}.crt -days 365

  kubectl config set-credentials $USERNAME --client-certificate=$CERT_DIR/${USERNAME}.crt --client-key=$CERT_DIR/${USERNAME}.key
}

# Создание пользователей и их групп
declare -A USERS
USERS["rick.sanchez"]="cluster-admin"
USERS["morty.smith"]="developer"
USERS["summer.smith"]="developer"
USERS["birdperson"]="namespace-admin"
USERS["jerry.smith"]="view-only"
USERS["abrodolph"]="secrets-reader"
USERS["squanchy"]="view-only"

echo "Создание пользователей..."
for USER in "${!USERS[@]}"; do
  create_user_cert "$USER" "${USERS[$USER]}"
  echo "Создан пользователь: $USER, Группа: ${USERS[$USER]}"
done

echo "Пользователи успешно созданы."
```

---

> Подготовьте скрипты, чтобы создать роли

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: view-only
rules:
  - apiGroups: [""]
    resources: ["*"]
    verbs: ["get", "list", "watch"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods", "deployments", "configmaps", "services"]
    verbs: ["create", "update", "delete"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-admin
  namespace: default
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secrets-reader
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list", "watch"]
```

---

> Подготовьте скрипты, чтобы связать пользователей с ролями

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-binding
subjects:
  - kind: User
    name: rick.sanchez
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: view-only-binding
subjects:
  - kind: User
    name: jerry.smith
    apiGroup: rbac.authorization.k8s.io
  - kind: User
    name: squanchy
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: view-only
  apiGroup: rbac.authorization.k8s.io

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: default
subjects:
  - kind: User
    name: morty.smith
    apiGroup: rbac.authorization.k8s.io
  - kind: User
    name: summer.smith
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: namespace-admin-binding
  namespace: default
subjects:
  - kind: User
    name: birdperson
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: namespace-admin
  apiGroup: rbac.authorization.k8s.io

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secrets-reader-binding
  namespace: default
subjects:
  - kind: User
    name: abrodolph
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: secrets-reader
  apiGroup: rbac.authorization.k8s.io

```

---
[Назад](../README.md)


