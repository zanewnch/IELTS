# IELTS Backend

Django backend template for the IELTS project.

## Setup

```powershell
python -m pip install -r ..\requirements.txt
python manage.py migrate
python manage.py runserver 127.0.0.1:8000
```

## Health Check

```powershell
Invoke-WebRequest http://127.0.0.1:8000/api/health/
```

The default database is SQLite at `backend/db.sqlite3`.
