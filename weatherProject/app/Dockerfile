FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt

COPY . /app/
RUN pip install gunicorn
EXPOSE 8000
CMD ["gunicorn","--bind" ,"0.0.0.0:8000","app:app"]


