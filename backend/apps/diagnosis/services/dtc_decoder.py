"""
DTC Decoder Service
Decodes Diagnostic Trouble Codes (DTCs)
"""

import re
from ..models import DTCCode, DTCSystem


class DTCDecoder:
    """Service for decoding Diagnostic Trouble Codes"""

    @staticmethod
    def decode(code):
        """Decode a DTC code"""
        code = code.strip().upper()

        # Check if code exists in database
        try:
            dtc = DTCCode.objects.get(code=code, is_active=True)
            return {
                'code': dtc.code,
                'system': dtc.system,
                'description': dtc.description,
                'detailed_description': dtc.detailed_description,
                'possible_causes': dtc.possible_causes,
                'symptoms': dtc.symptoms,
                'recommended_actions': dtc.recommended_actions,
                'severity': dtc.severity,
                'exists': True,
            }
        except DTCCode.DoesNotExist:
            # Attempt to parse the code structure
            return DTCDecoder._parse_code(code)

    @staticmethod
    def _parse_code(code):
        """Parse a DTC code structure"""
        system_map = {
            'P': 'Powertrain',
            'C': 'Chassis',
            'B': 'Body',
            'U': 'Network',
        }

        result = {
            'code': code,
            'exists': False,
            'system': None,
            'system_name': None,
            'type': None,
            'number': None,
            'description': None,
            'severity': 'medium',
        }

        # Match pattern: P0123, P0xxx, P1xxx
        pattern = r'^([PBCU])([0-9])([0-9]{3})$'
        match = re.match(pattern, code)

        if match:
            system = match.group(1)
            code_type = match.group(2)
            number = match.group(3)

            result['system'] = system
            result['system_name'] = system_map.get(system, 'Unknown')
            result['type'] = 'Generic' if code_type == '0' else 'Manufacturer Specific'
            result['number'] = number

            # Set default description based on system and number
            result['description'] = f"{system_map.get(system, 'Unknown')} code {code}"
        else:
            # Generic unknown code
            result['description'] = 'Unknown DTC code'

        return result

    @staticmethod
    def get_severity(code):
        """Get severity of a DTC"""
        try:
            dtc = DTCCode.objects.get(code=code, is_active=True)
            return dtc.severity
        except DTCCode.DoesNotExist:
            # Default severity based on code pattern
            if code.startswith('P0') or code.startswith('U0'):
                return 'low'
            elif code.startswith('P1') or code.startswith('C0'):
                return 'medium'
            elif code.startswith('C1') or code.startswith('B0'):
                return 'high'
            else:
                return 'medium'

    @staticmethod
    def get_system(code):
        """Get system of a DTC"""
        try:
            dtc = DTCCode.objects.get(code=code, is_active=True)
            return dtc.system
        except DTCCode.DoesNotExist:
            if code.startswith('P'):
                return DTCSystem.POWERTRAIN
            elif code.startswith('C'):
                return DTCSystem.CHASSIS
            elif code.startswith('B'):
                return DTCSystem.BODY
            elif code.startswith('U'):
                return DTCSystem.NETWORK
            return DTCSystem.GENERIC

    @staticmethod
    def is_emission_related(code):
        """Check if DTC is emission related"""
        try:
            dtc = DTCCode.objects.get(code=code, is_active=True)
            return dtc.is_emission_related
        except DTCCode.DoesNotExist:
            # Emission related codes often start with P0
            return code.startswith('P0')
