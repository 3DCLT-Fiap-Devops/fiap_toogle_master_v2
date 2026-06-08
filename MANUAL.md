Inicio
Execute o install.sh para aplicar os patches Rode docker compose up --build para subir rodar os containers Execute o smoke-test.sh para veriricar se todos os containers estão ok Importe a collection do postman e o arquivo de environments

Projetos relacionados
Como estes repositórios abaixo são de outra conta, utilizaremos a pasta patches/ para conseguir aplicar as correções necessárias para os containers serem executados.

git submodule add https://github.com/FIAP-TCs/auth-service auth-service
git submodule add https://github.com/FIAP-TCs/targeting-service targeting-service
git submodule add https://github.com/FIAP-TCs/analytics-service analytics-service
git submodule add https://github.com/FIAP-TCs/flag-service flag-service
git submodule add https://github.com/FIAP-TCs/evaluation-service evaluation-service
🛠️ Aplicando Patches nos Submódulos
Como este repositório utiliza submódulos externos, as customizações necessárias para este projeto estão armazenadas na pasta /patches.

Para aplicá-las (garantindo compatibilidade de encoding e quebras de linha), execute:

git submodule update --init --recursive
# Aplicar todos os patches ignorando espaços em branco (evita erros Windows/Linux)
git submodule foreach 'git apply --ignore-whitespace ../../patches/$name.patch || echo "Patch já aplicado ou inexistente para $name"'
Nota: Se você receber um erro dizendo que o patch não pode ser aplicado, é provável que as alterações já estejam presentes nos arquivos.

Comandos para build docker build -t analytics -f docker/Dockerfile.analytics .

Para injetar a .env docker run --env-file .env.prod analytics

Para gerar patchs:

git submodule foreach 'git diff HEAD > ../../patches/$name.patch'

Powershell:
`docker run -p 8089:8089 -v "$(pwd)/tests:/mnt/locust" locustio/locust -f /mnt/locust/locustfile.py`