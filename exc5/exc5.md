[Назад](../README.md)

---
non-admin-api-allow.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress  # Полностью блокируем входящий и исходящий трафик

---

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-front-end-to-back-end
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: back-end-api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: front-end
    ports:
    - protocol: TCP
      port: 80

---

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-admin-front-end-to-admin-back-end
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: admin-back-end-api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: admin-front-end
    ports:
    - protocol: TCP
      port: 80
```



---
[Назад](../README.md)


