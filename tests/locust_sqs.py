import os
import json
import time
import uuid
import boto3
from locust import User, task, between, events

# Obtém a URL da fila SQS e a Região AWS do ambiente (ou usa valores padrão)
SQS_URL = os.getenv("AWS_SQS_URL", "https://sqs.us-east-1.amazonaws.com/112719111297/toogle-events")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

class SqsUser(User):
    # Tempo de espera curto para enviar muitas mensagens e estressar o worker
    wait_time = between(0.01, 0.05)

    def on_start(self):
        # Inicializa o cliente SQS usando as credenciais configuradas na máquina
        self.client = boto3.client('sqs', region_name=AWS_REGION)

    @task
    def send_sqs_message(self):
        # Simula o payload que o analytics-service consome do SQS
        event = {
            "user_id": f"user_{uuid.uuid4().hex[:8]}",
            "flag_name": "test-flag",
            "result": True,
            "timestamp": time.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        start_time = time.time()
        try:
            self.client.send_message(
                QueueUrl=SQS_URL,
                MessageBody=json.dumps(event)
            )
            total_time = int((time.time() - start_time) * 1000)
            # Registra sucesso no painel do Locust
            events.request.fire(
                request_type="SQS",
                name="SendMessage",
                response_time=total_time,
                response_length=0,
                exception=None,
                context={}
            )
        except Exception as e:
            total_time = int((time.time() - start_time) * 1000)
            # Registra falha no painel do Locust
            events.request.fire(
                request_type="SQS",
                name="SendMessage",
                response_time=total_time,
                response_length=0,
                exception=e,
                context={}
            )
