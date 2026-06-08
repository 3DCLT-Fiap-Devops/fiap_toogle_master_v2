from locust import HttpUser, task, between

class ToogleUser(HttpUser):
    # Tempo de espera entre as requisições (0.1 a 0.5 segundos)
    wait_time = between(0.1, 0.5)

    @task
    def evaluate_flag(self):
        # O serviço espera os parâmetros via Query String, não via JSON body
        params = {
            "flag_name": "test-flag",
            "user_id": "user-123"
        }
        headers = {
            "x-api-key": "tm_key_f54b81bc161a5b84c277ed954384ae950c87adb8c795892db4abfaef75aaacab"
        }
        # Faz a requisição com os parâmetros na URL
        self.client.get("/evaluate", params=params, headers=headers)
