# celery_app.py

from celery import Celery

# Redis broker URL (default Redis on localhost, DB 0)
REDIS_URL = "redis://localhost:6379/0"

celery = Celery(
    'backend_tasks',
    broker=REDIS_URL,
    backend=REDIS_URL,
    include=['tasks.delivery_tasks']
)

# (Basic settings; you can keep these as-is)
celery.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_expires=3600,
    timezone='UTC'
)
