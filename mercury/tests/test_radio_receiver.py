from django.test import TestCase
from django.urls import reverse
from mercury.models import AGEvent
import datetime
import mock


def fake_event(event_uuid):
    """
        Mock a dummy AGEvent model
    """
    if str(event_uuid) == "d81cac8d-26e1-4983-a942-1922e54a943d":
        return AGEvent(
            event_uuid=event_uuid,
            event_name="fake event",
            event_description="fake event",
            event_date=datetime.datetime(2020, 2, 2, 20, 21, 22),
            event_location="nyu",
        )
    else:
        return None


def fake_valid(res):
    return True


class TestRadioReceiverView(TestCase):
    def setUp(self) -> None:
        self.get_url = "mercury:radioreceiver"
        self.post_url = "mercury:radioreceiver"
        self.uuid = "d81cac8d-26e1-4983-a942-1922e54a943d"
        self.uuid2 = "d81cac8d-26e1-4983-a942-1922e54a943a"

    def post_radio_data(self):
        # POST sensor data to the radioreceiver url
        response = self.client.post(
            reverse(self.post_url, args=[self.uuid]),
            data={
                "sensor_id": 1,
                "values": {"power": "2", "speed": 1},
                "date": datetime.datetime(2020, 2, 2, 20, 21, 22),
            },
        )
        return response

    @mock.patch("mercury.models.AGEvent.objects.get", fake_event)
    def test_Radio_Receiver_GET_No_Related_Event(self):
        response = self.client.get(reverse(self.get_url, args=[self.uuid2]))
        self.assertEqual(400, response.status_code)

    @mock.patch("mercury.models.AGEvent.objects.get", fake_event)
    def test_Radio_Receiver_GET_Success(self):
        response = self.client.get(
            reverse(self.get_url, args=[self.uuid]),
            data={
                "enable": 1,
                "baudrate": 9000,
                "bytesize": 8,
                "parity": "N",
                "stop bits": 1,
                "timeout": 1,
            },
        )
        self.assertEqual(200, response.status_code)

    @mock.patch("mercury.models.AGEvent.objects.get", fake_event)
    def test_Radio_Receiver_POST_Event_Not_Exist(self):
        response = self.client.post(reverse(self.get_url, args=[self.uuid2]))
        self.assertEqual(400, response.status_code)

    @mock.patch("mercury.models.AGEvent.objects.get", fake_event)
    @mock.patch("mercury.serializers.AGMeasurementSerializer.is_valid", fake_valid)
    @mock.patch("mercury.serializers.AGMeasurementSerializer.save", fake_valid)
    def test_Radio_Receiver_POST_Event_Success(self):
        response = self.post_radio_data()
        self.assertEqual(200, response.status_code)
