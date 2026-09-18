from rest_framework.pagination import PageNumberPagination

class SparePartPagination(PageNumberPagination):
    """Pagination for spare parts with configurable page size"""
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

class VehiclePagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 50

class DiagnosisPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 50

class BookingPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 50

class NotificationPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100
