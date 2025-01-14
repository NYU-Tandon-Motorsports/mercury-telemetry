import json

from django.db import models
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from ag_data.models import AGActiveEvent, AGSensor
from ag_data.formulas import pipeline
from django.core import serializers
from django.utils.dateparse import parse_datetime

from ag_data.error_record import record


def build_error(str):
    return json.dumps({"error": str})


def add_measurement(request):
    json_data = request.data

    try:
        timestamp = json_data["date"]
        sensor_id = json_data["sensor_id"]
        values = json_data["values"]
    except KeyError as e:
        record.save_error(
            raw_data=json.dumps(json_data),
            error_code=record.ERROR_CODE["MISSING_COL"],
            error_description=f"Missing column: {e.args[0]}",
        )
        return Response(
            build_error(f"Missing required params: {e.args[0]}"),
            status=status.HTTP_400_BAD_REQUEST,
        )

    timestamp = parse_datetime(timestamp)
    if not timestamp:
        record.save_error(
            raw_data=json.dumps(json_data),
            error_code=record.ERROR_CODE["INVALID_COL_VL"],
            error_description="Invalid timestamp in json_data",
        )
        return Response(
            build_error("Invalid timestamp"), status=status.HTTP_400_BAD_REQUEST
        )

    try:
        sensor = AGSensor.objects.get(serial=sensor_id)
    except models.ObjectDoesNotExist:
        record.save_error(
            raw_data=json.dumps(json_data),
            error_code=record.ERROR_CODE["INVALID_COL_VL"],
            error_description=f"sensor serial:{sensor_id} unknown",
        )
        return Response(
            build_error(f"No sensor for given sensor serial (sensor_id: {sensor_id})"),
            status=status.HTTP_400_BAD_REQUEST,
        )

    measurement = pipeline.shared_instance.save_measurement(sensor, timestamp, values)
    return Response(
        serializers.serialize("json", [measurement]), status=status.HTTP_201_CREATED,
    )


class MeasurementView(APIView):
    def post(self, request):
        """
        The post receives sensor data through internet
        Url example:
        http://localhost:8000/measurement/
        Post Json Data Example
        {
          "sensor_id": 1,
          "values": {
            "power" : "1",
            "speed" : "2",
          }
          "date" : 2020-03-11T20:20+01:00
        }
        """
        active_event = AGActiveEvent.objects.first()
        if not active_event:
            record.save_error(
                raw_data=request.data,
                error_code=record.ERROR_CODE["NO_ACT_EVENT"],
                error_description="Currently no active event",
            )
            return Response(
                build_error("No active event"), status=status.HTTP_400_BAD_REQUEST,
            )

        return add_measurement(request)
