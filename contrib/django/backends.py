import re

from django.contrib.auth import get_user_model
from django.contrib.auth.models import Permission


EMAIL_REGEX = re.compile(r'[^@]+@[^@]+\.[^@]+')


class CustomUserModelBackend(object):
    def authenticate(self, username=None, password=None):
        model = get_user_model()
        if EMAIL_REGEX.match(username):
            kwargs = {'email': username}
        else:
            kwargs = {'username': username}
        try:
            user = model.objects.get(**kwargs)
            if user.check_password(password):
                return user
        except model.DoesNotExist:
            return None

    def get_user(self, user_id):
        user_model = get_user_model()
        try:
            return user_model.objects.get(pk=user_id)
        except user_model.DoesNotExist:
            return None

    def get_group_permissions(self, user_obj, obj=None):
        """
        Returns a set of permission strings that this user has through his/her
        groups.
        """
        if user_obj.is_anonymous() or obj is not None:
            return set()
        if not hasattr(user_obj, '_group_perm_cache'):
            if user_obj.is_superuser:
                perms = Permission.objects.all()
            else:
                user_groups_field = get_user_model()._meta.get_field('groups')
                user_groups_query = 'group__%s' % user_groups_field.related_query_name()
                perms = Permission.objects.filter(**{user_groups_query: user_obj})
            perms = perms.values_list('content_type__app_label', 'codename').order_by()
            user_obj._group_perm_cache = set("%s.%s" % (ct, name) for ct, name in perms)
        return user_obj._group_perm_cache

    def get_all_permissions(self, user_obj, obj=None):
        if user_obj.is_anonymous() or obj is not None:
            return set()
        if not hasattr(user_obj, '_perm_cache'):
            user_obj._perm_cache = set("%s.%s" % (p.content_type.app_label, p.codename)
                                       for p in user_obj.user_permissions.select_related())
            user_obj._perm_cache.update(self.get_group_permissions(user_obj))
        return user_obj._perm_cache

    def has_perm(self, user_obj, perm, obj=None):
        if not user_obj.is_active:
            return False
        return perm in self.get_all_permissions(user_obj, obj)

    def has_module_perms(self, user_obj, app_label):
        """
        Returns True if user_obj has any permissions in the given app_label.
        """
        if not user_obj.is_active:
            return False
        for perm in self.get_all_permissions(user_obj):
            if perm[:perm.index('.')] == app_label:
                return True
        return False
