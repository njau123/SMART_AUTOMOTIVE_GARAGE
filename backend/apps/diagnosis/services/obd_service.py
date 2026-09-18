import re
from decimal import Decimal, InvalidOperation
from typing import Any

from apps.diagnosis.models import (
    DTCCode,
    DiagnosisDTC,
    DiagnosisSession,
    OBDPID,
    OBDScan,
)


class OBDServiceError(Exception):
    """Base exception for OBD processing errors."""


class OBDService:
    """
    Backend OBD-II processing service.

    IMPORTANT:
    This service does NOT communicate with Bluetooth hardware.

    Flutter is responsible for:
        OBD Adapter
            ↓
        Bluetooth / Wi-Fi
            ↓
        ELM327 communication

    Django is responsible for:
        raw/normalized data
            ↓
        validation
            ↓
        DTC processing
            ↓
        PID processing
            ↓
        database persistence
    """

    HEX_PATTERN = re.compile(r"^[0-9A-Fa-f]+$")

    @staticmethod
    def normalize_hex(value: Any) -> str:
        """
        Normalize a hexadecimal response.
        """
        if value is None:
            return ""

        value = str(value).strip()

        value = value.replace(
            "0x",
            "",
        ).replace(
            "0X",
            "",
        )

        value = re.sub(
            r"[^0-9A-Fa-f]",
            "",
            value,
        )

        return value.upper()

    @staticmethod
    def hex_to_bytes(value: Any) -> list[int]:
        """
        Convert a hexadecimal string into byte values.

        Example:
            "410C1AF8"

        becomes:

            [65, 12, 26, 248]
        """
        normalized = OBDService.normalize_hex(
            value
        )

        if not normalized:
            return []

        if len(normalized) % 2 != 0:
            raise OBDServiceError(
                "Invalid hexadecimal response length."
            )

        if not OBDService.HEX_PATTERN.match(
            normalized
        ):
            raise OBDServiceError(
                "Invalid hexadecimal response."
            )

        try:
            return [
                int(
                    normalized[index:index + 2],
                    16,
                )
                for index in range(
                    0,
                    len(normalized),
                    2,
                )
            ]
        except ValueError as exc:
            raise OBDServiceError(
                "Unable to decode hexadecimal response."
            ) from exc

    @staticmethod
    def decode_pid(
        pid: str,
        response: str,
    ) -> dict[str, Any]:
        """
        Decode common Mode 01 OBD-II PIDs.

        The response may contain:
            41 <PID> <DATA>

        Example:
            410C1AF8

        PID:
            0C

        Data:
            1A F8

        RPM:
            ((26 * 256) + 248) / 4
            = 1726 rpm
        """

        normalized_pid = (
            str(pid)
            .replace("0x", "")
            .replace("0X", "")
            .upper()
        )

        if normalized_pid.startswith("01"):
            normalized_pid = normalized_pid[2:]

        normalized_response = (
            OBDService.normalize_hex(response)
        )

        response_bytes = OBDService.hex_to_bytes(
            normalized_response
        )

        if len(response_bytes) < 3:
            raise OBDServiceError(
                "OBD PID response is too short."
            )

        expected_pid = int(
            normalized_pid,
            16,
        )

        data_start_index = None

        for index in range(
            len(response_bytes) - 1
        ):
            if (
                response_bytes[index] == 0x41
                and response_bytes[index + 1]
                == expected_pid
            ):
                data_start_index = index + 2
                break

        if data_start_index is None:
            raise OBDServiceError(
                "Expected PID response was not found."
            )

        data = response_bytes[
            data_start_index:
        ]

        if not data:
            raise OBDServiceError(
                "PID response contains no data."
            )

        pid_code = normalized_pid

        if pid_code == "05":
            raw_value = data[0]

            value = raw_value - 40

            return {
                "pid": "0105",
                "name": "Engine Coolant Temperature",
                "value": value,
                "unit": "°C",
                "raw": data,
            }

        if pid_code == "0B":
            value = data[0]

            return {
                "pid": "010B",
                "name": "Intake Manifold Absolute Pressure",
                "value": value,
                "unit": "kPa",
                "raw": data,
            }

        if pid_code == "0C":
            if len(data) < 2:
                raise OBDServiceError(
                    "RPM response requires two bytes."
                )

            raw_value = (
                (data[0] * 256)
                + data[1]
            )

            value = raw_value / 4

            return {
                "pid": "010C",
                "name": "Engine RPM",
                "value": value,
                "unit": "rpm",
                "raw": data,
            }

        if pid_code == "0D":
            value = data[0]

            return {
                "pid": "010D",
                "name": "Vehicle Speed",
                "value": value,
                "unit": "km/h",
                "raw": data,
            }

        if pid_code == "0E":
            value = (
                data[0] / 2
            ) - 64

            return {
                "pid": "010E",
                "name": "Timing Advance",
                "value": value,
                "unit": "degrees",
                "raw": data,
            }

        if pid_code == "0F":
            value = data[0] - 40

            return {
                "pid": "010F",
                "name": "Intake Air Temperature",
                "value": value,
                "unit": "°C",
                "raw": data,
            }

        if pid_code == "10":
            if len(data) < 2:
                raise OBDServiceError(
                    "MAF response requires two bytes."
                )

            raw_value = (
                (data[0] * 256)
                + data[1]
            )

            value = raw_value / 100

            return {
                "pid": "0110",
                "name": "Mass Air Flow",
                "value": value,
                "unit": "g/s",
                "raw": data,
            }

        if pid_code == "11":
            value = (
                data[0] * 100
            ) / 255

            return {
                "pid": "0111",
                "name": "Throttle Position",
                "value": round(
                    value,
                    2,
                ),
                "unit": "%",
                "raw": data,
            }

        if pid_code == "1F":
            if len(data) < 2:
                raise OBDServiceError(
                    "Engine runtime response requires two bytes."
                )

            value = (
                data[0] * 256
            ) + data[1]

            return {
                "pid": "011F",
                "name": "Run Time Since Engine Start",
                "value": value,
                "unit": "seconds",
                "raw": data,
            }

        if pid_code == "2F":
            value = (
                data[0] * 100
            ) / 255

            return {
                "pid": "012F",
                "name": "Fuel Level Input",
                "value": round(
                    value,
                    2,
                ),
                "unit": "%",
                "raw": data,
            }

        if pid_code == "31":
            if len(data) < 2:
                raise OBDServiceError(
                    "Distance response requires two bytes."
                )

            value = (
                data[0] * 256
            ) + data[1]

            return {
                "pid": "0131",
                "name": "Distance Since Codes Cleared",
                "value": value,
                "unit": "km",
                "raw": data,
            }

        if pid_code == "42":
            if len(data) < 2:
                raise OBDServiceError(
                    "Control module voltage response requires two bytes."
                )

            raw_value = (
                (data[0] * 256)
                + data[1]
            )

            value = raw_value / 1000

            return {
                "pid": "0142",
                "name": "Control Module Voltage",
                "value": value,
                "unit": "V",
                "raw": data,
            }

        if pid_code == "46":
            value = data[0] - 40

            return {
                "pid": "0146",
                "name": "Ambient Air Temperature",
                "value": value,
                "unit": "°C",
                "raw": data,
            }

        if pid_code == "4C":
            value = (
                data[0] * 100
            ) / 255

            return {
                "pid": "014C",
                "name": "Commanded Throttle Actuator",
                "value": round(
                    value,
                    2,
                ),
                "unit": "%",
                "raw": data,
            }

        raise OBDServiceError(
            f"PID 01{pid_code} is not currently supported."
        )

    @staticmethod
    def extract_dtc_codes(
        response: str,
    ) -> list[str]:
        """
        Extract standard OBD-II DTC codes.

        Supports Mode 03 response:

            43 ...

        and Mode 07:

            47 ...

        and Mode 0A:

            4A ...

        Example raw response:

            430300

        returns:

            ["P0300"]
        """

        normalized = OBDService.normalize_hex(
            response
        )

        if not normalized:
            return []

        try:
            data = OBDService.hex_to_bytes(
                normalized
            )
        except OBDServiceError:
            return []

        if len(data) < 3:
            return []

        mode = data[0]

        valid_modes = {
            0x43,
            0x47,
            0x4A,
        }

        if mode not in valid_modes:
            return []

        payload = data[1:]

        dtc_codes = []

        for index in range(
            0,
            len(payload) - 1,
            2,
        ):
            first = payload[index]
            second = payload[index + 1]

            if first == 0 and second == 0:
                continue

            code = OBDService.bytes_to_dtc(
                first,
                second,
            )

            if code:
                dtc_codes.append(
                    code
                )

        return dtc_codes

    @staticmethod
    def bytes_to_dtc(
        first: int,
        second: int,
    ) -> str | None:
        """
        Convert two OBD-II DTC bytes into a standard code.

        DTC first byte format:

            bits 7-6 = system
            bits 5-4 = first numeric character
            bits 3-0 = second numeric character
        """

        system_map = {
            0b00: "P",
            0b01: "C",
            0b10: "B",
            0b11: "U",
        }

        system = system_map[
            (first & 0xC0) >> 6
        ]

        digit_1 = (
            (first & 0x30) >> 4
        )

        digit_2 = first & 0x0F

        digit_3 = (
            (second & 0xF0) >> 4
        )

        digit_4 = second & 0x0F

        if any(
            digit > 9
            for digit in [
                digit_1,
                digit_2,
                digit_3,
                digit_4,
            ]
        ):
            return None

        return (
            f"{system}"
            f"{digit_1}"
            f"{digit_2}"
            f"{digit_3}"
            f"{digit_4}"
        )

    @staticmethod
    def find_dtc_definition(
        code: str,
    ) -> DTCCode | None:
        """
        Find DTC definition from database.
        """
        normalized = (
            str(code)
            .strip()
            .upper()
        )

        return (
            DTCCode.objects
            .filter(
                code=normalized,
                is_active=True,
            )
            .first()
        )

    @staticmethod
    def create_diagnosis_dtc(
        diagnosis: DiagnosisSession,
        code: str,
        *,
        pending: bool = False,
        confirmed: bool = True,
        permanent: bool = False,
        freeze_frame: dict | None = None,
        raw_code: str = "",
    ) -> DiagnosisDTC | None:
        """
        Create or update a DTC attached to a diagnosis session.
        """

        normalized_code = (
            str(code)
            .strip()
            .upper()
        )

        definition = (
            OBDService.find_dtc_definition(
                normalized_code
            )
        )

        if definition is None:
            return None

        diagnosis_dtc, created = (
            DiagnosisDTC.objects.get_or_create(
                session=diagnosis,
                raw_code=raw_code,
                defaults={
                    "dtc_code": definition,
                    "status": "ACTIVE",
                },
            )
        )


        if not created:
            diagnosis_dtc.occurrence_count += 1

            diagnosis_dtc.is_pending = pending
            diagnosis_dtc.is_confirmed = confirmed
            diagnosis_dtc.is_permanent = permanent

            if raw_code:
                diagnosis_dtc.raw_code = raw_code

            if freeze_frame:
                diagnosis_dtc.freeze_frame = (
                    freeze_frame
                )

            diagnosis_dtc.save(
                update_fields=[
                    "occurrence_count",
                    "is_pending",
                    "is_confirmed",
                    "is_permanent",
                    "raw_code",
                    "freeze_frame",
                ]
            )

        return diagnosis_dtc

    @staticmethod
    def process_dtc_scan(
        diagnosis: DiagnosisSession,
        raw_response: str,
        *,
        pending: bool = False,
        permanent: bool = False,
    ) -> dict[str, Any]:
        """
        Process a raw DTC response and attach known DTCs
        to the diagnosis.
        """

        codes = (
            OBDService.extract_dtc_codes(
                raw_response
            )
        )

        processed = []
        unknown = []

        for code in codes:
            diagnosis_dtc = (
                OBDService.create_diagnosis_dtc(
                    diagnosis,
                    code,
                    pending=pending,
                    confirmed=not pending,
                    permanent=permanent,
                    raw_code=raw_response,
                )
            )

            if diagnosis_dtc is None:
                unknown.append(code)
                continue

            processed.append(
                {
                    "code": code,
                    "diagnosis_dtc_id": (
                        diagnosis_dtc.id
                    ),
                    "occurrence_count": (
                        diagnosis_dtc
                        .occurrence_count
                    ),
                }
            )

        return {
            "codes": codes,
            "processed": processed,
            "unknown": unknown,
            "count": len(codes),
        }

    @staticmethod
    def save_obd_scan(
        diagnosis: DiagnosisSession,
        *,
        protocol: str = "",
        adapter_name: str = "",
        adapter_identifier: str = "",
        vin: str = "",
        ecu_count: int = 0,
        raw_response: dict | None = None,
        live_data: dict | None = None,
        supported_pids: list | None = None,
        mil_status: bool = False,
        scan_started_at=None,
        scan_completed_at=None,
    ) -> OBDScan:
        """
        Persist an OBD scan for a diagnosis session.
        """

        raw_response = (
            raw_response
            if isinstance(
                raw_response,
                dict,
            )
            else {}
        )

        live_data = (
            live_data
            if isinstance(
                live_data,
                dict,
            )
            else {}
        )

        supported_pids = (
            supported_pids
            if isinstance(
                supported_pids,
                list,
            )
            else []
        )

        obd_scan, _ = (
            OBDScan.objects
            .update_or_create(
                diagnosis=diagnosis,
                defaults={
                    "protocol": protocol,
                    "adapter_name": adapter_name,
                    "adapter_identifier": (
                        adapter_identifier
                    ),
                    "vin": vin,
                    "ecu_count": ecu_count,
                    "dtc_count": (
                        diagnosis.dtcs.count()
                    ),
                    "raw_response": raw_response,
                    "live_data": live_data,
                    "supported_pids": (
                        supported_pids
                    ),
                    "mil_status": mil_status,
                    "scan_started_at": (
                        scan_started_at
                    ),
                    "scan_completed_at": (
                        scan_completed_at
                    ),
                },
            )
        )

        return obd_scan

    @staticmethod
    def normalize_live_data(
        live_data: dict,
    ) -> dict:
        """
        Normalize live data coming from Flutter.

        This keeps the API stable even if Flutter uses
        slightly different field naming.
        """

        if not isinstance(
            live_data,
            dict,
        ):
            return {}

        aliases = {
            "rpm": "engine_rpm",
            "engineRpm": "engine_rpm",
            "coolantTemp": "coolant_temperature",
            "coolantTemperature": (
                "coolant_temperature"
            ),
            "vehicleSpeed": "vehicle_speed",
            "throttlePosition": (
                "throttle_position"
            ),
            "intakeAirTemperature": (
                "intake_air_temperature"
            ),
            "massAirFlow": "mass_air_flow",
            "fuelLevel": "fuel_level",
            "controlModuleVoltage": (
                "control_module_voltage"
            ),
        }

        normalized = {}

        for key, value in live_data.items():
            target_key = aliases.get(
                key,
                key,
            )

            normalized[target_key] = value

        return normalized
