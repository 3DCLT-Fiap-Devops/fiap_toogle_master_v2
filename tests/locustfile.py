from locust import HttpUser, task, between

class ToogleUser(HttpUser):
    # Tempo de espera entre as requisições (0.1 a 0.5 segundos)
    wait_time = between(0.1, 0.5)

    @task
    def evaluate_flag(self):
        # O serviço espera os parâmetros via Query String, não via JSON body
        params = {
            "flag_name": "test-flag",
            "user_id": "user_12345"
        }
        headers = {
            "x-api-key": "tm_key_e75478d580db130091a5ec327ac4b240ee9600bff3a600e10329bf67ba671602"
        }
        # Faz a requisição com os parâmetros na URL (apropriado para o Ingress)
        self.client.get("/evaluate/evaluate", params=params, headers=headers)
