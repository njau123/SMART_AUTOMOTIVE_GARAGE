from .models import AuditLog


class AuditService:

    @staticmethod
    def log(
        *,
        user=None,
        action,
        model_name="",
        object_id="",
        description="",
        old_values=None,
        new_values=None,
        request=None,
    ):
        ip_address = None
        user_agent = ""
        request_method = ""
        request_path = ""

        if request is not None:
            ip_address = request.META.get(
                "REMOTE_ADDR"
            )

            user_agent = request.META.get(
                "HTTP_USER_AGENT",
                "",
            )

            request_method = (
                request.method
            )

            request_path = (
                request.path
            )

        return AuditLog.objects.create(
            user=user,
            action=action,
            model_name=model_name,
            object_id=str(object_id)
            if object_id
            else "",
            description=description,
            old_values=old_values or {},
            new_values=new_values or {},
            ip_address=ip_address,
            user_agent=user_agent,
            request_method=request_method,
            request_path=request_path,
        )