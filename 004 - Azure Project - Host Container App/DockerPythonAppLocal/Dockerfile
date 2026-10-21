# Start with a lightweight Debian Linux image that already includes Python 3.12.
FROM python:3.12-slim-bookworm

# Create /app inside the container and use it as the working directory.
WORKDIR /app

# Install the system packages and Microsoft ODBC Driver needed to connect to Azure SQL.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        unixodbc-dev \
        libgssapi-krb5-2 \
    && curl -sSL \
        https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb \
        -o /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql18 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy the list of Python dependencies our application requires.
COPY requirements.txt .

# Install those Python packages inside the image.
RUN pip install --no-cache-dir -r requirements.txt

# Copy our application files into the /app directory inside the image.
COPY . .

# Document that our application listens on port 50505.
EXPOSE 50505

# Start the application with Gunicorn when the container runs.
CMD ["gunicorn", "--bind", "0.0.0.0:50505", "--workers", "2", "app:app"]