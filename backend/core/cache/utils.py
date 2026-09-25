"""
Cache utilities kwa Smart Garage.
Inatumika kupunguza DB queries kwa 80-90%.
"""
import hashlib
import json
from functools import wraps

from django.core.cache import cache


def cache_key(prefix, *args, **kwargs):
    """Tengeneza cache key yenye hash."""
    raw = f"{prefix}:{args}:{sorted(kwargs.items())}"
    h = hashlib.md5(raw.encode()).hexdigest()[:16]
    return f"sg:{prefix}:{h}"


def cached(prefix, timeout=300, vary_on=None):
    """
    Decorator ya kucache function results.

    Matumizi:
        @cached('mechanics_list', timeout=300)
        def get_mechanics(region):
            return list(MechanicProfile.objects.filter(region=region).values())
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            key_parts = []
            if vary_on:
                for v in vary_on:
                    key_parts.append(str(kwargs.get(v, args[0] if args else '')))
            else:
                key_parts = [str(a) for a in args] + [f"{k}={v}" for k, v in kwargs.items()]

            key = cache_key(prefix, *key_parts)
            result = cache.get(key)
            if result is None:
                result = func(*args, **kwargs)
                cache.set(key, result, timeout)
            return result
        return wrapper
    return decorator


def invalidate(prefix):
    """
    Futa cache yote ya prefix fulani.
    Matumizi: baada ya update/create/delete.
    """
    try:
        # Kwa django-redis, tunaweza kutumia pattern
        from django_redis import get_redis_connection
        conn = get_redis_connection("default")
        pattern = f"*sg:{prefix}:*"
        keys = conn.keys(pattern)
        if keys:
            conn.delete(*keys)
    except Exception:
        # Fallback: clear all
        cache.clear()


def cache_get_or_set(key, callback, timeout=300):
    """Simpler helper."""
    result = cache.get(key)
    if result is None:
        result = callback()
        cache.set(key, result, timeout)
    return result
