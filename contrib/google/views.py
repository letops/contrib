from __future__ import absolute_import, unicode_literals

from django.conf import settings
from django.core.cache import cache
from django.http import HttpResponse

from .geoJSON_generator import geoJSON


def geoJSONView(request, environment):
    cache_key = 'google-geoJSON:' + str(request.site.id)
    geojson_json = cache.get(cache_key)

    if not geojson_json:
        # Rerender geoJSON
        geojson = geoJSON(request.site)
        geojson_json = geojson.render()

        cache.set(cache_key, geojson_json, getattr(settings, 'GOOGLEGEOJSONS_CACHE_TIMEOUT', 6000))

    # Build response
    response = HttpResponse(geojson_json)
    response['Content-Type'] = "application/json; charset=utf-8"

    return response


# TODO:
# Receive name of the file from the url and the environment from the kwargs
# Load the environment with the name of the file
# Execute the query contained in the environment if no file is present
