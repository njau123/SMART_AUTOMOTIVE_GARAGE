from .firebase_config import *  # noqa
import os
from pathlib import Path
import os
import environ
import dj_database_url

# Env
env = environ.Env()

from dotenv import load_dotenv

# Load .env file from project root
load_dotenv(Path(__file__).resolve().parent.parent / '.env')

# Build paths
BASE_DIR = Path(__file__).resolve().parent.parent

# ============ FIREBASE ADMIN ============
FIREBASE_CREDENTIALS = os.path.join(BASE_DIR, 'firebase-service-account.json')

# Firebase Admin env vars (production)
FIREBASE_PROJECT_ID = env('FIREBASE_PROJECT_ID', default='smart-automotive-garage')
FIREBASE_CLIENT_EMAIL = env('FIREBASE_CLIENT_EMAIL', default='')
FIREBASE_PRIVATE_KEY = env('FIREBASE_PRIVATE_KEY', default='')
FIREBASE_STORAGE_BUCKET = env('FIREBASE_STORAGE_BUCKET', default='smart-automotive-garage.appspot.com')


# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = env('SECRET_KEY', default='dev-secret-key-change-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = env.bool('DEBUG', default=False)

ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=['localhost', '127.0.0.1', '.onrender.com', '.vercel.app'])

# Application definition
INSTALLED_APPS = [
    'api',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # Third party
    'rest_framework',
    'corsheaders',
    'django_filters',
    
    # Local apps
    'apps.accounts',
    'apps.vehicles',
    'apps.mechanics',
    'apps.services',
    'apps.spare_parts',
    'apps.bookings',
    'apps.diagnosis',
    'apps.ai_diagnosis.apps.AiDiagnosisConfig',
    'apps.obd_scanner.apps.ObdScannerConfig',
    'apps.bluetooth',
    'apps.wallet',
    'apps.payments',
    'apps.notifications',
    'apps.news',
    'apps.advertisements',
    'apps.contact',
    'apps.tracking',
    'apps.reviews',
    'apps.chat',
    'apps.dashboard',
    'apps.analytics',
    'apps.media',
    'apps.reports',
    'apps.audit_logs',
    'apps.system',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.middleware.gzip.GZipMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'automotive_backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'automotive_backend.wsgi.application'

# Database
DATABASES = {
    'default': dj_database_url.config(
        default=env('DATABASE_URL', default=f"sqlite:///{BASE_DIR / 'db.sqlite3'}"),
        conn_max_age=600,
        conn_health_checks=True,
    )
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Dar_es_Salaam'
USE_I18N = True
USE_TZ = True

# Static files
STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# === UPLOAD LIMITS (kwa chat, media, n.k.) ===
DATA_UPLOAD_MAX_MEMORY_SIZE = 52428800  # 50 MB
FILE_UPLOAD_MAX_MEMORY_SIZE = 52428800  # 50 MB
DATA_UPLOAD_MAX_NUMBER_FIELDS = 10000

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Custom User Model
AUTH_USER_MODEL = 'accounts.User'

# CORS Settings
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

# REST Framework
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        (
            "rest_framework_simplejwt.authentication."
            "JWTAuthentication"
        ),
    ],

    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],

    "DEFAULT_RENDERER_CLASSES": [
        "rest_framework.renderers.JSONRenderer",
    ],

    "DEFAULT_PARSER_CLASSES": [
        "rest_framework.parsers.JSONParser",
        "rest_framework.parsers.FormParser",
        "rest_framework.parsers.MultiPartParser",
    ],

    "DEFAULT_PAGINATION_CLASS": (
        "core.pagination.pagination."
        "StandardPagination"
    ),

    "PAGE_SIZE": 20,

    "DEFAULT_VERSIONING_CLASS": (
        "rest_framework.versioning.URLPathVersioning"
    ),

    "DEFAULT_VERSION": "v1",

    "ALLOWED_VERSIONS": [
        "v1",
    ],

    "DEFAULT_SCHEMA_CLASS": (
        "drf_spectacular.openapi.AutoSchema"
    ),

    "EXCEPTION_HANDLER": (
        "core.exceptions.handlers."
        "custom_exception_handler"
    ),
}
# JWT Settings
from datetime import timedelta
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'VERIFYING_KEY': None,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
    'TOKEN_TYPE_CLAIM': 'token_type',
}

# ============ EMAIL SETTINGS ============
EMAIL_BACKEND = os.environ.get(
    'EMAIL_BACKEND',
    'django.core.mail.backends.smtp.EmailBackend'
)
EMAIL_HOST = os.environ.get('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', '587'))
EMAIL_USE_TLS = os.environ.get('EMAIL_USE_TLS', 'True').lower() == 'true'
EMAIL_USE_SSL = os.environ.get('EMAIL_USE_SSL', 'False').lower() == 'true'
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')
DEFAULT_FROM_EMAIL = os.environ.get(
    'DEFAULT_FROM_EMAIL',
    'Smart Automotive Garage <noreply@smartautomotivegarage.com>'
)

# ============ SESSION SETTINGS ============
SESSION_COOKIE_AGE = 10800  # 3 hours (admin)
SESSION_ENGINE = 'django.contrib.sessions.backends.db'
SESSION_EXPIRE_AT_BROWSER_CLOSE = True

# JWT Settings for different roles
SIMPLE_JWT['ACCESS_TOKEN_LIFETIME'] = timedelta(hours=8)  # User + Mechanic session

# ============ EMAIL SETTINGS (Development block removed) ============

# ============ LOCAL DEVELOPMENT CACHE ============
# Redis is reserved for production/staging where a compatible
# Redis server is available.
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "smart-automotive-garage-local",
    }
}

CACHE_TTL = 60 * 15  # 15 minutes

# Use the normal database-backed Django session during local development.
SESSION_ENGINE = "django.contrib.sessions.backends.db"

# ============ REST FRAMEWORK PAGINATION ============


# ============ CORS (multipart upload) ============
from corsheaders.defaults import default_headers

CORS_ALLOW_HEADERS = list(default_headers) + [
    'content-type',
    'content-disposition',
    'authorization',
]

CORS_ALLOW_METHODS = [
    'DELETE', 'GET', 'OPTIONS', 'PATCH', 'POST', 'PUT',
]

CORS_ALLOW_CREDENTIALS = True
