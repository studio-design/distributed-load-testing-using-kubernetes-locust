from locust import task, constant_pacing, FastHttpUser


class StaticLoad(FastHttpUser):
    wait_time = constant_pacing(1)

    @task
    def static_load(self):
        self.client.get("/")
