import io
import json
import os
import re
from datetime import date, datetime
import frontmatter
import markdown
import pyodbc
from azure.core.exceptions import AzureError
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from flask import Flask, abort, render_template, send_file
from markupsafe import Markup

app = Flask(__name__)

#--- Azure Blob Storage
storage_account_url = os.environ["STORAGE_ACCOUNT_URL"]     # mandatory
storage_sas_token = os.getenv("STORAGE_SAS_TOKEN")          # optional

if storage_sas_token: # SAS Authentication
    storage_credential = storage_sas_token
else: # Managed Identity
    storage_credential = DefaultAzureCredential()

blob_service_client = BlobServiceClient(
    account_url=storage_account_url,
    credential=storage_credential,
)

#--- Azure SQL Database
sql_server = os.environ["SQL_SERVER"]       # mandatory
sql_database = os.environ["SQL_DATABASE"]   # mandatory
sql_username = os.getenv("SQL_USERNAME")    # optional
sql_password = os.getenv("SQL_PASSWORD")    # optional

def get_sql_connection():
    connection_string = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER=tcp:{sql_server},1433;"
        f"DATABASE={sql_database};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
    )

    if sql_username and sql_password: # SQL Authentication
        connection_string += (
            f"UID={sql_username};"
            f"PWD={sql_password};"
        )
    else: # Managed Identity
        connection_string += (
            "Authentication=ActiveDirectoryMsi;"
            f"UID={os.environ['AZURE_CLIENT_ID']};"
        )

    return pyodbc.connect(connection_string)

# Reads all keywords from dbo.Keywords in ID order
def get_keywords() -> list[str]:
    connection = None

    try:
        connection = get_sql_connection()
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT Keyword
            FROM dbo.Keywords
            ORDER BY Id;
            """
        )
        return [row.Keyword for row in cursor.fetchall()]

    except pyodbc.Error as error:
        app.logger.exception(
            "Failed to retrieve keywords from Azure SQL: %s",
            error,
        )
        return []

    finally:
        if connection is not None:
            connection.close()

#--- Videos
# Loads the video sections from videolinks.json in the site blob container
def get_video_sections() -> list[dict]:
    blob_client = blob_service_client.get_blob_client(
        container="site",
        blob="videolinks.json",
    )

    try:
        video_text = (
            blob_client
            .download_blob()
            .readall()
            .decode("utf-8")
        )
        return json.loads(video_text)

    except (AzureError, UnicodeDecodeError, json.JSONDecodeError) as error:
        app.logger.exception(
            "Failed to retrieve video links from Blob Storage: %s",
            error,
        )
        return []

#--- Article Helpers
# Converts a front-matter date into text that can be displayed
def normalize_article_date(value) -> str:
    if isinstance(value, (date, datetime)):
        return value.strftime("%B %d, %Y").replace(" 0", " ")
    return str(value) if value else ""

# Finds all published Markdown files in the articles blob container
def get_article_posts() -> list[dict]:
    container_client = blob_service_client.get_container_client("articles")
    article_posts: list[dict] = []

    try:
        blobs = container_client.list_blobs()

        for blob in blobs:
            blob_name = blob.name

            if not blob_name.endswith(".md"): # Ignore non-Markdown files
                continue

            if blob_name.startswith("_"): # Ignore files beginning with an underscore
                continue

            blob_client = container_client.get_blob_client(blob_name)

            try:
                article_text = (
                    blob_client
                    .download_blob()
                    .readall()
                    .decode("utf-8")
                )
                post = frontmatter.loads(article_text)

            except (AzureError, UnicodeDecodeError):
                continue

            slug = blob_name.removesuffix(".md")
            title = post.get(
                "title",
                slug.replace("-", " ").replace("_", " ").title(),
            )
            article_date = normalize_article_date(post.get("date", ""))
            sort_date = post.get("date", "")

            if isinstance(sort_date, datetime):
                sort_value = sort_date
            elif isinstance(sort_date, date):
                sort_value = datetime.combine(
                    sort_date,
                    datetime.min.time(),
                )
            else:
                try:
                    sort_value = datetime.fromisoformat(str(sort_date))
                except (TypeError, ValueError):
                    sort_value = datetime.min

            article_posts.append(
                {
                    "title": str(title),
                    "slug": slug,
                    "date": article_date,
                    "category": str(post.get("category", "")),
                    "sort_date": sort_value,
                }
            )

    except AzureError as error:
        app.logger.exception(
            "Failed to retrieve articles from Blob Storage: %s",
            error,
        )
        return []

    return sorted(
        article_posts,
        key=lambda post: post["sort_date"],
        reverse=True,
    )

# Loads one Markdown article from Blob Storage and converts it to HTML
def get_article_post(slug: str) -> dict:
    if not re.fullmatch(r"[a-zA-Z0-9_-]+", slug):
        abort(404)

    blob_client = blob_service_client.get_blob_client(
        container="articles",
        blob=f"{slug}.md",
    )

    try:
        article_text = (
            blob_client
            .download_blob()
            .readall()
            .decode("utf-8")
        )
        post = frontmatter.loads(article_text)

    except (AzureError, UnicodeDecodeError):
        abort(404)

    title = post.get(
        "title",
        slug.replace("-", " ").replace("_", " ").title(),
    )

    article_html = markdown.markdown(
        post.content,
        extensions=[
            "fenced_code",
            "tables",
            "sane_lists",
            "smarty",
            "toc",
        ],
        extension_configs={
            "toc": {
                "permalink": False,
            }
        },
    )

    return {
        "title": str(title),
        "date": normalize_article_date(post.get("date", "")),
        "category": str(post.get("category", "")),
        "description": str(post.get("description", "")),
        "content": Markup(article_html),
    }

#--- Page Routes
@app.route("/")
def home():
    return render_template(
        "index.html",
        video_sections=get_video_sections(),
        keywords=get_keywords(),
    )

@app.route("/about")
def about():
    return render_template("about.html")

@app.route("/articles")
def articles():
    return render_template(
        "articles.html",
        article_posts=get_article_posts(),
    )

@app.route("/articles/<slug>")
def article_article(slug: str):
    post = get_article_post(slug)
    return render_template(
        "article.html",
        post=post,
    )

#--- Storage Asset Route
@app.route("/storage/<path:blob_name>")
def storage_asset(blob_name: str):
    allowed_files = {
        "headshot.png",
        "biopicture.png",
    }

    if blob_name not in allowed_files:
        abort(404)

    blob_client = blob_service_client.get_blob_client(
        container="images",
        blob=blob_name,
    )

    try:
        properties = blob_client.get_blob_properties()
        file_data = blob_client.download_blob().readall()
    except AzureError:
        abort(404)

    content_type = (
        properties.content_settings.content_type
        or "application/octet-stream"
    )

    return send_file(
        io.BytesIO(file_data),
        mimetype=content_type,
        download_name=blob_name,
        max_age=3600,
    )

@app.route("/health")
def health():
    return {"status": "healthy"}, 200