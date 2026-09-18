"""
Custom Pagination Classes
Provides consistent pagination across the API
"""

from rest_framework import pagination
from rest_framework.response import Response
from collections import OrderedDict


class StandardPagination(pagination.PageNumberPagination):
    """
    Standard pagination class with customizable page size
    """
    
    # Default page size
    page_size = 20
    
    # Allow client to override page size
    page_size_query_param = 'page_size'
    
    # Maximum page size allowed
    max_page_size = 100
    
    # Page number parameter
    page_query_param = 'page'
    
    def get_paginated_response(self, data):
        """
        Return paginated response in standard format
        """
        return Response(
            OrderedDict([
                ('success', True),
                ('message', 'Data retrieved successfully'),
                ('data', {
                    'items': data,
                    'pagination': {
                        'total_items': self.page.paginator.count,
                        'total_pages': self.page.paginator.num_pages,
                        'current_page': self.page.number,
                        'page_size': self.page.paginator.per_page,
                        'next': self.get_next_link(),
                        'previous': self.get_previous_link(),
                    }
                }),
                ('errors', None),
                ('status', 200),
            ])
        )


class LargeResultsPagination(StandardPagination):
    """Pagination for large result sets"""
    page_size = 50
    max_page_size = 200


class SmallResultsPagination(StandardPagination):
    """Pagination for small result sets"""
    page_size = 10
    max_page_size = 50


class CursorPagination(pagination.CursorPagination):
    """Cursor-based pagination for infinite scrolling"""
    
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100
    cursor_query_param = 'cursor'
    ordering = '-created_at'
    
    def get_paginated_response(self, data):
        return Response(
            OrderedDict([
                ('success', True),
                ('message', 'Data retrieved successfully'),
                ('data', {
                    'items': data,
                    'pagination': {
                        'next': self.get_next_link(),
                        'previous': self.get_previous_link(),
                    }
                }),
                ('errors', None),
                ('status', 200),
            ])
        )


class LimitOffsetPagination(pagination.LimitOffsetPagination):
    """Limit/Offset pagination"""
    
    default_limit = 20
    limit_query_param = 'limit'
    offset_query_param = 'offset'
    max_limit = 100
    
    def get_paginated_response(self, data):
        return Response(
            OrderedDict([
                ('success', True),
                ('message', 'Data retrieved successfully'),
                ('data', {
                    'items': data,
                    'pagination': {
                        'count': self.count,
                        'limit': self.limit,
                        'offset': self.offset,
                        'next': self.get_next_link(),
                        'previous': self.get_previous_link(),
                    }
                }),
                ('errors', None),
                ('status', 200),
            ])
        )


def get_pagination_class(pagination_type='standard'):
    """Get pagination class by type"""
    pagination_map = {
        'standard': StandardPagination,
        'large': LargeResultsPagination,
        'small': SmallResultsPagination,
        'cursor': CursorPagination,
        'limit_offset': LimitOffsetPagination,
    }
    return pagination_map.get(pagination_type, StandardPagination)


class CustomPaginationMixin:
    """Mixin to easily add pagination to viewsets"""
    
    pagination_class = StandardPagination
    pagination_type = 'standard'
    
    @property
    def paginator(self):
        if not hasattr(self, '_paginator'):
            if self.pagination_class is None:
                self._paginator = None
            else:
                self._paginator = self.pagination_class()
        return self._paginator
    
    def paginate_queryset(self, queryset):
        if self.paginator is None:
            return None
        
        pagination_type = self.request.query_params.get('pagination_type')
        if pagination_type:
            pagination_class = get_pagination_class(pagination_type)
            self.paginator = pagination_class()
        
        return self.paginator.paginate_queryset(queryset, self.request, view=self)
    
    def get_paginated_response(self, data):
        if self.paginator is None:
            return Response({
                'success': True,
                'message': 'Data retrieved successfully',
                'data': data,
                'errors': None,
                'status': 200,
            })
        return self.paginator.get_paginated_response(data)
