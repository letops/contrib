from rest_framework.decorators import detail_route, list_route
from rest_framework.response import Response
from rest_framework import authentication, permissions, status, viewsets
from rest_framework.authentication import SessionAuthentication


class UnsafeSessionAuthentication(SessionAuthentication):
    def authenticate(self, request):
        http_request = request._request
        user = getattr(http_request, 'user', None)
        if not user or not user.is_active:
            return None
        return (user, None)

    def enforce_csrf(self, request):
        return


class EmptyAPIView(viewsets.ViewSet):
    environment = None
    authentication_classes = (UnsafeSessionAuthentication, )
    permission_classes = (permissions.AllowAny, )


class WebAPIView(EmptyAPIView):
    def list(self, request, format=None):
        self.environment.load_data(
            method='list',
            filters=request.data.get("filters", None))
        if len(self.environment.permissions) == 0 or request.user.has_perms(
                self.environment.permissions):
            serial = self.environment.serializer(
                self.environment.query,
                many=True,
                read_only=True)
            return Response(serial.data, status=status.HTTP_200_OK)
        else:
            return Response(status=status.HTTP_403_FORBIDDEN)

    # Get only one object by its ID or PK
    def retrieve(self, request, pk, format=None):
        self.environment.load_data(method='retrieve', pk=pk)
        if len(self.environment.permissions) == 0 or request.user.has_perms(
                self.environment.permissions):
            serial = self.environment.serializer(
                self.environment.query,
                many=False,
                read_only=True)
            return Response(serial.data, status=status.HTTP_200_OK)
        else:
            return Response(status=status.HTTP_403_FORBIDDEN)

    # Create a new object from scratch
    @list_route(methods=['post'])
    def create(self, request, format=None):
        self.environment.load_data('create')
        if len(self.environment.permissions) == 0 or request.user.has_perms(
                self.environment.permissions):
            serial = self.environment.serializer(request.data)
            if serial.is_valid():
                serial.save()
                return Response(serial.data, status=status.HTTP_201_CREATED)
            return Response(
                serial.errors,
                status=status.HTTP_412_PRECONDITION_FAILED)
        else:
            return Response(status=status.HTTP_403_FORBIDDEN)

    # Update an existing object using its ID or PK
    def update(self, request, pk, format=None):
        self.environment.load_data('update', pk=pk)
        if len(self.environment.permissions) == 0 or request.user.has_perms(
                self.environment.permissions):
            serial = self.environment.serializer(
                self.environment.query,
                data=request.data)
            if serial.is_valid():
                serial.save()
                return Response(serial.data, status=status.HTTP_202_ACCEPTED)
            return Response(
                serial.errors,
                status=status.HTTP_412_PRECONDITION_FAILED)
        else:
            return Response(status=status.HTTP_403_FORBIDDEN)

    # Delete an object by using its ID or PK
    def destroy(self, request, pk, format=None):
        self.environment.load_data('destroy', pk=pk)
        if len(self.environment.permissions) == 0 or request.user.has_perms(
                self.environment.permissions):
            self.environment.query.delete()
            return Response(status=status.HTTP_200_OK)
        else:
            return Response(status=status.HTTP_403_FORBIDDEN)

    # @list_route(methods=['post'])
    # def destroy1(self, request, pk, format=None):
    #     self.environment.load_data('delete', pk=pk)
    #     if len(self.environment.permissions) == 0 or request.user.has_perms(
    #             self.environment.permissions):
    #         self.environment.query.delete()
    #         return Response(status=status.HTTP_200_OK)
    #     else:
    #         return Response(status=status.HTTP_403_FORBIDDEN)
