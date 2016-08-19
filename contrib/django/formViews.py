from . import messages as msgs
from django.db import transaction
from django.contrib.auth.decorators import login_required
from django.core import urlresolvers
from django.http import HttpResponseRedirect
from django.shortcuts import render_to_response, render
from django.template import RequestContext
from django.utils.translation import ugettext as _ug


@transaction.atomic()
def WebFormView(request, environment, pk=None):
    environment.load_data(request.method, pk)
    instance = None

    # Create and redirect on success, or rerender on fail.
    if request.method == 'POST':
        new_instance, instance = formPost(request, environment)
        if new_instance is not None:
            return HttpResponseRedirect(urlresolvers.reverse(
                                        environment.redirect_urlname))

    # Edit and redirect, or rerender on fail.
    elif request.method == 'PUT':
        new_instance, instance = formPut(request, environment)
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
#  by WebFormView had a POST method. This function SHOULD only
#  create new instances, not update them.
def formPost(request, environment=None):
    new_instance = instance_form = None
    permissions = environment.permissions

    # The request is trying to edit an instance. Send error
    if environment.pk is not None:
        msgs.generate_msg(request, msgs.RED, msgs.ERROR,
                          msgs.errors_list['title']['409'],
                          msgs.errors_list['body']['incorrect_method'])

    # Handle creation of new instances
    elif environment.pk is None:
        # Does the user have enough permissions?
        if len(permissions) == 0 or request.user.has_perms(permissions):  # FIXME: Add privileges
            instance_form = environment.serializer(data=request.POST)
            if instance_form.is_valid():
                new_instance = instance_form.save(user=request.user)
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
#  by WebFormView had a PUT method. This function SHOULD only
#  update database instances, not create them.
def formPut(request, environment=None):
    new_instance = instance_form = None
    permissions = environment.permissions
    # Handle the edition of instances
    if environment.pk is not None:
        # Does the user have enough permissions?
        if len(permissions) == 0 or request.user.has_perms(permissions):
            instance = environment.query
            instance_form = environment.serializer(
                                data=request.POST,
                                instance=instance)
            if instance_form.is_valid():
                new_instance = instance_form.save(user=request.user)
                msgs.generate_msg(request, msgs.GREEN, msgs.SUCCESS,
                                  _ug('The changes have been saved.'))
        # No, the user doesn't have the required permissions
        else:
            msgs.generate_msg(request, msgs.RED, msgs.ERROR,
                              msgs.errors_list['title']['403'],
                              msgs.errors_list['body']['no_perm'])

    # The request is trying to create a new instance. Send error.
    elif environment.pk is None:
        msgs.generate_msg(request, msgs.RED, msgs.ERROR,
                          msgs.errors_list['title']['409'],
                          msgs.errors_list['body']['incorrect_method'])
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
