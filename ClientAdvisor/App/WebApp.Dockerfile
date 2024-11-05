FROM node:20-alpine AS frontend  
RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app

WORKDIR /home/node/app 
COPY ./frontend/package*.json ./  
USER node
RUN npm ci  
COPY --chown=node:node ./frontend/ ./frontend  
COPY --chown=node:node ./static/ ./static  
WORKDIR /home/node/app/frontend
RUN npm run build
  
FROM python:3.11-alpine 
RUN apk add --no-cache --virtual .build-deps \  
    build-base \  
    libffi-dev \  
    openssl-dev \  
    curl \
    unixodbc-dev \  
    && apk add --no-cache \  
    libpq \
    # Download and install the ODBC Driver and mssql-tools
    && curl -O https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/msodbcsql18_18.4.1.1-1_amd64.apk \
    && curl -O https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/mssql-tools18_18.4.1.1-1_amd64.apk \
    && apk add --allow-untrusted msodbcsql18_18.4.1.1-1_amd64.apk \
    && apk add --allow-untrusted mssql-tools18_18.4.1.1-1_amd64.apk \
    && rm msodbcsql18_18.4.1.1-1_amd64.apk mssql-tools18_18.4.1.1-1_amd64.apk
  
COPY requirements.txt /usr/src/app/  
RUN pip install --no-cache-dir -r /usr/src/app/requirements.txt \  
    && rm -rf /root/.cache  
  
COPY . /usr/src/app/  
COPY --from=frontend /home/node/app/static  /usr/src/app/static/
WORKDIR /usr/src/app  
EXPOSE 80  

CMD ["gunicorn"  , "-b", "0.0.0.0:80", "app:app"]