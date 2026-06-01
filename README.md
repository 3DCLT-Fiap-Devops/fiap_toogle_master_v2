Projetos relacionados

```
git submodule add https://github.com/FIAP-TCs/auth-service auth-service
git submodule add https://github.com/FIAP-TCs/targeting-service targeting-service
git submodule add https://github.com/FIAP-TCs/analytics-service analytics-service
git submodule add https://github.com/FIAP-TCs/flag-service flag-service
git submodule add https://github.com/FIAP-TCs/evaluation-service evaluation-service
```


Comandos para build `docker build -t analytics -f docker/Dockerfile.analytics .`

Para injetar a `.env` `docker run --env-file .env.prod analytics`