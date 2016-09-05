from . import messages as msgs
from django.db import transaction
from django.conf import settings
from django.core import urlresolvers
from django.http import HttpResponseRedirect
from django.shortcuts import render_to_response, render, redirect
from django.template import RequestContext
from django.utils.translation import ugettext as _ug


@transaction.atomic()
def WebFormView(request, environment, pk=None):
    environment.load_data(request.method, pk)
    if environment.login_required and not request.user.is_authenticated():
        return redirect('%s?next=%s' % (settings.LOGIN_URL, request.path))
    instance = None

    # Create and redirect on success, or rerender on fail.
    if request.method == 'POST':
        new_instance, instance = formPost(request, environment)
        if new_instance is not None:
            return HttpResponseRedirect(urlresolvers.reverse(
                                        environment.redirect_urlname))

    # Request the create/update form
    elif request.method == 'GET':
        instance = formGet(request, environment)

    return render(
        request,
        template_name=environment.template,
        context={'django_form': instance}
    )


# Function executed in case that the request received
#  by WebFormView had a POST method.
def formPost(request, environment=None):
    new_instance = instance_form = None
    permissions = environment.permissions

    # Handle the edition of instances
    if environment.pk is not None:
        # Does the user have enough permissions?
        if len(permissions) == 0 or request.user.has_perms(permissions):
            instance_form = environment.serializer(
                                data=request.POST,
                                instance=environment.query)
            if instance_form.is_valid():
                new_instance = instance_form.save()
                msgs.generate_msg(request, msgs.GREEN, msgs.SUCCESS,
                                  _ug('The changes have been saved.'))
        # No, the user doesn't have the required permissions
        else:
            msgs.generate_msg(request, msgs.RED, msgs.ERROR,
                              msgs.errors_list['title']['403'],
                              msgs.errors_list['body']['no_perm'])

    # Handle creation of new instances
    elif environment.pk is None:
        # Does the user have enough permissions?
        if len(permissions) == 0 or request.user.has_perms(permissions):  # FIXME: Add privileges
            instance_form = environment.serializer(data=request.POST)
            if instance_form.is_valid():
                new_instance = instance_form.save()
                msgs.generate_msg(request, msgs.GREEN, msgs.SUCCESS,
                                  _ug('The creation was done successfully.'))
        # No, the user doesn't have the required permissions
        else:
            msgs.generate_msg(request, msgs.RED, msgs.ERROR,
                              msgs.errors_list['title']['403'],
                              msgs.errors_list['body']['no_perm'])

    # This shouldn't have happened.
    else:
        msgs.generate_msg(request, msgs.RED, msgs.ERROR,
                          msgs.errors_list['title']['500'],
                          msgs.errors_list['body']['ticket'])
    return new_instance, instance_form


# Function executed in case that the request received
#  by WebFormView had a GET method
def formGet(request, environment=None):
    instance = None
    permissions = environment.permissions

    # Recover the instance from the database, put it in a serializer and
    #  return. The serializer can be a django form or django_rest serializer.
    if environment.pk is not None and (len(permissions) == 0 or
                                       request.user.has_perms(permissions)):
        instance = environment.serializer(instance=environment.query)

    # Empty serializer
    elif environment.pk is None and (len(permissions) == 0 or
                                     request.user.has_perms(permissions)):
        instance = environment.serializer()

    # This shouldn't have happened.
    else:
        msgs.generate_msg(request, msgs.RED, msgs.ERROR,
                          msgs.errors_list['title']['500'],
                          msgs.errors_list['body']['ticket'])

    return instance
