# Checklist – Tech Challenge Fase 2: ToggleMaster Microsserviços

> **Legenda:** 
> · `[A]`     = Opção A (AWS Academy) 
> · `[B]`     = Opção B (Conta pessoal)
> · `[AB]`   = Comum a ambas

---

## 1. Conteinerização (Docker)

- [x] Criar Dockerfile otimizado (multi-stage build) para o **auth-service** (Go) `[AB]`
- [x] Criar Dockerfile otimizado (multi-stage build) para o **flag-service** (Python) `[AB]`
- [x] Criar Dockerfile otimizado (multi-stage build) para o **targeting-service** (Python) `[AB]`
- [x] Criar Dockerfile otimizado (multi-stage build) para o **evaluation-service** (Go) `[AB]`
- [x] Criar Dockerfile otimizado (multi-stage build) para o **analytics-service** (Python) `[AB]`
- [x] Criar `docker-compose.yml` com os 5 microsserviços + 4 bancos de dados locais (2× PostgreSQL, Redis, DynamoDB Local) `[AB]`
- [x] Validar que `docker compose up` sobe todos os 9 contêineres sem erros `[AB]`

---

## 2. Infraestrutura na Nuvem – Cluster Kubernetes

- [x] Criar cluster EKS via Console da AWS usando a role **LabRole** `[A]`
- [x] Criar Managed Node Group via console com Node IAM Role = LabRole `[A]`
- [x] Configurar Auto Scaling do node group (Mín=1, Desejado=2, Máx=4) `[A]`
- [ ] Criar cluster Kubernetes (EKS com `eksctl`, GKE, AKS ou outro) `[B]`

---

## 3. Infraestrutura – Registro de Contêineres (ECR)

- [x] Criar repositório ECR: `auth-service` `[AB]`
- [x] Criar repositório ECR: `flag-service` `[AB]`
- [x] Criar repositório ECR: `targeting-service` `[AB]`
- [x] Criar repositório ECR: `evaluation-service` `[AB]`
- [x] Criar repositório ECR: `analytics-service` `[AB]`
- [x] Publicar as 5 imagens Docker nos respectivos repositórios ECR `[AB]`

---

## 4. Infraestrutura – Bancos de Dados e Serviços AWS

- [x] Criar instância RDS PostgreSQL para o **auth-service** `[AB]`
- [x] Criar instância RDS PostgreSQL para o **flag-service** `[AB]`
- [x] Criar instância RDS PostgreSQL para o **targeting-service** `[AB]`
- [x] Criar cluster ElastiCache for Redis para o **evaluation-service** `[AB]`
- [x] Criar tabela DynamoDB para o **analytics-service** (verificar nome e chave primária no código-fonte) `[AB]`
- [x] Criar fila SQS Standard para evaluation-service (produtor) e analytics-service (consumidor) `[AB]`
- [x] Anotar todos os endpoints/strings de conexão (RDS, ElastiCache, DynamoDB, ARN da fila SQS) `[AB]`

---

## 5. Configuração do Cluster

- [x] Instalar **Metrics Server** no cluster (`kubectl apply -f .../components.yaml`) `[AB]`
- [x] Instalar **Nginx Ingress Controller** via Helm ou `kubectl apply` (usando LabRole) `[A]`
- [ ] Instalar **Nginx Ingress Controller** com IRSA (IAM Roles for Service Accounts) `[B]`

---

## 6. Manifestos Kubernetes – Recursos Básicos

- [x] Criar **Namespaces** para separação lógica dos microsserviços `[AB]`
- [x] Criar **Secrets** com credenciais em base64 para cada microsserviço `[AB]`
- [x] Criar **ConfigMaps** com URLs internas e variáveis de ambiente `[AB]`
- [x] Criar **Deployment** para auth-service (com Requests/Limits e Readiness/LivenessProbe) `[AB]`
- [x] Criar **Deployment** para flag-service (com Requests/Limits e Readiness/LivenessProbe) `[AB]`
- [x] Criar **Deployment** para targeting-service (com Requests/Limits e Readiness/LivenessProbe) `[AB]`
- [x] Criar **Deployment** para evaluation-service (com Requests/Limits e Readiness/LivenessProbe) `[AB]`
- [x] Criar **Deployment** para analytics-service (com Requests/Limits e Readiness/LivenessProbe) `[AB]`
- [x] Criar **Service** (ClusterIP) para cada um dos 5 microsserviços `[AB]`
- [x] Criar manifesto **Ingress** com regras de roteamento (`/auth`, `/flags`, etc.) `[AB]`

---

## 7. Escalabilidade

- [x] Criar **HPA** para evaluation-service (`targetCPUUtilizationPercentage: 70`) `[A]`
- [x] Criar **HPA** para analytics-service baseado em CPU `[A]`
- [ ] Instalar **KEDA** no cluster `[B]`
- [ ] Criar **ScaledObject** para analytics-service monitorando a fila SQS (`queueDepth`, escala 0→N) `[B]`

---

## 8. Entregáveis – Vídeo (até 20 min)

- [x] Demonstrar `docker compose up` com todos os 9 contêineres rodando localmente `[AB]`
- [x] Mostrar o cluster Kubernetes provisionado na nuvem `[AB]`
- [x] Mostrar os 5 microsserviços rodando como Pods (`kubectl get pods`) `[AB]`
- [x] Demonstrar o Nginx Ingress funcionando via `curl` ou Postman na URL do Load Balancer `[AB]`
- [x] Gerar carga no evaluation-service e mostrar HPA escalando réplicas (`kubectl get hpa` e `kubectl get pods`) `[AB]`
- [x] Enviar mensagens para a fila SQS e mostrar escala do analytics-service (HPA ou KEDA) `[AB]`
- [x] Mostrar dados aparecendo na tabela DynamoDB `[AB]`
- [x] Explicar a arquitetura e os desafios encontrados (ex: limitações da LabRole) `[AB]`
- [x] Explicar a escolha de escalabilidade do analytics-service (HPA por CPU ou KEDA por fila) `[AB]`
- [x] Explicar a diferença de propósito entre RDS, ElastiCache e DynamoDB `[AB]`

---

## 9. Entregáveis – Relatório (.PDF ou .txt)

- [ ] Incluir nomes dos participantes, RMs e usernames do Discord `[AB]`
- [ ] Incluir links dos repositórios de código `[AB]`
- [ ] Incluir link do vídeo (YouTube ou similar) `[AB]`
- [ ] _(Opcional)_ Adicionar link do badge do Google Cloud Skills Boost para +10 pontos extras `[AB]`