from firebase_admin import storage


from .client import get_storage_bucket


class FirebaseStorageService:

    @staticmethod
    def upload_file(
        file_obj,
        destination,
        content_type=None,
    ):
        bucket = get_storage_bucket()

        blob = bucket.blob(
            destination
        )

        blob.upload_from_file(
            file_obj,
            content_type=content_type,
        )

        blob.make_public()

        return {
            "name": blob.name,
            "url": blob.public_url,
        }

    @staticmethod
    def delete_file(
        destination,
    ):
        bucket = get_storage_bucket()

        blob = bucket.blob(
            destination
        )

        if blob.exists():
            blob.delete()

        return True

    @staticmethod
    def get_file_url(
        destination,
    ):
        bucket = get_storage_bucket()

        blob = bucket.blob(
            destination
        )

        if not blob.exists():
            return None

        blob.make_public()

        return blob.public_url