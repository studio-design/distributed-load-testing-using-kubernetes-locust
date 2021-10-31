from collections import namedtuple

# Generate a lock to wait until all users are created.
from gevent.lock import Semaphore
from locust import TaskSet, task, events, LoadTestShape, FastHttpUser

# All users lock
all_users_spawned = Semaphore()
all_users_spawned.acquire()

#
# User Amount
#
user_amount = 100


# Hold throwing requests until all users are spawned.
@events.init.add_listener
def _(environment, **kw):
    @environment.events.spawning_complete.add_listener
    def on_spawning_complete(**kw):
        all_users_spawned.release()


# Stops load when failure rate raised.
# @events.quitting.add_listener
# def _(environment, **kw):
#     if environment.stats.total.fail_ratio > 0.01:
#         logging.error("Test failed due to failure ratio > 1%")
#         environment.process_exit_code = 1
#     elif environment.stats.total.avg_response_time > 200:
#         logging.error("Test failed due to average response time ratio > 200 ms")
#         environment.process_exit_code = 1
#     elif environment.stats.total.get_response_time_percentile(0.95) > 800:
#         logging.error("Test failed due to 95th percentile response time > 800 ms")
#         environment.process_exit_code = 1
#     else:
#         environment.process_exit_code = 0


class UserTasks(TaskSet):
    def on_start(self):
        all_users_spawned.wait()
        self.wait()

    @task
    def get_root(self):
        self.client.get("/")


class SpikeLoadGenerator(FastHttpUser):
    tasks = [UserTasks]

    def __init__(self, *args, **kwargs):
        super(SpikeLoadGenerator, self).__init__(*args, **kwargs)


Step = namedtuple("Step", ["users", "dwell"])


class StepLoadShape(LoadTestShape):
    """
    A step load shape that waits until the target user count has
    been reached before waiting on a per-step timer.

    The purpose here is to ensure that a target number of users is always reached,
    regardless of how slow the user spawn rate is. The dwell time is there to
    observe the steady state at that number of users.

    Keyword arguments:

        targets_with_times -- iterable of 2-tuples, with the desired user count first,
            and the dwell (hold) time with that user count second

    """

    targets_with_times = Step(user_amount, 60)

    def __init__(self, *args, **kwargs):
        self.step = 0
        self.time_active = False
        super(StepLoadShape, self).__init__(*args, **kwargs)

    def tick(self):
        if self.step >= len(self.targets_with_times):
            return None

        target = self.targets_with_times
        users = self.get_current_user_count()

        if target.users == users:
            if not self.time_active:
                self.reset_time()
                self.time_active = True
            run_time = self.get_run_time()
            if run_time > target.dwell:
                self.step += 1
                self.time_active = False

        # Spawn rate is the second value here. It is not relevant because we are
        # rate-limited by the User init rate.  We set it arbitrarily high, which
        # means "spawn as fast as you can"
        return (target.users, user_amount)
