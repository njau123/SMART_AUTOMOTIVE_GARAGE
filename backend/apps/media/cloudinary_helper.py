"""Cloudinary upload helper — safe kwa Render ephemeral storage."""
import os
import cloudinary
import cloudinary.uploader
from django.conf import settings


def _config_cloudinary():
    """Configure Cloudinary kwa mara moja."""
    cloudinary.config(
        cloud_name=os.environ.get('CLOUDINARY_CLOUD_NAME', ''),
        api_key=os.environ.get('CLOUDINARY_API_KEY', ''),
        api_secret=os.environ.get('CLOUDINARY_API_SECRET', ''),
        secure=True,
    )


def upload_to_cloudinary(file, folder='uploads', resource_type='auto'):
    """
    Upload file (image/video) kwenye Cloudinary.
    Returns: (url, public_id) au (None, None)
    """
    if not file:
        return None, None

    try:
        _config_cloudinary()
        result = cloudinary.uploader.upload(
            file,
            folder=f'smart_garage/{folder}',
            resource_type=resource_type,
            overwrite=False,
        )
        url = result.get('secure_url')
        public_id = result.get('public_id')
        print(f'[CLOUDINARY] Uploaded: {url[:60]}...')
        return url, public_id
    except Exception as e:
        print(f'[CLOUDINARY ERROR] {e}')
        return None, None
