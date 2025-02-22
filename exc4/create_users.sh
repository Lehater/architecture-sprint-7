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
