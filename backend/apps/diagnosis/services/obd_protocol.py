"""
OBD Protocol Service
Handles OBD-II protocol communication
"""

import re
import time
from decimal import Decimal
from .pid_decoder import PIDDecoder


class OBDProtocol:
    """Service for OBD-II protocol handling"""

    # OBD-II protocols
    PROTOCOLS = {
        'auto': 'Automatic',
        'iso9141': 'ISO 9141-2 (PWM)',
        'iso14230': 'ISO 14230-4 (KWP2000)',
        'iso15765': 'ISO 15765-4 (CAN)',
        'j1850pwm': 'SAE J1850 PWM',
        'j1850vpw': 'SAE J1850 VPW',
        'can11': 'CAN 11-bit',
        'can29': 'CAN 29-bit',
    }

    @staticmethod
    def get_protocol_name(protocol_code):
        """Get protocol name from code"""
        return OBDProtocol.PROTOCOLS.get(protocol_code, protocol_code)

    @staticmethod
    def parse_vin_response(response):
        """Parse VIN from OBD response"""
        # Typical VIN response format
        vin_pattern = r'[0-9A-HJ-NPR-Z]{17}'
        match = re.search(vin_pattern, response)
        if match:
            return match.group(0)
        return None

    @staticmethod
    def parse_dtc_response(response):
        """Parse DTCs from OBD response"""
        dtc_pattern = r'[PBCU][0-9]{4}'
        matches = re.findall(dtc_pattern, response)
        return list(set(matches))  # Remove duplicates

    @staticmethod
    def parse_pid_response(pid, response):
        """Parse PID response"""
        # Remove spaces and 0x prefix
        data = response.replace(' ', '').replace('0x', '')

        # Check if response contains PID
        if pid in data:
            # Extract data after PID
            parts = data.split(pid)
            if len(parts) > 1:
                raw_data = parts[1]
                # Limit to 20 characters
                raw_data = raw_data[:20]
                return raw_data

        return None

    @staticmethod
    def format_command(cmd):
        """Format OBD command"""
        cmd = cmd.strip().replace(' ', '')
        if not cmd.startswith('0x'):
            cmd = '0x' + cmd
        return cmd

    @staticmethod
    def parse_ecu_response(response):
        """Parse ECU response"""
        # Remove headers and formatting
        data = response.replace(' ', '').replace('0x', '')
        data = data.replace('\r', '').replace('\n', '')
        return data

    @staticmethod
    def get_supported_pids(response):
        """Get supported PIDs from response"""
        pids = []
        data = response.replace(' ', '').replace('0x', '')

        # Check each PID (01 00 response)
        if len(data) >= 8:
            # Parse bitmask
            mask_bytes = []
            for i in range(0, len(data[:8]), 2):
                if i + 2 <= len(data):
                    mask_bytes.append(int(data[i:i+2], 16))

            # Decode supported PIDs
            pid_base = 0
            for byte_index, byte_val in enumerate(mask_bytes):
                for bit_index in range(8):
                    if byte_val & (1 << (7 - bit_index)):
                        pid_num = pid_base + bit_index
                        pid_hex = f'01{pid_num:02X}'
                        pids.append(pid_hex)

        return pids

    @staticmethod
    def validate_dtc(code):
        """Validate DTC format"""
        pattern = r'^[PBCU][0-9]{4}$'
        return bool(re.match(pattern, code.upper()))

    @staticmethod
    def validate_pid(pid):
        """Validate PID format"""
        pattern = r'^01[0-9A-F]{2}$'
        return bool(re.match(pattern, pid.upper()))

    @staticmethod
    def get_baud_rate(protocol):
        """Get baud rate for protocol"""
        baud_rates = {
            'iso9141': 10400,
            'iso14230': 10400,
            'iso15765': 500000,
            'j1850pwm': 41600,
            'j1850vpw': 10400,
            'can11': 500000,
            'can29': 500000,
        }
        return baud_rates.get(protocol, 9600)

    @staticmethod
    def get_timeout(protocol):
        """Get timeout for protocol"""
        timeouts = {
            'iso9141': 200,
            'iso14230': 200,
            'iso15765': 100,
            'j1850pwm': 200,
            'j1850vpw': 200,
            'can11': 100,
            'can29': 100,
        }
        return timeouts.get(protocol, 200)

    @staticmethod
    def detect_protocol(responses):
        """Detect protocol from responses"""
        for response in responses:
            if 'ISO 15765' in response or 'CAN' in response:
                return 'iso15765'
            elif 'ISO 9141' in response:
                return 'iso9141'
            elif 'ISO 14230' in response:
                return 'iso14230'
            elif 'J1850 PWM' in response:
                return 'j1850pwm'
            elif 'J1850 VPW' in response:
                return 'j1850vpw'
        return 'auto'
