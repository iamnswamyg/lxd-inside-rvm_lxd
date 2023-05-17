#!/bin/bash

TARGET_WEB_PORT=8283
{%- set app = data['application-webservers']['misc'] %}
TARGET_WEB="{{ app['ufcolo1']['prod'] | sort | join(' ') }} {{ app['ufcolo2']['prod'] | sort | join(' ') }}"
