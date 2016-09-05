# Obtained and modified from:
# http://goo.gl/XDH8QX

from __future__ import unicode_literals

from django import forms
from django.contrib.auth import get_user_model
from django.contrib.auth.forms import PasswordResetForm as PRF
from django.contrib.auth.tokens import default_token_generator
from django.contrib.sites.shortcuts import get_current_site
from django.template import loader
from django.urls import reverse
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from django.utils.translation import ugettext as _ug

from django_sendgrid_parse.emails import TransactionalEmail


class PasswordResetForm(PRF):
    def send_mail(self, subject_template_name, email_template_id,
                  context, from_email, to_email, html_email_template_name=None):
        """
        Sends a django.core.mail.EmailMultiAlternatives to `to_email`.
        """
        subject = loader.render_to_string(subject_template_name, context)
        # Email subject *must not* contain newlines
        subject = ''.join(subject.splitlines())
        email = TransactionalEmail(
            subject,
            email_template_id,
            context,
            from_email=from_email,
            to=[to_email]
        )
        email.send()
        # email_message = EmailMultiAlternatives(subject, body, from_email, [to_email])
        # if html_email_template_name is not None:
        #     html_email = loader.render_to_string(html_email_template_name, context)
        #     email_message.attach_alternative(html_email, 'text/html')
        # email_message.send()

    def save(self, email_template_id, domain_override=None,
             subject_template_name='registration/password_reset_subject.txt',
             use_https=False, token_generator=default_token_generator,
             from_email=None, request=None, html_email_template_name=None,
             extra_email_context=None):
        """
        Generates a one-use only link for resetting password and sends to the
        user.
        """
        email = self.cleaned_data["email"]
        for user in self.get_users(email):
            if not domain_override:
                current_site = get_current_site(request)
                site_name = current_site.name
                domain = current_site.domain
            else:
                site_name = domain = domain_override

            # {'-name-': self.validated_data['name'],
            #  '-company-': self.validated_data['company'],
            #  '-email-': self.validated_data['email'],
            #  '-accounts-': self.validated_data['accounts'],
            #  '-message-': self.validated_data['message']},
            protocol = 'https' if use_https else 'http'
            context = {
                '-link-': protocol + '://' + domain + reverse(
                    'password_reset_confirm', kwargs={
                        'uidb64': urlsafe_base64_encode(force_bytes(user.pk)),
                        'token': token_generator.make_token(user),
                        }),
            }
            print(context['-link-'])
            if extra_email_context is not None:
                context.update(extra_email_context)
            self.send_mail(
                subject_template_name, email_template_id, context, from_email,
                user.email, html_email_template_name=html_email_template_name,
            )
