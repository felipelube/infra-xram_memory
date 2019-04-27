#!/bin/bash
celery worker -A xram_memory -n 'worker@%h'